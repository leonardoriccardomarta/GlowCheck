import { OAuth2Client } from 'google-auth-library';
import { env } from '../config/env';

let client: OAuth2Client | null = null;

function googleClient() {
  const clientId = env.GOOGLE_CLIENT_ID?.trim();
  if (!clientId) {
    throw new Error('GOOGLE_CLIENT_ID is not set');
  }
  if (!client) client = new OAuth2Client(clientId);
  return { client, clientId };
}

export async function verifyGoogleIdToken(idToken?: string) {
  if (!idToken?.trim()) {
    throw new Error('Google sign-in failed.');
  }
  const { client, clientId } = googleClient();
  const ticket = await client.verifyIdToken({
    idToken: idToken.trim(),
    audience: clientId,
  });
  const payload = ticket.getPayload();
  const email = payload?.email?.trim().toLowerCase();
  if (!payload || !email || payload.email_verified === false) {
    throw new Error('Google sign-in failed.');
  }
  const name = (payload.name || payload.given_name || email.split('@')[0] || 'Google user').trim();
  return { email, name };
}
