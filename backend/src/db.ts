import { neon, type NeonQueryFunction } from '@neondatabase/serverless';
import { env } from './config/env';

type Sql = NeonQueryFunction<false, false>;

let sql: Sql | null = null;
let ready: Promise<void> | null = null;

export function sqlClient(): Sql {
  const url = env.DATABASE_URL?.trim();
  if (!url) {
    throw new Error('DATABASE_URL is not set');
  }
  if (!sql) sql = neon(url);
  return sql;
}

export async function ensureDb() {
  if (!ready) {
    ready = (async () => {
      const client = sqlClient();
      await client`
        CREATE TABLE IF NOT EXISTS users (
          id TEXT PRIMARY KEY,
          email TEXT NOT NULL UNIQUE,
          name TEXT NOT NULL,
          provider TEXT NOT NULL,
          password_hash TEXT,
          is_pro BOOLEAN NOT NULL DEFAULT FALSE,
          used_free BOOLEAN NOT NULL DEFAULT FALSE,
          created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
        )
      `;
    })().catch((error) => {
      ready = null;
      throw error;
    });
  }
  await ready;
}
