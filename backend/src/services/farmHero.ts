const UA =
  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36';

const BAD_PHOTO =
  /skyline|skyscraper|cityscape|nightscape|downtown|architecture|building|tower|hotel|apartment|wikimedia|wikipedia|pexels|unsplash|flickr|gettyimages|shutterstock|city-night|urban|landscape|screenshot|meme/i;

const AD_PHOTO =
  /banner|campaign|collage|infographic|promo|advert|coupon|og-image|facebook|instagram|social-share|before-after|comparison|4x|reparac|mais\s|%off|percent.off|testimonial|key.?visual|billboard|claim|eficac|effetiv|effettiv|clinically.proven|vs\.|versus|beforeafter|advertorial|magazine-ad|print-ad|social.?ad/i;

const STUDIO_HOST =
  /sephora|ulta|lookfantastic|cultbeauty|notino|douglas|perfumesclub|perfume'?s.?club|laroche-posay|loreal|nocibe|marionnaud|boots\.com|superdrug|spacenk|bluemercury|dermstore|skinstore|feelunique|cocooncenter|atida|docmorris|shopify|cloudinary|scene7|demandware|sfcc|woocommerce/i;

const CATALOG_HOST = /openbeautyfacts|openfoodfacts/i;
const SKIP_HOST = /encrypted-tbn|gstatic\.com|google\.com\/|googleusercontent\.com\/proxy/i;

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
    if (SKIP_HOST.test(parsed.hostname + parsed.pathname)) return false;
    return !blockedHost(parsed.hostname);
  } catch {
    return false;
  }
}

async function timedText(url: string, ms = 6500) {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), ms);
  try {
    const response = await fetch(url, {
      signal: controller.signal,
      headers: {
        'User-Agent': UA,
        Accept: 'text/html,application/json',
        'Accept-Language': 'en-US,en;q=0.9,it;q=0.8',
      },
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

function decodeUrl(raw: string) {
  return raw
    .replace(/\\u0026/g, '&')
    .replace(/\\u002f/g, '/')
    .replace(/\\u003d/g, '=')
    .replace(/\\u0025/g, '%')
    .replace(/&amp;/g, '&')
    .replace(/\\\//g, '/')
    .replace(/\\/g, '');
}

type HeroHit = { url: string; title: string; width: number; height: number };

function queryTokens(query: string) {
  return query
    .toLowerCase()
    .replace(/[^a-z0-9\s]/g, ' ')
    .split(/\s+/)
    .filter((token) => token.length > 3 && !['with', 'from', 'this', 'product', 'bottle', 'skincare', 'cream'].includes(token));
}

function searchQueries(query: string) {
  const q = query.replace(/\s+/g, ' ').trim();
  const words = q.split(' ');
  const short = words.slice(0, Math.min(5, words.length)).join(' ');
  return [...new Set([`${short} product white background`, `${short} packshot`, short, q])];
}

function scoreHit(hit: HeroHit, query: string) {
  const blob = `${hit.url} ${hit.title}`.toLowerCase();
  if (BAD_PHOTO.test(blob) || AD_PHOTO.test(blob) || !hit.url.startsWith('https://') || /\.svg(\?|$)/i.test(hit.url)) {
    return -999;
  }
  if (!allowedFarmImage(hit.url)) return -999;
  let n = 0;
  const w = hit.width || 800;
  const h = hit.height || 800;
  n += Math.min((w * h) / 80000, 55);
  const aspect = w / h;
  if (aspect > 1.5) n -= 45;
  if (aspect >= 0.55 && aspect <= 1.2) n += 28;
  if (STUDIO_HOST.test(blob)) n += 55;
  if (CATALOG_HOST.test(blob)) n -= 90;
  if (/packshot|pack-shot|white-bg|on white|product-image|studio|demandware|scene7/.test(blob)) n += 18;
  const tokens = queryTokens(query);
  n += tokens.filter((token) => blob.includes(token)).length * 10;
  if (tokens.length && !tokens.some((token) => blob.includes(token))) n -= 15;
  return n;
}

function pickBest(hits: HeroHit[], query: string, fallback?: string | null) {
  const seen = new Set<string>();
  const ranked: { hit: HeroHit; score: number }[] = [];
  for (const hit of hits) {
    const key = hit.url.split('?')[0];
    if (!key || seen.has(key)) continue;
    const score = scoreHit(hit, query);
    if (score <= 0) continue;
    seen.add(key);
    ranked.push({ hit, score });
  }
  ranked.sort((a, b) => {
    const aspect = (h: HeroHit) => (h.width || 800) / (h.height || 800);
    const pack = (h: HeroHit) => {
      const a = aspect(h);
      return a >= 0.55 && a <= 1.22 ? 30 : a > 1.45 ? -40 : 0;
    };
    return b.score + pack(b.hit) - (a.score + pack(a.hit));
  });
  const urls = ranked
    .filter((row) => {
      const a = (row.hit.width || 800) / (row.hit.height || 800);
      return a <= 1.45;
    })
    .map((row) => row.hit.url);
  if (fallback && !urls.includes(fallback)) urls.push(fallback);
  return urls;
}

async function googleImages(query: string): Promise<HeroHit[]> {
  const html = await timedText(
    `https://www.google.com/search?tbm=isch&udm=2&hl=en&gl=us&safe=active&tbs=isz:l,itp:photo,iar:s&q=${encodeURIComponent(query)}`,
  );
  if (!html) return [];
  const hits: HeroHit[] = [];
  const fromOu = [...html.matchAll(/"ou":"(https:[^"]+)"/g)];
  const fromOw = [...html.matchAll(/"ou":"(https:[^"]+)"[\s\S]{0,180}?"ow":(\d+)[\s\S]{0,40}?"oh":(\d+)/g)];
  const fromTriple = [...html.matchAll(/\["(https:\/\/[^"]+\.(?:jpe?g|png|webp)[^"]*)",\s*(\d{3,5}),\s*(\d{3,5})\]/gi)];
  for (const row of fromOw) {
    hits.push({ url: decodeUrl(row[1]), title: query, width: Number(row[2]) || 0, height: Number(row[3]) || 0 });
  }
  for (const row of fromTriple) {
    hits.push({
      url: decodeUrl(row[1]),
      title: query,
      width: Number(row[2]) || 0,
      height: Number(row[3]) || 0,
    });
  }
  if (!hits.length) {
    for (const row of fromOu) hits.push({ url: decodeUrl(row[1]), title: query, width: 1200, height: 1200 });
  }
  return hits.filter((hit) => (hit.width || 1200) >= 400);
}

async function bingImages(query: string): Promise<HeroHit[]> {
  const html = await timedText(
    `https://www.bing.com/images/async?q=${encodeURIComponent(query)}&first=0&count=35&mmasync=1&qft=+filterui:photo-photo+filterui:imagesize-large`,
  );
  const found = [
    ...html.matchAll(/murl":"(https:[^"]+)"[\s\S]{0,280}?"t":"([^"]*)"/g),
    ...html.matchAll(/murl&quot;:&quot;(https:[^&]+)&quot;[\s\S]{0,280}?t&quot;:&quot;([^&]*)&quot;/g),
  ];
  return found.map((row) => ({
    url: decodeUrl(row[1]),
    title: decodeUrl(row[2] || query),
    width: 1200,
    height: 1200,
  }));
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
      .filter((row) => (row.width ?? 0) >= 400 && (row.height ?? 0) >= 400)
      .map((row) => ({
        url: row.image || '',
        title: row.title || query,
        width: row.width || 0,
        height: row.height || 0,
      }));
  } catch {
    return [];
  }
}

export async function farmHeroImage(
  query: string,
  fallback?: string | null,
): Promise<{ url: string | null; urls: string[] }> {
  const q = query.replace(/\s+/g, ' ').trim();
  if (q.length < 2) return { url: fallback || null, urls: fallback ? [fallback] : [] };
  const queries = searchQueries(q);
  const jobs: Promise<HeroHit[]>[] = [];
  for (const term of queries.slice(0, 3)) {
    jobs.push(googleImages(term), bingImages(term), duckImages(term));
  }
  const packs = await Promise.allSettled(jobs);
  const hits = packs.flatMap((row) => (row.status === 'fulfilled' ? row.value : []));
  const urls = pickBest(hits, q, fallback);
  return { url: urls[0] || fallback || null, urls };
}
