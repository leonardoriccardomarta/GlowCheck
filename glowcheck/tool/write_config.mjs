import { writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = dirname(fileURLToPath(import.meta.url));
const out = join(root, '..', 'build', 'web', 'config.json');
const apiUrl = (process.env.API_URL || '').trim();

writeFileSync(
  out,
  `${JSON.stringify(
    {
      apiUrl,
      authApiUrl: (process.env.AUTH_API_URL || apiUrl).trim(),
      googleClientId: (process.env.GOOGLE_CLIENT_ID || '').trim(),
      appleServiceId: (process.env.APPLE_SERVICE_ID || '').trim(),
      revenueCatApiKey: (process.env.REVENUECAT_API_KEY || '').trim(),
      stripeCheckoutUrl: (process.env.STRIPE_CHECKOUT_URL || '').trim(),
    },
    null,
    2
  )}\n`
);
console.log(`Wrote ${out} apiUrl=${apiUrl || '(empty)'}`);
