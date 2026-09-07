import { createApp } from './app';
import { env } from './config/env';

const app = createApp();

app.listen(Number(env.PORT), () => {
  console.log(`GlowCheck API running on port ${env.PORT}`);
});
