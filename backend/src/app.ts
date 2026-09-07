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
  const onVercel = Boolean(process.env.VERCEL);
  const webRoot = publicDir();
  const hasWeb = !onVercel && fs.existsSync(path.join(webRoot, 'index.html'));

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

  const info = {
    name: 'GlowCheck API',
    ok: true,
    health: '/health',
    analyze: 'POST /analyze',
    auth: 'POST /auth/register /auth/login /auth/social',
  };

  app.get('/health', (_req, res) => {
    res.json({ ok: true, name: 'GlowCheck API' });
  });

  app.get('/', (_req, res) => {
    res.json(info);
  });

  app.use('/auth', rateLimit, authRouter);
  app.use('/analyze', rateLimit, analyzeRouter);

  if (hasWeb) {
    app.use(express.static(webRoot));
    app.use((req, res, next) => {
      if (req.method !== 'GET') return next();
      const index = path.join(webRoot, 'index.html');
      if (!fs.existsSync(index)) return next();
      res.sendFile(index);
    });
  }

  app.use((req, res) => {
    res.status(404).json({ ok: false, error: 'Not found', path: req.path });
  });

  app.use((err: unknown, _req: express.Request, res: express.Response, _next: express.NextFunction) => {
    console.error(err);
    res.status(500).json({ ok: false, error: 'Internal server error' });
  });

  return app;
}
