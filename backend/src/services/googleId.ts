import { OAuth2Client } from 'google-auth-library';
import { env } from '../config/env';

let client: OAuth2Client | null = null;

function googleClientId() {
  const clientId = env.GOOGLE_CLIENT_ID?.trim();
  if (!clientId) {
    throw new Error('GOOGLE_CLIENT_ID is not set');
  }
  return clientId;
}

function googleClient() {
  const clientId = googleClientId();
  if (!client) client = new OAuth2Client(clientId);
  return { client, clientId };
}

function profileFromPayload(email: string, name?: string, given?: string) {
  return {
    email,
    name: (name || given || email.split('@')[0] || 'Google user').trim(),
  };
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
  return profileFromPayload(email, payload.name, payload.given_name);
}

async function verifyGoogleAccessToken(accessToken?: string) {
  if (!accessToken?.trim()) {
    throw new Error('Google sign-in failed.');
  }
  const clientId = googleClientId();
  const infoRes = await fetch(
    `https://oauth2.googleapis.com/tokeninfo?access_token=${encodeURIComponent(accessToken.trim())}`
  );
  if (!infoRes.ok) {
    throw new Error('Google sign-in failed.');
  }
  const info = (await infoRes.json()) as { aud?: string; azp?: string };
  if (info.aud !== clientId && info.azp !== clientId) {
    throw new Error('Google sign-in failed.');
  }
  const profileRes = await fetch('https://www.googleapis.com/oauth2/v3/userinfo', {
    headers: { Authorization: `Bearer ${accessToken.trim()}` },
  });
  if (!profileRes.ok) {
    throw new Error('Google sign-in failed.');
  }
  const profile = (await profileRes.json()) as {
    email?: string;
    email_verified?: boolean | string;
    name?: string;
    given_name?: string;
  };
  const email = profile.email?.trim().toLowerCase();
  if (!email || profile.email_verified === false || profile.email_verified === 'false') {
    throw new Error('Google sign-in failed.');
  }
  return profileFromPayload(email, profile.name, profile.given_name);
}

export async function verifyGoogleSignIn(input: { idToken?: string; accessToken?: string }) {
  if (input.idToken?.trim()) {
    return verifyGoogleIdToken(input.idToken);
  }
  return verifyGoogleAccessToken(input.accessToken);
}
