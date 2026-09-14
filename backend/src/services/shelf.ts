type ShelfItem = Record<string, unknown> & { at: number };

const shelves = new Map<string, ShelfItem[]>();

export function listShelf(userId: string): ShelfItem[] {
  return shelves.get(userId) ?? [];
}

export function saveShelfItem(userId: string, item: ShelfItem): ShelfItem[] {
  const current = shelves.get(userId) ?? [];
  const next = [item, ...current.filter((entry) => entry.at !== item.at)].slice(0, 40);
  shelves.set(userId, next);
  return next;
}
