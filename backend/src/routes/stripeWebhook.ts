import type { Request, Response } from 'express';
import { env } from '../config/env';
import { markPro } from '../services/auth';
import { sessionPaid, stripeClient } from '../services/stripeBilling';

export async function stripeWebhook(req: Request, res: Response) {
  const stripe = stripeClient();
  const secret = env.STRIPE_WEBHOOK_SECRET?.trim();
  if (!stripe || !secret) {
    return res.status(503).send('Stripe webhook not configured');
  }
  const signature = req.headers['stripe-signature'];
  if (typeof signature !== 'string') {
    return res.status(400).send('Missing stripe-signature');
  }
  const raw = Buffer.isBuffer(req.body)
    ? req.body
    : typeof req.body === 'string'
      ? Buffer.from(req.body)
      : Buffer.from(JSON.stringify(req.body ?? {}));

  try {
    const event = stripe.webhooks.constructEvent(raw, signature, secret);
    if (event.type === 'checkout.session.completed') {
      const session = event.data.object;
      if (sessionPaid(session)) {
        const email = session.customer_details?.email || session.customer_email;
        if (email) markPro(email);
        console.log('stripe lifetime paid', session.id);
      }
    }
    return res.json({ received: true });
  } catch (error) {
    console.error(error);
    return res.status(400).send('Invalid webhook signature');
  }
}
