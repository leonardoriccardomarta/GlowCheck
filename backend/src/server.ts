import { env } from './config/env';
import app from './index';

if (!process.env.VERCEL) {
  app.listen(Number(env.PORT), () => {
    console.log(`GlowCheck API running on port ${env.PORT}`);
  });
}
