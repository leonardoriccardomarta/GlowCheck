import Stripe from 'stripe';
import { Router } from 'express';
import { z } from 'zod';
import { issueSession, markPro } from '../services/auth';
import {
  LIFETIME_AMOUNT,
  LIFETIME_CURRENCY,
  LIFETIME_PLAN,
  allowedReturnUrl,
  sessionPaid,
  stripeClient,
  stripeEnabled,
} from '../services/stripeBilling';

export const billingRouter = Router();

function checkoutLocale(locale?: string): Stripe.Checkout.SessionCreateParams.Locale {
  if (locale === 'it' || locale === 'en' || locale === 'es' || locale === 'fr' || locale === 'de') {
    return locale;
  }
  return 'auto';
}

const checkoutSchema = z.object({
  successUrl: z.string().url().max(500),
  cancelUrl: z.string().url().max(500),
  email: z.string().email().max(120).optional(),
  locale: z.string().max(8).optional(),
});

const confirmSchema = z.object({
  sessionId: z.string().min(8).max(200),
});

billingRouter.get('/ready', (_req, res) => {
  res.json({
    ok: true,
    stripe: stripeEnabled(),
    amount: LIFETIME_AMOUNT,
    currency: LIFETIME_CURRENCY,
    plan: LIFETIME_PLAN,
  });
});

billingRouter.post('/checkout', async (req, res) => {
  if (!stripeEnabled()) {
    return res.status(503).json({ ok: false, error: 'STRIPE_NOT_CONFIGURED' });
  }
  const parsed = checkoutSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ ok: false, error: 'INVALID_CHECKOUT' });
  }
  const { successUrl, cancelUrl, email, locale } = parsed.data;
  if (!allowedReturnUrl(successUrl) || !allowedReturnUrl(cancelUrl)) {
    return res.status(400).json({ ok: false, error: 'INVALID_RETURN_URL' });
  }
  if (!successUrl.includes('{CHECKOUT_SESSION_ID}')) {
    return res.status(400).json({ ok: false, error: 'MISSING_SESSION_PLACEHOLDER' });
  }

  const stripe = stripeClient();
  if (!stripe) {
    return res.status(503).json({ ok: false, error: 'STRIPE_NOT_CONFIGURED' });
  }

  try {
    const session = await stripe.checkout.sessions.create({
      mode: 'payment',
      success_url: successUrl,
      cancel_url: cancelUrl,
      customer_email: email || undefined,
      locale: checkoutLocale(locale),
      submit_type: 'pay',
      allow_promotion_codes: true,
      metadata: { plan: LIFETIME_PLAN },
      line_items: [
        {
          quantity: 1,
          price_data: {
            currency: LIFETIME_CURRENCY,
            unit_amount: LIFETIME_AMOUNT,
            product_data: {
              name: 'GlowCheck Accesso a vita',
              description: 'Scansioni illimitate. Una tantum. Nessun abbonamento.',
            },
          },
        },
      ],
    });
    if (!session.url) {
      return res.status(502).json({ ok: false, error: 'NO_CHECKOUT_URL' });
    }
    return res.json({ ok: true, url: session.url, sessionId: session.id });
  } catch (error) {
    console.error(error);
    return res.status(502).json({ ok: false, error: 'CHECKOUT_FAILED' });
  }
});

billingRouter.post('/confirm', async (req, res) => {
  if (!stripeEnabled()) {
    return res.status(503).json({ ok: false, error: 'STRIPE_NOT_CONFIGURED' });
  }
  const parsed = confirmSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ ok: false, error: 'INVALID_SESSION' });
  }
  const stripe = stripeClient();
  if (!stripe) {
    return res.status(503).json({ ok: false, error: 'STRIPE_NOT_CONFIGURED' });
  }
  try {
    const session = await stripe.checkout.sessions.retrieve(parsed.data.sessionId);
    const unlocked = sessionPaid(session);
    const email = session.customer_details?.email || session.customer_email || null;
    if (unlocked && email) await markPro(email);
    const issued = unlocked && email ? await issueSession(email) : null;
    return res.json({
      ok: true,
      unlocked,
      plan: unlocked ? LIFETIME_PLAN : null,
      email: unlocked ? email : null,
      token: issued?.token ?? null,
      isPro: unlocked,
    });
  } catch (error) {
    console.error(error);
    return res.status(404).json({ ok: false, error: 'SESSION_NOT_FOUND' });
  }
});
