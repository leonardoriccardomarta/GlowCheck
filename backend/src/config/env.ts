import 'dotenv/config';
import { z } from 'zod';

const schema = z.object({
  PORT: z.string().default('4000'),
  GEMINI_API_KEY: z.string().optional(),
  OPENAI_API_KEY: z.string().optional(),
  GROQ_API_KEY: z.string().optional(),
  FAL_KEY: z.string().optional(),
  VISION_MODEL: z.string().default('qwen/qwen3.6-27b'),
  DUPE_MODEL: z.string().default('openai/gpt-oss-20b'),
  MOCK_VISION: z
    .string()
    .optional()
    .transform((value) => value === 'true'),
  AUTH_JWT_SECRET: z.string().optional(),
  DATABASE_URL: z.string().optional(),
  GOOGLE_CLIENT_ID: z.string().optional(),
  PUBLIC_DIR: z.string().optional(),
  FRONTEND_ORIGIN: z.string().optional(),
  STRIPE_SECRET_KEY: z.string().optional(),
  STRIPE_WEBHOOK_SECRET: z.string().optional(),
  ADMIN_EMAIL: z.string().email().optional(),
  ADMIN_PASSWORD: z.string().min(8).max(120).optional(),
});

const parsed = schema.safeParse(process.env);

if (!parsed.success) {
  console.error('Invalid environment configuration', parsed.error.flatten().fieldErrors);
  process.exit(1);
}

export const env = parsed.data;
