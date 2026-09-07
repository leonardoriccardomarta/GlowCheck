import { createHmac, randomBytes, timingSafeEqual } from 'crypto';
import { env } from '../config/env';

export type AuthUser = {
  id: string;
  name: string;
  email: string;
  provider: 'email' | 'google' | 'apple';
};

type StoredUser = AuthUser & { passwordHash?: string };

const users = new Map<string, StoredUser>();

function hashPassword(password: string) {
  const secret = env.AUTH_JWT_SECRET || 'glowcheck-sandbox';
  return createHmac('sha256', secret).update(password).digest('hex');
}

function signToken(user: AuthUser) {
  const payload = Buffer.from(
    JSON.stringify({ sub: user.id, email: user.email, provider: user.provider, exp: Date.now() + 1000 * 60 * 60 * 24 * 30 })
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

export function registerUser(input: { name: string; email: string; password: string }) {
  const email = input.email.trim().toLowerCase();
  if (!email.includes('@') || input.password.length < 6 || input.name.trim().length < 1) {
    throw new Error('Name, email and a password of at least 6 characters.');
  }
  if (users.has(email)) {
    throw new Error('An account with this email already exists.');
  }
  const user: StoredUser = {
    id: randomBytes(8).toString('hex'),
    name: input.name.trim(),
    email,
    provider: 'email',
    passwordHash: hashPassword(input.password),
  };
  users.set(email, user);
  return sessionOf(user);
}

export function loginUser(input: { email: string; password: string }) {
  const email = input.email.trim().toLowerCase();
  const stored = users.get(email);
  if (!stored || !stored.passwordHash || !safeEqual(stored.passwordHash, hashPassword(input.password))) {
    throw new Error('Email or password does not match.');
  }
  return sessionOf(stored);
}

export function socialUser(input: { provider: 'google' | 'apple'; email?: string; name?: string }) {
  const email = (input.email ?? `${input.provider}@glowcheck.local`).trim().toLowerCase();
  const existing = users.get(email);
  const user: StoredUser = existing ?? {
    id: randomBytes(8).toString('hex'),
    name: (input.name ?? (input.provider === 'apple' ? 'Apple user' : 'Google user')).trim(),
    email,
    provider: input.provider,
  };
  user.provider = input.provider;
  users.set(email, user);
  return sessionOf(user);
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
    token: signToken(publicUser),
    user: publicUser,
  };
}
