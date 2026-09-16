import { createHmac, randomBytes, timingSafeEqual } from 'crypto';
import { env } from '../config/env';
import { ensureDb, sqlClient } from '../db';
import { verifyGoogleSignIn } from './googleId';

export type AuthUser = {
  id: string;
  name: string;
  email: string;
  provider: 'email' | 'google' | 'apple';
};

export type StoredUser = AuthUser & {
  passwordHash?: string;
  isPro?: boolean;
  usedFree?: boolean;
};

function hashPassword(password: string) {
  const secret = env.AUTH_JWT_SECRET || 'glowcheck-sandbox';
  return createHmac('sha256', secret).update(password).digest('hex');
}

function signToken(user: StoredUser) {
  const payload = Buffer.from(
    JSON.stringify({
      sub: user.id,
      email: user.email,
      provider: user.provider,
      isPro: Boolean(user.isPro),
      exp: Date.now() + 1000 * 60 * 60 * 24 * 30,
    })
  ).toString('base64url');
  const secret = env.AUTH_JWT_SECRET || 'glowcheck-sandbox';
  const sig = createHmac('sha256', secret).update(payload).digest('base64url');
  return `${payload}.${sig}`;
}

function safeEqual(a: string, b: string) {
  const left = Buffer.from(a);
  const right = Buffer.from(b);
  if (left.length !== right.length) return false;
  return timingSafeEqual(left, right);
}

function asProvider(value: string | undefined): StoredUser['provider'] {
  if (value === 'google' || value === 'apple') return value;
  return 'email';
}

function rowToUser(row: Record<string, unknown>): StoredUser {
  return {
    id: String(row.id),
    name: String(row.name),
    email: String(row.email),
    provider: asProvider(String(row.provider)),
    passwordHash: row.password_hash ? String(row.password_hash) : undefined,
    isPro: Boolean(row.is_pro),
    usedFree: Boolean(row.used_free),
  };
}

async function findByEmail(email: string): Promise<StoredUser | null> {
  await ensureDb();
  const rows = await sqlClient()`
    SELECT id, email, name, provider, password_hash, is_pro, used_free
    FROM users
    WHERE email = ${email}
    LIMIT 1
  `;
  return rows[0] ? rowToUser(rows[0]) : null;
}

export async function registerUser(input: { name: string; email: string; password: string }) {
  const email = input.email.trim().toLowerCase();
  if (!email.includes('@') || input.password.length < 6 || input.name.trim().length < 1) {
    throw new Error('Name, email and a password of at least 6 characters.');
  }
  await ensureDb();
  const existing = await findByEmail(email);
  if (existing) {
    if (existing.passwordHash || existing.provider === 'google' || existing.provider === 'apple') {
      throw new Error('An account with this email already exists.');
    }
    const claimed = await sqlClient()`
      UPDATE users
      SET
        name = ${input.name.trim()},
        provider = 'email',
        password_hash = ${hashPassword(input.password)}
      WHERE email = ${email}
      RETURNING id, email, name, provider, password_hash, is_pro, used_free
    `;
    if (!claimed[0]) {
      throw new Error('An account with this email already exists.');
    }
    return sessionOf(rowToUser(claimed[0]));
  }
  const rows = await sqlClient()`
    INSERT INTO users (id, email, name, provider, password_hash)
    VALUES (
      ${randomBytes(8).toString('hex')},
      ${email},
      ${input.name.trim()},
      'email',
      ${hashPassword(input.password)}
    )
    ON CONFLICT (email) DO NOTHING
    RETURNING id, email, name, provider, password_hash, is_pro, used_free
  `;
  if (!rows[0]) {
    throw new Error('An account with this email already exists.');
  }
  return sessionOf(rowToUser(rows[0]));
}

export async function loginUser(input: { email: string; password: string }) {
  const email = input.email.trim().toLowerCase();
  const stored = await findByEmail(email);
  if (stored && !stored.passwordHash) {
    throw new Error('An account with this email already exists.');
  }
  if (!stored || !stored.passwordHash || !safeEqual(stored.passwordHash, hashPassword(input.password))) {
    throw new Error('Email or password does not match.');
  }
  return sessionOf(stored);
}

export async function socialUser(input: {
  provider: 'google' | 'apple';
  email?: string;
  name?: string;
  idToken?: string;
  accessToken?: string;
}) {
  let email: string;
  let name: string;
  if (input.provider === 'google') {
    const profile = await verifyGoogleSignIn({
      idToken: input.idToken,
      accessToken: input.accessToken,
    });
    email = profile.email;
    name = profile.name;
  } else {
    email = (input.email ?? `${input.provider}@glowcheck.local`).trim().toLowerCase();
    name = (input.name ?? 'Apple user').trim();
  }
  await ensureDb();
  const existing = await findByEmail(email);
  if (existing) {
    if (existing.provider === 'email' && existing.passwordHash) {
      throw new Error('An account with this email already exists.');
    }
    if (existing.provider !== input.provider) {
      await sqlClient()`
        UPDATE users
        SET provider = ${input.provider}, name = ${name}
        WHERE email = ${email}
      `;
      existing.provider = input.provider;
      existing.name = name;
    }
    return sessionOf(existing);
  }
  const rows = await sqlClient()`
    INSERT INTO users (id, email, name, provider)
    VALUES (${randomBytes(8).toString('hex')}, ${email}, ${name}, ${input.provider})
    ON CONFLICT (email) DO NOTHING
    RETURNING id, email, name, provider, password_hash, is_pro, used_free
  `;
  if (!rows[0]) {
    throw new Error('An account with this email already exists.');
  }
  return sessionOf(rowToUser(rows[0]));
}

function sessionOf(user: StoredUser) {
  const publicUser: AuthUser = {
    id: user.id,
    name: user.name,
    email: user.email,
    provider: user.provider,
  };
  return {
    ok: true as const,
    live: Boolean(env.AUTH_JWT_SECRET),
    token: signToken(user),
    user: publicUser,
    isPro: Boolean(user.isPro),
  };
}

export async function verifyToken(token: string): Promise<StoredUser | null> {
  const [payload, sig] = token.split('.');
  if (!payload || !sig) return null;
  const secret = env.AUTH_JWT_SECRET || 'glowcheck-sandbox';
  const expected = createHmac('sha256', secret).update(payload).digest('base64url');
  if (!safeEqual(sig, expected)) return null;
  try {
    const data = JSON.parse(Buffer.from(payload, 'base64url').toString('utf8')) as {
      sub?: string;
      email?: string;
      provider?: string;
      isPro?: boolean;
      exp?: number;
    };
    if (!data.email || (typeof data.exp === 'number' && data.exp < Date.now())) return null;
    const email = data.email.trim().toLowerCase();
    const existing = await findByEmail(email);
    if (existing) {
      if (data.isPro && !existing.isPro) {
        await sqlClient()`UPDATE users SET is_pro = TRUE WHERE email = ${email}`;
        existing.isPro = true;
      }
      return existing;
    }
    const provider = asProvider(data.provider);
    const rows = await sqlClient()`
      INSERT INTO users (id, email, name, provider, is_pro)
      VALUES (
        ${data.sub || randomBytes(8).toString('hex')},
        ${email},
        ${email.split('@')[0] || 'GlowCheck'},
        ${provider},
        ${Boolean(data.isPro)}
      )
      ON CONFLICT (email) DO UPDATE SET
        is_pro = users.is_pro OR EXCLUDED.is_pro
      RETURNING id, email, name, provider, password_hash, is_pro, used_free
    `;
    return rows[0] ? rowToUser(rows[0]) : null;
  } catch {
    return null;
  }
}

export async function issueSession(email: string) {
  const user = await findByEmail(email.trim().toLowerCase());
  return user ? sessionOf(user) : null;
}

export async function userFromRequest(req: { headers: { authorization?: string } }): Promise<StoredUser | null> {
  const header = req.headers.authorization;
  if (!header?.startsWith('Bearer ')) return null;
  return verifyToken(header.slice(7).trim());
}

export async function markPro(email: string) {
  const key = email.trim().toLowerCase();
  if (!key.includes('@')) return;
  await ensureDb();
  await sqlClient()`
    INSERT INTO users (id, email, name, provider, is_pro)
    VALUES (
      ${randomBytes(8).toString('hex')},
      ${key},
      ${key.split('@')[0] || 'GlowCheck'},
      'pending',
      TRUE
    )
    ON CONFLICT (email) DO UPDATE SET is_pro = TRUE
  `;
}

export async function markFreeUsed(user: StoredUser) {
  user.usedFree = true;
  await ensureDb();
  await sqlClient()`UPDATE users SET used_free = TRUE WHERE id = ${user.id}`;
}
