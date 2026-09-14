import Stripe from 'stripe';
import { env } from '../config/env';

export const LIFETIME_AMOUNT = 999;
export const LIFETIME_CURRENCY = 'eur';
export const LIFETIME_PLAN = 'lifetime';

let client: Stripe | null = null;

export function stripeEnabled() {
  return Boolean(env.STRIPE_SECRET_KEY?.trim());
}

export function stripeClient() {
  const key = env.STRIPE_SECRET_KEY?.trim();
  if (!key) return null;
  if (!client) {
    client = new Stripe(key);
  }
  return client;
}

export function allowedReturnUrl(raw: string) {
  let parsed: URL;
  try {
    parsed = new URL(raw);
  } catch {
    return false;
  }
  if (parsed.protocol !== 'http:' && parsed.protocol !== 'https:') return false;
  if (parsed.hostname === 'localhost' || parsed.hostname === '127.0.0.1') return true;
  if (env.FRONTEND_ORIGIN) {
    try {
      if (parsed.origin === new URL(env.FRONTEND_ORIGIN).origin) return true;
    } catch {
      /* ignore */
    }
  }
  if (parsed.protocol === 'https:' && /glow-?check/i.test(parsed.hostname) && parsed.hostname.endsWith('.vercel.app')) {
    return true;
  }
  return false;
}

export function sessionPaid(session: Stripe.Checkout.Session) {
  if (session.metadata?.plan !== LIFETIME_PLAN) return false;
  if (session.mode && session.mode !== 'payment') return false;
  if (session.payment_status !== 'paid') return false;
  if (session.currency && session.currency !== LIFETIME_CURRENCY) return false;
  if (session.amount_total != null && session.amount_total < LIFETIME_AMOUNT) return false;
  return true;
}
