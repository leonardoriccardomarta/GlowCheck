import type { Request, Response } from 'express';
import type { StoredUser } from './auth';
import { markFreeUsed } from './auth';

export const FREE_SCAN_COOKIE = 'glow_free_used';
const IP_MAX = 3;
const IP_WINDOW_MS = 24 * 60 * 60 * 1000;

type IpHit = { n: number; resetAt: number };
const ipHits = new Map<string, IpHit>();

export function readCookie(req: Request, name: string): string | undefined {
  const raw = req.headers.cookie;
  if (!raw) return undefined;
  for (const part of raw.split(';')) {
    const trimmed = part.trim();
    const eq = trimmed.indexOf('=');
    if (eq < 0) continue;
    if (trimmed.slice(0, eq) !== name) continue;
    try {
      return decodeURIComponent(trimmed.slice(eq + 1));
    } catch {
      return trimmed.slice(eq + 1);
    }
  }
  return undefined;
}

export function clientIp(req: Request): string {
  const forwarded = req.headers['x-forwarded-for'];
  if (typeof forwarded === 'string' && forwarded.trim()) {
    return forwarded.split(',')[0].trim();
  }
  if (Array.isArray(forwarded) && forwarded[0]) {
    return forwarded[0].split(',')[0].trim();
  }
  return req.ip || req.socket.remoteAddress || 'unknown';
}

function cookieUsed(req: Request) {
  return readCookie(req, FREE_SCAN_COOKIE) === '1';
}

function ipOverLimit(ip: string) {
  const hit = ipHits.get(ip);
  if (!hit) return false;
  if (hit.resetAt <= Date.now()) {
    ipHits.delete(ip);
    return false;
  }
  return hit.n >= IP_MAX;
}

export async function syncFreeFromCookie(req: Request, user: StoredUser | null) {
  if (user && !user.isPro && cookieUsed(req) && !user.usedFree) {
    await markFreeUsed(user);
  }
}

export function freeScanBlocked(req: Request, user: StoredUser | null): boolean {
  if (user?.isPro) return false;
  if (user?.usedFree) return true;
  if (cookieUsed(req)) return true;
  return ipOverLimit(clientIp(req));
}

export async function consumeFreeScan(req: Request, res: Response, user: StoredUser | null) {
  if (user?.isPro) return;
  if (user) await markFreeUsed(user);
  const proto = req.headers['x-forwarded-proto'];
  const https =
    Boolean(process.env.VERCEL) ||
    req.secure ||
    proto === 'https' ||
    (Array.isArray(proto) && proto[0] === 'https');
  res.cookie(FREE_SCAN_COOKIE, '1', {
    httpOnly: true,
    secure: https,
    sameSite: https ? 'none' : 'lax',
    maxAge: 365 * 24 * 60 * 60 * 1000,
    path: '/',
  });
  const ip = clientIp(req);
  const now = Date.now();
  const hit = ipHits.get(ip);
  if (!hit || hit.resetAt <= now) {
    ipHits.set(ip, { n: 1, resetAt: now + IP_WINDOW_MS });
    return;
  }
  hit.n += 1;
}
