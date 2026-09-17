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
import { farmLookup, farmScores } from '../services/farmCatalog';
import { farmPairs, farmScript, farmWhy } from '../services/farmCopy';
import { allowedFarmImage, farmHeroImage } from '../services/farmHero';
import { farmCoverImage } from '../services/farmCover';
import { markFarmUsed, unusedFarmIdeas } from '../services/farmUsed';

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
  res.setHeader('Cache-Control', 'no-store');
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
  }).map((row) => ({ ...row, why: farmWhy(row) }));
  const product = {
    name: parsed.data.name,
    brand: parsed.data.brand ?? null,
    imageUrl: parsed.data.imageUrl ?? null,
  };
  const pairs = farmPairs(scores);
  const script = farmScript(product, scores, pairs.v1);
  const script2 = farmScript(product, scores, pairs.v2);
  return res.json({
    ok: true,
    product,
    scores,
    script,
    script2,
    pairs: {
      v1: pairs.v1.map((row) => row.id),
      v2: pairs.v2.map((row) => row.id),
    },
  });
});

adminRouter.get('/farm/ideas', requireAdmin, async (_req, res) => {
  try {
    const ideas = await unusedFarmIdeas(8);
    return res.json({ ok: true, ideas });
  } catch (error) {
    console.error(error);
    return res.status(502).json({ ok: false, error: 'IDEAS_FAILED' });
  }
});

adminRouter.post('/farm/hero', requireAdmin, async (req, res) => {
  const parsed = z
    .object({
      query: z.string().min(2).max(160),
      fallback: z.string().url().max(1200).nullable().optional(),
    })
    .safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ ok: false, error: 'INVALID_HERO' });
  }
  try {
    const hero = await farmHeroImage(parsed.data.query, parsed.data.fallback);
    const urls = [...new Set((hero.urls || []).filter(Boolean))].slice(0, 8);
    return res.json({ ok: true, url: hero.url || parsed.data.fallback || null, urls });
  } catch (error) {
    console.error(error);
    return res.json({ ok: true, url: parsed.data.fallback || null, urls: parsed.data.fallback ? [parsed.data.fallback] : [] });
  }
});

adminRouter.post('/farm/cover', requireAdmin, async (req, res) => {
  const parsed = z
    .object({
      imageUrl: z.string().url().max(1200),
      name: z.string().min(2).max(160),
    })
    .safeParse(req.body);
  if (!parsed.success || !allowedFarmImage(parsed.data.imageUrl)) {
    return res.status(400).json({ ok: false, error: 'INVALID_COVER' });
  }
  try {
    const buf = await farmCoverImage(parsed.data.imageUrl, parsed.data.name);
    if (!buf) return res.json({ ok: true, image: null });
    return res.json({ ok: true, image: `data:image/png;base64,${buf.toString('base64')}` });
  } catch (error) {
    console.error(error);
    return res.json({ ok: true, image: null });
  }
});

adminRouter.post('/farm/used', requireAdmin, async (req, res) => {
  const parsed = z
    .object({
      key: z.string().min(2).max(160),
      label: z.string().min(1).max(160),
    })
    .safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ ok: false, error: 'INVALID_USED' });
  }
  await markFarmUsed(parsed.data);
  return res.json({ ok: true });
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
      redirect: 'follow',
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
        Accept: 'image/avif,image/webp,image/apng,image/*,*/*;q=0.8',
        Referer: new URL(raw).origin + '/',
      },
    });
    if (!response.ok) {
      return res.status(404).json({ ok: false, error: 'IMAGE_NOT_FOUND' });
    }
    const type = response.headers.get('content-type') || '';
    if (type.startsWith('text/') || type.includes('json')) {
      return res.status(400).json({ ok: false, error: 'NOT_IMAGE' });
    }
    const buf = Buffer.from(await response.arrayBuffer());
    if (buf.length > 6_000_000) {
      return res.status(413).json({ ok: false, error: 'IMAGE_TOO_LARGE' });
    }
    const magic =
      buf.length >= 12 && buf[0] === 0xff && buf[1] === 0xd8
        ? 'image/jpeg'
        : buf[0] === 0x89 && buf[1] === 0x50
          ? 'image/png'
          : buf[0] === 0x47 && buf[1] === 0x49
            ? 'image/gif'
            : buf.slice(8, 12).toString() === 'WEBP'
              ? 'image/webp'
              : null;
    if (!type.startsWith('image/') && !magic) {
      return res.status(400).json({ ok: false, error: 'NOT_IMAGE' });
    }
    res.setHeader('Content-Type', type.startsWith('image/') ? type : magic || 'image/jpeg');
    res.setHeader('Cache-Control', 'public, max-age=86400');
    return res.send(buf);
  } catch {
    return res.status(502).json({ ok: false, error: 'IMAGE_FETCH' });
  } finally {
    clearTimeout(timer);
  }
});
