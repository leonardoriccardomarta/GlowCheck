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
  idToken: z.string().max(4000).optional(),
  clientId: z.string().max(200).optional(),
});

authRouter.post('/register', (req, res) => {
  const parsed = registerSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ ok: false, error: 'Name, email and a password of at least 6 characters.' });
  }
  try {
    return res.json(registerUser(parsed.data));
  } catch (error) {
    return res.status(400).json({ ok: false, error: error instanceof Error ? error.message : 'Register failed.' });
  }
});

authRouter.post('/login', (req, res) => {
  const parsed = loginSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ ok: false, error: 'Email or password does not match.' });
  }
  try {
    return res.json(loginUser(parsed.data));
  } catch (error) {
    return res.status(400).json({ ok: false, error: error instanceof Error ? error.message : 'Login failed.' });
  }
});

authRouter.post('/social', (req, res) => {
  const parsed = socialSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ ok: false, error: 'Unsupported social login.' });
  }
  try {
    return res.json(socialUser(parsed.data));
  } catch (error) {
    return res.status(400).json({ ok: false, error: error instanceof Error ? error.message : 'Social login failed.' });
  }
});
