import { INGREDIENT_DB } from '../data/ingredients';

function fold(value: string) {
  return value
    .normalize('NFD')
    .replace(/\p{M}/gu, '')
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, ' ')
    .trim();
}

function levenshtein(a: string, b: string) {
  if (a === b) return 0;
  if (!a.length) return b.length;
  if (!b.length) return a.length;
  if (Math.abs(a.length - b.length) > 3) return 99;
  const row = Array.from({ length: b.length + 1 }, (_, i) => i);
  for (let i = 1; i <= a.length; i += 1) {
    let prev = i - 1;
    row[0] = i;
    for (let j = 1; j <= b.length; j += 1) {
      const cur = row[j];
      const cost = a[i - 1] === b[j - 1] ? 0 : 1;
      row[j] = Math.min(row[j] + 1, row[j - 1] + 1, prev + cost);
      prev = cur;
    }
  }
  return row[b.length];
}

type IndexRow = { key: string; name: string };

const index: IndexRow[] = [];
const exact = new Map<string, string>();

for (const row of INGREDIENT_DB) {
  const keys = [row.name, ...(row.aliases ?? [])];
  for (const alias of keys) {
    const key = fold(alias);
    if (!key) continue;
    if (!exact.has(key)) exact.set(key, row.name);
    index.push({ key, name: row.name });
  }
}

function fuzzyName(raw: string): string | null {
  const key = fold(raw);
  if (!key) return null;
  const hit = exact.get(key);
  if (hit) return hit;

  if (key.length < 5) return null;
  const maxDist = key.length < 8 ? 1 : 2;
  let best: { name: string; dist: number } | null = null;
  for (const row of index) {
    if (Math.abs(row.key.length - key.length) > 3) continue;
    const dist = levenshtein(key, row.key);
    if (dist > maxDist) continue;
    if (!best || dist < best.dist) best = { name: row.name, dist };
    if (dist === 0) break;
  }
  return best?.name ?? null;
}

export function canonicalizeIngredient(raw: string): string {
  const cleaned = raw.replace(/\s+/g, ' ').replace(/^[\d.\s%-]+/, '').trim();
  if (cleaned.length < 3) return cleaned;
  return fuzzyName(cleaned) ?? cleaned;
}

export function isKnownInci(raw: string): boolean {
  const cleaned = raw.replace(/\s+/g, ' ').replace(/^[\d.\s%-]+/, '').trim();
  if (cleaned.length < 3) return false;
  return fuzzyName(cleaned) !== null;
}

export function knownInciCount(list: string[]): number {
  return list.filter(isKnownInci).length;
}

export function canonicalizeIngredients(list: string[]): string[] {
  const seen = new Set<string>();
  const out: string[] = [];
  for (const raw of list) {
    const name = canonicalizeIngredient(raw);
    if (name.length < 3) continue;
    const key = fold(name);
    if (seen.has(key)) continue;
    seen.add(key);
    out.push(name);
  }
  return out.slice(0, 120);
}
