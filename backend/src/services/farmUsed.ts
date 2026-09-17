import { ensureDb, sqlClient } from '../db';
import { DEFAULT_USED_IDEAS, FARM_IDEAS, ideaKey, type FarmIdea } from '../data/farmIdeas';

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

export async function unusedFarmIdeas(limit = 6): Promise<FarmIdea[]> {
  try {
    await seedDefaults();
    const rows = await sqlClient()`SELECT idea_key FROM farm_used`;
    const used = new Set(rows.map((row) => String(row.idea_key)));
    return FARM_IDEAS.filter(
      (idea) =>
        !used.has(idea.id) &&
        !used.has(ideaKey(idea.query)) &&
        !used.has(ideaKey(idea.label))
    ).slice(0, limit);
  } catch {
    return FARM_IDEAS.filter((idea) => !DEFAULT_USED_IDEAS.includes(idea.id)).slice(0, limit);
  }
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
