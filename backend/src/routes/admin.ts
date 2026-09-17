import { Router } from 'express';
import path from 'path';
import { z } from 'zod';
import { env } from '../config/env';
import {
  adminConfigured,
  adminFromRequest,
  checkAdminLogin,
  issueAdminToken,
} from '../services/adminAuth';
import { allowedFarmImage, farmLookup, farmScores } from '../services/farmCatalog';

export const adminRouter = Router();

function adminDir() {
  const raw = env.PUBLIC_DIR || path.join(process.cwd(), 'public');
  return path.resolve(raw, 'admin');
}

function requireAdmin(req: { headers: { authorization?: string } }, res: { status: (code: number) => { json: (body: unknown) => unknown } }, next: () => void) {
  if (!adminFromRequest(req)) {
    return res.status(401).json({ ok: false, error: 'ADMIN_REQUIRED' });
  }
  return next();
}

adminRouter.get('/', (_req, res) => {
  res.sendFile(path.join(adminDir(), 'index.html'));
});

adminRouter.post('/login', (req, res) => {
  if (!adminConfigured()) {
    return res.status(503).json({ ok: false, error: 'ADMIN_NOT_CONFIGURED' });
  }
  const parsed = z
    .object({
      email: z.string().email().max(120),
      password: z.string().min(8).max(120),
    })
    .safeParse(req.body);
  if (!parsed.success || !checkAdminLogin(parsed.data.email, parsed.data.password)) {
    return res.status(401).json({ ok: false, error: 'ADMIN_LOGIN' });
  }
  return res.json({
    ok: true,
    token: issueAdminToken(parsed.data.email),
    email: parsed.data.email.trim().toLowerCase(),
  });
});

adminRouter.post('/farm/lookup', requireAdmin, async (req, res) => {
  const parsed = z.object({ query: z.string().min(2).max(160) }).safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ ok: false, error: 'INVALID_QUERY' });
  }
  try {
    const products = await farmLookup(parsed.data.query);
    return res.json({ ok: true, products });
  } catch (error) {
    console.error(error);
    return res.status(502).json({ ok: false, error: 'LOOKUP_FAILED' });
  }
});

adminRouter.post('/farm/build', requireAdmin, (req, res) => {
  const parsed = z
    .object({
      name: z.string().min(1).max(160),
      brand: z.string().max(80).nullable().optional(),
      imageUrl: z.string().url().max(500).nullable().optional(),
      ingredients: z.array(z.string().min(2).max(120)).min(1).max(80),
    })
    .safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ ok: false, error: 'INVALID_PRODUCT' });
  }
  const scores = farmScores({
    name: parsed.data.name,
    ingredients: parsed.data.ingredients,
  });
  return res.json({
    ok: true,
    product: {
      name: parsed.data.name,
      brand: parsed.data.brand ?? null,
      imageUrl: parsed.data.imageUrl ?? null,
    },
    scores,
  });
});

adminRouter.get('/farm/image', requireAdmin, async (req, res) => {
  const raw = typeof req.query.url === 'string' ? req.query.url : '';
  if (!allowedFarmImage(raw)) {
    return res.status(400).json({ ok: false, error: 'INVALID_IMAGE' });
  }
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), 8000);
  try {
    const response = await fetch(raw, {
      signal: controller.signal,
      headers: { 'User-Agent': 'GlowCheck/1.0 (tiktok farm; https://www.glow-check.com)' },
    });
    if (!response.ok) {
      return res.status(404).json({ ok: false, error: 'IMAGE_NOT_FOUND' });
    }
    const type = response.headers.get('content-type') || 'image/jpeg';
    if (!type.startsWith('image/')) {
      return res.status(400).json({ ok: false, error: 'NOT_IMAGE' });
    }
    const buf = Buffer.from(await response.arrayBuffer());
    if (buf.length > 6_000_000) {
      return res.status(413).json({ ok: false, error: 'IMAGE_TOO_LARGE' });
    }
    res.setHeader('Content-Type', type);
    res.setHeader('Cache-Control', 'public, max-age=86400');
    return res.send(buf);
  } catch {
    return res.status(502).json({ ok: false, error: 'IMAGE_FETCH' });
  } finally {
    clearTimeout(timer);
  }
});
