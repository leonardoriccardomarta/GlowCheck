import { createHmac, timingSafeEqual } from 'crypto';
import { env } from '../config/env';

function secret() {
  return env.AUTH_JWT_SECRET || 'glowcheck-sandbox';
}

function safeEqual(a: string, b: string) {
  const left = Buffer.from(a);
  const right = Buffer.from(b);
  if (left.length !== right.length) return false;
  return timingSafeEqual(left, right);
}

export function adminConfigured() {
  return Boolean(env.ADMIN_EMAIL?.includes('@') && (env.ADMIN_PASSWORD?.length ?? 0) >= 8);
}

export function checkAdminLogin(email: string, password: string) {
  if (!adminConfigured()) return false;
  const wantEmail = createHmac('sha256', secret()).update(env.ADMIN_EMAIL!.trim().toLowerCase()).digest('hex');
  const gotEmail = createHmac('sha256', secret()).update(email.trim().toLowerCase()).digest('hex');
  const wantPass = createHmac('sha256', secret()).update(env.ADMIN_PASSWORD!).digest('hex');
  const gotPass = createHmac('sha256', secret()).update(password).digest('hex');
  return safeEqual(wantEmail, gotEmail) && safeEqual(wantPass, gotPass);
}

export function issueAdminToken(email: string) {
  const payload = Buffer.from(
    JSON.stringify({
      sub: 'admin',
      email: email.trim().toLowerCase(),
      role: 'admin',
      exp: Date.now() + 1000 * 60 * 60 * 24 * 30,
    })
  ).toString('base64url');
  const sig = createHmac('sha256', secret()).update(payload).digest('base64url');
  return `${payload}.${sig}`;
}

export function verifyAdminToken(token: string): { email: string } | null {
  const [payload, sig] = token.split('.');
  if (!payload || !sig) return null;
  const expected = createHmac('sha256', secret()).update(payload).digest('base64url');
  if (!safeEqual(sig, expected)) return null;
  try {
    const data = JSON.parse(Buffer.from(payload, 'base64url').toString('utf8')) as {
      role?: string;
      email?: string;
      exp?: number;
    };
    if (data.role !== 'admin' || !data.email) return null;
    if (typeof data.exp === 'number' && data.exp < Date.now()) return null;
    return { email: data.email };
  } catch {
    return null;
  }
}

export function adminFromRequest(req: { headers: { authorization?: string } }) {
  const header = req.headers.authorization;
  if (!header?.startsWith('Bearer ')) return null;
  return verifyAdminToken(header.slice(7).trim());
}
