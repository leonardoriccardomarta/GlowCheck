import { Router } from 'express';
import { z } from 'zod';
import { loginUser, registerUser, socialUser } from '../services/auth';

export const authRouter = Router();

const registerSchema = z.object({
  name: z.string().min(1).max(80),
  email: z.string().email().max(120),
  password: z.string().min(6).max(120),
});

const loginSchema = z.object({
  email: z.string().email().max(120),
  password: z.string().min(6).max(120),
});

const socialSchema = z.object({
  provider: z.enum(['google', 'apple']),
  email: z.string().email().max(120).optional(),
  name: z.string().max(80).optional(),
  idToken: z.string().max(8000).optional(),
  clientId: z.string().max(200).optional(),
});

function fail(res: { status: (code: number) => { json: (body: unknown) => unknown } }, errorKey: string, error: string) {
  return res.status(400).json({ ok: false, errorKey, error });
}

function keyFromMessage(message: string) {
  if (message.includes('does not match')) return 'err_email_pass';
  if (message.includes('already exists')) return 'auth_exists';
  if (message.includes('at least 6')) return 'login_fields';
  if (message.includes('Unsupported')) return 'auth_social';
  return 'auth_failed';
}

authRouter.post('/register', async (req, res) => {
  const parsed = registerSchema.safeParse(req.body);
  if (!parsed.success) {
    return fail(res, 'login_fields', 'Name, email and a password of at least 6 characters.');
  }
  try {
    return res.json(await registerUser(parsed.data));
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Register failed.';
    if (message.includes('DATABASE_URL')) {
      return res.status(503).json({ ok: false, errorKey: 'auth_failed', error: message });
    }
    return fail(res, keyFromMessage(message), message);
  }
});

authRouter.post('/login', async (req, res) => {
  const parsed = loginSchema.safeParse(req.body);
  if (!parsed.success) {
    return fail(res, 'err_email_pass', 'Email or password does not match.');
  }
  try {
    return res.json(await loginUser(parsed.data));
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Login failed.';
    if (message.includes('DATABASE_URL')) {
      return res.status(503).json({ ok: false, errorKey: 'auth_failed', error: message });
    }
    return fail(res, keyFromMessage(message), message);
  }
});

authRouter.post('/social', async (req, res) => {
  const parsed = socialSchema.safeParse(req.body);
  if (!parsed.success) {
    return fail(res, 'auth_social', 'Unsupported social login.');
  }
  try {
    return res.json(await socialUser(parsed.data));
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Social login failed.';
    if (message.includes('DATABASE_URL')) {
      return res.status(503).json({ ok: false, errorKey: 'auth_failed', error: message });
    }
    return fail(res, keyFromMessage(message), message);
  }
});
