import { Router } from 'express';
import { z } from 'zod';
import { userFromRequest } from '../services/auth';
import { listShelf, saveShelfItem } from '../services/shelf';

export const shelfRouter = Router();

const shelfItemSchema = z.object({
  productName: z.string().min(1).max(200),
  score: z.number().int().min(0).max(100),
  badge: z.string().min(1).max(40),
  headline: z.string().max(400).optional().default(''),
  why: z.string().max(4000).optional().default(''),
  at: z.number().int(),
  occlusionAlert: z.enum(['low', 'medium', 'high']).optional().default('low'),
  dupeId: z.string().max(80).nullable().optional(),
  dupe: z.unknown().nullable().optional(),
  ingredients: z.array(z.unknown()).optional().default([]),
  flagged: z.array(z.unknown()).optional().default([]),
});

function unauthorized(res: { status: (code: number) => { json: (body: unknown) => unknown } }) {
  return res.status(401).json({ ok: false, error: 'UNAUTHORIZED' });
}

shelfRouter.get('/', async (req, res) => {
  const user = await userFromRequest(req);
  if (!user) return unauthorized(res);
  return res.json({ ok: true, items: listShelf(user.id) });
});

shelfRouter.post('/', async (req, res) => {
  const user = await userFromRequest(req);
  if (!user) return unauthorized(res);
  const parsed = shelfItemSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ ok: false, error: 'INVALID_SCAN' });
  }
  const items = saveShelfItem(user.id, parsed.data);
  return res.json({ ok: true, items });
});
