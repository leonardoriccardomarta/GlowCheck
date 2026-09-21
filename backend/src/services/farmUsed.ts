import { ensureDb, sqlClient } from '../db';
import { DEFAULT_USED_IDEAS, FARM_IDEAS, ideaKey, type FarmIdea } from '../data/farmIdeas';
import { farmLookup, type FarmHit } from './farmCatalog';

export type ReadyFarmIdea = FarmIdea & { product: FarmHit };

const SCAN_KEY = '__scan_cursor__';
const hitCache = new Map<string, FarmHit | null>();

function norm(value: string) {
  return value.toLowerCase().replace(/[^a-z0-9]+/g, ' ').trim();
}

function ideaKeysOf(idea: FarmIdea) {
  return [...new Set([idea.id, ideaKey(idea.id), ideaKey(idea.query), ideaKey(idea.label)].filter(Boolean))];
}

function productKeysOf(product: { name?: string | null; brand?: string | null }) {
  const name = String(product.name || '').trim();
  const brand = String(product.brand || '').trim();
  return [...new Set([ideaKey(name), ideaKey([brand, name].filter(Boolean).join(' '))].filter((key) => key.length >= 4))];
}

function matchesIdea(product: { name?: string | null; brand?: string | null }, idea: FarmIdea) {
  const hay = norm(`${product.brand || ''} ${product.name || ''}`);
  if (!hay) return false;
  const query = norm(idea.query);
  const label = norm(idea.label);
  if (query && hay.includes(query)) return true;
  if (label && hay.includes(label)) return true;
  const words = query.split(' ').filter((word) => word.length > 3);
  return words.length >= 2 && words.every((word) => hay.includes(word));
}

async function seedDefaults() {
  await ensureDb();
  for (const raw of DEFAULT_USED_IDEAS) {
    await sqlClient()`
      INSERT INTO farm_used (idea_key, label)
      VALUES (${raw}, ${raw})
      ON CONFLICT (idea_key) DO NOTHING
    `;
  }
  await sqlClient()`
    INSERT INTO farm_used (idea_key, label)
    VALUES (${ideaKey('CeraVe Moisturizing Cream')}, ${'CeraVe Moisturizing Cream'})
    ON CONFLICT (idea_key) DO NOTHING
  `;
}

async function usedKeys() {
  try {
    await seedDefaults();
    const rows = await sqlClient()`SELECT idea_key FROM farm_used`;
    return new Set(rows.map((row) => String(row.idea_key)).filter((key) => !key.startsWith('__')));
  } catch {
    return new Set(DEFAULT_USED_IDEAS);
  }
}

function isUnused(idea: FarmIdea, used: Set<string>) {
  const keys = ideaKeysOf(idea);
  if (keys.some((key) => used.has(key))) return false;
  for (const usedKey of used) {
    if (usedKey.length < 8) continue;
    if (keys.some((key) => key.length >= 8 && (usedKey.includes(key) || key.includes(usedKey)))) return false;
  }
  return true;
}

function productAlreadyUsed(product: FarmHit, used: Set<string>) {
  if (productKeysOf(product).some((key) => used.has(key))) return true;
  return FARM_IDEAS.some((idea) => matchesIdea(product, idea) && !isUnused(idea, used));
}

async function firstInciHit(query: string): Promise<FarmHit | null> {
  if (hitCache.has(query)) return hitCache.get(query) ?? null;
  try {
    const hits = await farmLookup(query);
    const hit = hits.find((item) => item.ingredients.length >= 2) ?? null;
    hitCache.set(query, hit);
    return hit;
  } catch {
    hitCache.set(query, null);
    return null;
  }
}

export async function bumpFarmScan(): Promise<number> {
  try {
    await ensureDb();
    await sqlClient()`
      INSERT INTO farm_used (idea_key, label)
      VALUES (${SCAN_KEY}, ${'1'})
      ON CONFLICT (idea_key) DO UPDATE SET
        label = (COALESCE(NULLIF(farm_used.label, ''), '0')::int + 1)::text,
        used_at = NOW()
    `;
    const rows = await sqlClient()`SELECT label FROM farm_used WHERE idea_key = ${SCAN_KEY}`;
    return Number(rows[0]?.label || 1) || 1;
  } catch {
    return Date.now();
  }
}

export async function readFarmScan(): Promise<number> {
  try {
    await ensureDb();
    const rows = await sqlClient()`SELECT label FROM farm_used WHERE idea_key = ${SCAN_KEY}`;
    return Number(rows[0]?.label || 0) || 0;
  } catch {
    return 0;
  }
}

export async function unusedFarmIdeas(limit = 8, opts?: { rotate?: boolean }): Promise<ReadyFarmIdea[]> {
  const used = await usedKeys();
  const unused = FARM_IDEAS.filter((idea) => isUnused(idea, used));
  const recycle = unused.length === 0;
  const pool = recycle ? FARM_IDEAS : unused;
  let ordered = pool;
  if (opts?.rotate && pool.length) {
    const cursor = await bumpFarmScan();
    const start = cursor % pool.length;
    ordered = [...pool.slice(start), ...pool.slice(0, start)];
  }
  const ready: ReadyFarmIdea[] = [];
  const chunk = 4;
  for (let i = 0; i < ordered.length && ready.length < limit; i += chunk) {
    const batch = ordered.slice(i, i + chunk);
    const rows = await Promise.all(
      batch.map(async (idea) => {
        const product = await firstInciHit(idea.query);
        if (!product || (!recycle && productAlreadyUsed(product, used))) return null;
        return { ...idea, product } satisfies ReadyFarmIdea;
      }),
    );
    for (const row of rows) {
      if (row && ready.length < limit) ready.push(row);
    }
  }
  return ready;
}

export async function markFarmUsed(input: { key: string; label: string }) {
  const key = ideaKey(input.key);
  if (!key || key.startsWith('__')) return;
  try {
    await ensureDb();
    await sqlClient()`
      INSERT INTO farm_used (idea_key, label)
      VALUES (${key}, ${input.label.slice(0, 120)})
      ON CONFLICT (idea_key) DO UPDATE SET used_at = NOW()
    `;
  } catch {
    /* local / no db */
  }
}

export async function markFarmProductsUsed(products: { name?: string | null; brand?: string | null }[]) {
  for (const product of products) {
    for (const key of productKeysOf(product)) {
      await markFarmUsed({ key, label: String(product.name || key).slice(0, 120) });
    }
    for (const idea of FARM_IDEAS) {
      if (!matchesIdea(product, idea)) continue;
      const label = idea.label.slice(0, 120);
      await markFarmUsed({ key: idea.id, label });
      await markFarmUsed({ key: idea.query, label });
      await markFarmUsed({ key: idea.label, label });
    }
  }
}
