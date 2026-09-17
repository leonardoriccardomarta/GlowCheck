const UA =
  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36';

const BAD_PHOTO =
  /skyline|skyscraper|cityscape|nightscape|downtown|architecture|building|tower|hotel|apartment|wikimedia|wikipedia|pexels|unsplash|flickr|gettyimages|shutterstock|city-night|urban|landscape/i;

function blockedHost(host: string) {
  const h = host.toLowerCase().replace(/\[|\]/g, '');
  if (h === 'localhost' || h.endsWith('.localhost') || h === '::1' || h === '0.0.0.0') return true;
  if (/^(127|10|169\.254)\./.test(h)) return true;
  if (/^192\.168\./.test(h)) return true;
  if (/^172\.(1[6-9]|2\d|3[0-1])\./.test(h)) return true;
  return false;
}

export function allowedFarmImage(raw: string) {
  try {
    const parsed = new URL(raw);
    if (parsed.protocol !== 'https:') return false;
    return !blockedHost(parsed.hostname);
  } catch {
    return false;
  }
}

async function timedText(url: string, ms = 4500) {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), ms);
  try {
    const response = await fetch(url, {
      signal: controller.signal,
      headers: { 'User-Agent': UA, Accept: 'text/html,application/json' },
      redirect: 'follow',
    });
    if (!response.ok) return '';
    return await response.text();
  } catch {
    return '';
  } finally {
    clearTimeout(timer);
  }
}

function queryTokens(query: string) {
  return query
    .toLowerCase()
    .replace(/[^a-z0-9\s]/g, ' ')
    .split(/\s+/)
    .filter((token) => token.length > 3 && !['with', 'from', 'this', 'product', 'bottle', 'skincare'].includes(token));
}

function isProductPhoto(url: string, title: string, query: string) {
  const blob = `${url} ${title}`.toLowerCase();
  if (BAD_PHOTO.test(blob)) return false;
  if (!url.startsWith('https://') || /\.svg(\?|$)/i.test(url)) return false;
  if (!allowedFarmImage(url)) return false;
  const tokens = queryTokens(query);
  const hits = tokens.filter((token) => blob.includes(token)).length;
  if (hits >= 1) return true;
  return /openbeautyfacts|openfoodfacts|sephora|ulta|lookfantastic|cultbeauty|notino|douglas|sunscreen|moisturizer|moisturiser|serum|cleanser|toner|spf/.test(
    blob,
  );
}

type HeroHit = { url: string; title: string };

function pickUrls(hits: HeroHit[], query: string) {
  const seen = new Set<string>();
  const out: string[] = [];
  for (const hit of hits) {
    if (!isProductPhoto(hit.url, hit.title, query)) continue;
    const key = hit.url.split('?')[0];
    if (seen.has(key)) continue;
    seen.add(key);
    out.push(hit.url);
  }
  return out;
}

async function duckImages(query: string): Promise<HeroHit[]> {
  const home = await timedText(`https://duckduckgo.com/?q=${encodeURIComponent(query)}&iax=images&ia=images`);
  const vqd = home.match(/vqd=([\d-]+)/)?.[1] || home.match(/vqd='([\d-]+)'/)?.[1];
  if (!vqd) return [];
  const body = await timedText(
    `https://duckduckgo.com/i.js?l=us-en&o=json&q=${encodeURIComponent(query)}&vqd=${encodeURIComponent(vqd)}&f=,,,`,
  );
  try {
    const json = JSON.parse(body) as { results?: { image?: string; title?: string; width?: number; height?: number }[] };
    return (json.results ?? [])
      .filter((row) => (row.width ?? 0) >= 360 && (row.height ?? 0) >= 360)
      .map((row) => ({ url: row.image || '', title: row.title || '' }));
  } catch {
    return [];
  }
}

async function bingImages(query: string): Promise<HeroHit[]> {
  const html = await timedText(
    `https://www.bing.com/images/async?q=${encodeURIComponent(query)}&first=0&count=25&mmasync=1`,
  );
  const found = [
    ...html.matchAll(/murl":"(https:[^"]+)"[\s\S]{0,240}?"t":"([^"]*)"/g),
    ...html.matchAll(/murl&quot;:&quot;(https:[^&]+)&quot;[\s\S]{0,240}?t&quot;:&quot;([^&]*)&quot;/g),
  ];
  return found.map((row) => ({
    url: row[1]
      .replace(/\\u0026/g, '&')
      .replace(/\\u002f/g, '/')
      .replace(/&amp;/g, '&')
      .replace(/\\/g, ''),
    title: row[2].replace(/\\u0026/g, '&').replace(/&amp;/g, '&'),
  }));
}

export async function farmHeroImage(query: string, fallback?: string | null): Promise<string | null> {
  const q = query.replace(/\s+/g, ' ').trim();
  if (q.length < 2) return fallback || null;
  const search = `"${q}" bottle OR sunscreen OR cream OR serum -skyline -city -building`;
  const packs = await Promise.allSettled([bingImages(search), duckImages(`${q} skincare bottle`)]);
  const hits = packs.flatMap((row) => (row.status === 'fulfilled' ? row.value : []));
  const urls = pickUrls(hits, q);
  return urls[0] || fallback || null;
}
