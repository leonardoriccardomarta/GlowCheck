import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import fs from 'fs';
import path from 'path';
import { analyzeRouter } from './routes/analyze';
import { authRouter } from './routes/auth';
import { billingRouter } from './routes/billing';
import { shelfRouter } from './routes/shelf';
import { adminRouter } from './routes/admin';
import { stripeWebhook } from './routes/stripeWebhook';
import { rateLimit } from './middleware/rateLimit';
import { env } from './config/env';
import { allowedReturnUrl } from './services/stripeBilling';

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
      crossOriginResourcePolicy: { policy: 'cross-origin' },
    })
  );
  app.use(
    cors({
      origin(origin, callback) {
        if (!origin) return callback(null, true);
        if (allowedReturnUrl(origin)) return callback(null, origin);
        return callback(null, false);
      },
      credentials: true,
      allowedHeaders: ['Content-Type', 'Authorization'],
    })
  );
  app.use(morgan('dev'));
  app.post('/billing/webhook', express.raw({ type: 'application/json' }), stripeWebhook);
  app.use(express.json({ limit: '8mb' }));

  const info = {
    name: 'GlowCheck API',
    ok: true,
    health: '/health',
    analyze: 'POST /analyze',
    auth: 'POST /auth/register /auth/login /auth/social',
    shelf: 'GET|POST /shelf',
    billing: 'GET /billing/ready POST /billing/checkout POST /billing/confirm',
    admin: 'GET /admin  POST /admin/login  POST /admin/farm/lookup  POST /admin/farm/build',
  };

  app.get('/health', (_req, res) => {
    res.json({ ok: true, name: 'GlowCheck API' });
  });

  app.get('/', (_req, res) => {
    res.json(info);
  });

  app.use('/auth', rateLimit, authRouter);
  app.use('/analyze', rateLimit, analyzeRouter);
  app.use('/shelf', rateLimit, shelfRouter);
  app.use('/billing', rateLimit, billingRouter);
  app.get('/admin', (_req, res) => {
    res.setHeader('Cache-Control', 'no-store');
    res.sendFile(path.join(webRoot, 'admin', 'index.html'));
  });
  app.use('/admin', rateLimit, adminRouter);
  app.use('/admin', express.static(path.join(webRoot, 'admin'), { index: false, maxAge: '1h' }));

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
