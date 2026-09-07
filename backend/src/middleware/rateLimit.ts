import type { Request, Response, NextFunction } from 'express';
import { copy } from '../i18n/scoreCopy';

const WINDOW_MS = 60 * 60 * 1000;
const MAX = 60;

type Bucket = { count: number; resetAt: number };

const hits = new Map<string, Bucket>();

export function rateLimit(req: Request, res: Response, next: NextFunction) {
  const ip = req.ip ?? req.socket.remoteAddress ?? 'unknown';
  const now = Date.now();
  const current = hits.get(ip);

  if (!current || now > current.resetAt) {
    hits.set(ip, { count: 1, resetAt: now + WINDOW_MS });
    return next();
  }

  if (current.count >= MAX) {
    return res.status(429).json({
      readable: false,
      productName: null,
      compatibilityScore: 0,
      statusBadge: 'CAUTION',
      headline: copy((req.body as { profile?: { locale?: string } })?.profile?.locale, 'too_many'),
      whyForYou: '',
      occlusionAlert: 'low',
      flaggedIngredients: [],
      ingredients: [],
      dupeId: null,
      dupe: null,
      errorCode: 'INTERNAL',
    });
  }

  current.count += 1;
  return next();
}
