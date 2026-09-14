import { ensureDb, sqlClient } from '../db';

export type ShelfItem = Record<string, unknown> & { at: number };

const MAX_ITEMS = 40;

function asItem(value: unknown): ShelfItem | null {
  let raw: unknown = value;
  if (typeof raw === 'string') {
    try {
      raw = JSON.parse(raw);
    } catch {
      return null;
    }
  }
  if (!raw || typeof raw !== 'object' || Array.isArray(raw)) return null;
  const row = raw as Record<string, unknown>;
  const at = typeof row.at === 'number' ? row.at : Number(row.at);
  if (!Number.isFinite(at)) return null;
  return { ...row, at };
}

function rowsToItems(rows: Array<Record<string, unknown>>): ShelfItem[] {
  return rows
    .map((row) => asItem(row.item))
    .filter((item): item is ShelfItem => item != null)
    .sort((a, b) => b.at - a.at)
    .slice(0, MAX_ITEMS);
}

export async function listShelf(userId: string): Promise<ShelfItem[]> {
  await ensureDb();
  const rows = await sqlClient()`
    SELECT item
    FROM shelf_items
    WHERE user_id = ${userId}
    ORDER BY item_at DESC
    LIMIT ${MAX_ITEMS}
  `;
  return rowsToItems(rows as Array<Record<string, unknown>>);
}

async function trimShelf(userId: string) {
  await sqlClient()`
    DELETE FROM shelf_items
    WHERE user_id = ${userId}
      AND item_at IN (
        SELECT item_at
        FROM shelf_items
        WHERE user_id = ${userId}
        ORDER BY item_at DESC
        OFFSET ${MAX_ITEMS}
      )
  `;
}

async function upsertItem(userId: string, item: ShelfItem) {
  await sqlClient()`
    INSERT INTO shelf_items (user_id, item_at, item)
    VALUES (${userId}, ${item.at}, ${item as never})
    ON CONFLICT (user_id, item_at) DO UPDATE SET item = EXCLUDED.item
  `;
}

export async function saveShelfItem(userId: string, item: ShelfItem): Promise<ShelfItem[]> {
  await ensureDb();
  await upsertItem(userId, item);
  await trimShelf(userId);
  return listShelf(userId);
}

export async function mergeShelf(userId: string, items: ShelfItem[]): Promise<ShelfItem[]> {
  await ensureDb();
  const unique = new Map<number, ShelfItem>();
  for (const item of items) {
    unique.set(item.at, item);
  }
  for (const item of unique.values()) {
    await upsertItem(userId, item);
  }
  await trimShelf(userId);
  return listShelf(userId);
}
