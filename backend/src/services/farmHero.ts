const UA =
  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36';

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

function pickUrls(raw: string[]) {
  const seen = new Set<string>();
  const out: string[] = [];
  for (const item of raw) {
    if (!item || !item.startsWith('https://')) continue;
    if (/\.svg(\?|$)/i.test(item)) continue;
    if (!allowedFarmImage(item)) continue;
    const key = item.split('?')[0];
    if (seen.has(key)) continue;
    seen.add(key);
    out.push(item);
  }
  return out;
}

async function duckImages(query: string) {
  const home = await timedText(`https://duckduckgo.com/?q=${encodeURIComponent(query)}&iax=images&ia=images`);
  const vqd = home.match(/vqd=([\d-]+)/)?.[1] || home.match(/vqd='([\d-]+)'/)?.[1];
  if (!vqd) return [];
  const body = await timedText(
    `https://duckduckgo.com/i.js?l=us-en&o=json&q=${encodeURIComponent(query)}&vqd=${encodeURIComponent(vqd)}&f=,,,`,
  );
  try {
    const json = JSON.parse(body) as { results?: { image?: string; width?: number; height?: number }[] };
    return (json.results ?? [])
      .filter((row) => (row.width ?? 0) >= 360 && (row.height ?? 0) >= 360)
      .map((row) => row.image || '');
  } catch {
    return [];
  }
}

async function bingImages(query: string) {
  const html = await timedText(
    `https://www.bing.com/images/async?q=${encodeURIComponent(query)}&first=0&count=20&mmasync=1`,
  );
  const found = [...html.matchAll(/murl&quot;:&quot;(https:[^&]+)&quot;/g), ...html.matchAll(/murl":"(https:[^"]+)"/g)];
  return found.map((row) =>
    row[1]
      .replace(/\\u0026/g, '&')
      .replace(/\\u002f/g, '/')
      .replace(/&amp;/g, '&')
      .replace(/\\/g, ''),
  );
}

async function openverseImages(query: string) {
  const body = await timedText(
    `https://api.openverse.org/v1/images/?q=${encodeURIComponent(query)}&page_size=8&mature=false`,
  );
  try {
    const json = JSON.parse(body) as { results?: { url?: string; width?: number; height?: number }[] };
    return (json.results ?? [])
      .filter((row) => (row.width ?? 0) >= 360)
      .map((row) => row.url || '');
  } catch {
    return [];
  }
}

async function wikiImages(query: string) {
  const body = await timedText(
    'https://commons.wikimedia.org/w/api.php?action=query&format=json&origin=*' +
      '&generator=search&gsrnamespace=6&gsrlimit=8' +
      `&gsrsearch=${encodeURIComponent(query)}` +
      '&prop=imageinfo&iiprop=url|size&iiurlwidth=1600',
  );
  try {
    const json = JSON.parse(body) as {
      query?: { pages?: Record<string, { imageinfo?: { url?: string; thumburl?: string; width?: number }[] }> };
    };
    return Object.values(json.query?.pages ?? {}).flatMap((page) => {
      const info = page.imageinfo?.[0];
      if (!info || (info.width ?? 0) < 360) return [];
      return [info.thumburl || info.url || ''];
    });
  } catch {
    return [];
  }
}

export async function farmHeroImage(query: string): Promise<string | null> {
  const q = query.replace(/\s+/g, ' ').trim();
  if (q.length < 2) return null;
  const searches = [`${q} skincare product`, `${q} bottle`, q];
  const first = searches[0];
  const packs = await Promise.allSettled([
    bingImages(first),
    duckImages(first),
    wikiImages(q),
    openverseImages(q),
  ]);
  const urls = pickUrls(packs.flatMap((row) => (row.status === 'fulfilled' ? row.value : [])));
  return urls[0] || null;
}
