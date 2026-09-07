import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import fs from 'fs';
import path from 'path';
import { analyzeRouter } from './routes/analyze';
import { authRouter } from './routes/auth';
import { rateLimit } from './middleware/rateLimit';
import { env } from './config/env';

function publicDir() {
  const raw = env.PUBLIC_DIR || path.join(process.cwd(), 'public');
  return path.resolve(raw);
}

export function createApp() {
  const app = express();
  const webRoot = publicDir();
  const hasWeb = fs.existsSync(path.join(webRoot, 'index.html'));

  app.set('trust proxy', 1);
  app.use(
    helmet({
      contentSecurityPolicy: false,
      crossOriginEmbedderPolicy: false,
    })
  );
  app.use(
    cors({
      origin: env.FRONTEND_ORIGIN || true,
    })
  );
  app.use(morgan('dev'));
  app.use(express.json({ limit: '8mb' }));

  app.get('/health', (_req, res) => {
    res.json({ ok: true, name: 'GlowCheck API' });
  });

  if (!hasWeb) {
    app.get('/', (_req, res) => {
      res.json({
        name: 'GlowCheck API',
        ok: true,
        health: '/health',
        analyze: 'POST /analyze',
        auth: 'POST /auth/register /auth/login /auth/social',
      });
    });
  }

  app.use('/auth', rateLimit, authRouter);
  app.use('/analyze', rateLimit, analyzeRouter);

  if (hasWeb) {
    app.use(express.static(webRoot));
    app.use((req, res, next) => {
      if (req.method !== 'GET') return next();
      res.sendFile(path.join(webRoot, 'index.html'));
    });
  }

  return app;
}
