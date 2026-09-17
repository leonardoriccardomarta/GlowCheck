import { ensureDb, sqlClient } from '../db';
import { DEFAULT_USED_IDEAS, FARM_IDEAS, ideaKey, type FarmIdea } from '../data/farmIdeas';
import { farmLookup, type FarmHit } from './farmCatalog';

export type ReadyFarmIdea = FarmIdea & { product: FarmHit };

const hitCache = new Map<string, FarmHit | null>();

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
    return new Set(rows.map((row) => String(row.idea_key)));
  } catch {
    return new Set(DEFAULT_USED_IDEAS);
  }
}

function isUnused(idea: FarmIdea, used: Set<string>) {
  return !used.has(idea.id) && !used.has(ideaKey(idea.query)) && !used.has(ideaKey(idea.label));
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

export async function unusedFarmIdeas(limit = 8): Promise<ReadyFarmIdea[]> {
  const used = await usedKeys();
  const unused = FARM_IDEAS.filter((idea) => isUnused(idea, used));
  const ready: ReadyFarmIdea[] = [];
  const chunk = 4;
  for (let i = 0; i < unused.length && ready.length < limit; i += chunk) {
    const batch = unused.slice(i, i + chunk);
    const rows = await Promise.all(
      batch.map(async (idea) => {
        const product = await firstInciHit(idea.query);
        return product ? ({ ...idea, product } satisfies ReadyFarmIdea) : null;
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
  if (!key) return;
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
