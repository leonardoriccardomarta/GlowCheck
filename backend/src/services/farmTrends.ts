import { env } from '../config/env';

export type TrendPost = {
  caption: string;
  views: number;
  likes: number;
  saves: number;
  saveRate: number;
  likeRate: number;
};

const TAGS = ['skintok', 'poreclogging', 'skincare'];

function asRecord(value: unknown): Record<string, unknown> | null {
  return value && typeof value === 'object' && !Array.isArray(value) ? (value as Record<string, unknown>) : null;
}

function num(value: unknown) {
  const n = Number(value);
  return Number.isFinite(n) && n > 0 ? n : 0;
}

function collectPosts(node: unknown, out: TrendPost[], seen: WeakSet<object>, depth: number) {
  if (!node || depth > 8) return;
  if (typeof node === 'object') {
    if (seen.has(node)) return;
    seen.add(node);
  }
  const row = asRecord(node);
  if (row) {
    const stats = asRecord(row.stats) || asRecord(row.statistics) || row;
    const caption = String(row.desc || row.title || row.text || row.caption || row.video_description || '').trim();
    const views = num(stats.playCount ?? stats.play_count ?? row.playCount ?? row.play_count ?? row.views);
    const likes = num(stats.diggCount ?? stats.digg_count ?? row.diggCount ?? row.likes);
    const saves = num(stats.collectCount ?? stats.collect_count ?? row.collectCount ?? row.saves);
    if (caption.length > 12 && views > 500) {
      out.push({
        caption: caption.slice(0, 420),
        views,
        likes,
        saves,
        saveRate: views ? saves / views : 0,
        likeRate: views ? likes / views : 0,
      });
    }
    for (const value of Object.values(row)) collectPosts(value, out, seen, depth + 1);
  } else if (Array.isArray(node)) {
    for (const item of node) collectPosts(item, out, seen, depth + 1);
  }
}

function rank(posts: TrendPost[]) {
  const uniq = new Map<string, TrendPost>();
  for (const post of posts) {
    const key = post.caption.slice(0, 80).toLowerCase();
    const prev = uniq.get(key);
    if (!prev || post.views > prev.views) uniq.set(key, post);
  }
  return [...uniq.values()]
    .sort((a, b) => b.saveRate - a.saveRate || b.views - a.views)
    .slice(0, 20);
}

async function rapidHashtag(tag: string) {
  const key = env.RAPIDAPI_KEY?.trim();
  const host = env.RAPIDAPI_TIKTOK_HOST?.trim() || 'tiktok-scraper7.p.rapidapi.com';
  if (!key) return [] as TrendPost[];
  const urls = [
    `https://${host}/challenge/posts?name=${encodeURIComponent(tag)}&count=20`,
    `https://${host}/hashtag/posts?name=${encodeURIComponent(tag)}&count=20`,
    `https://${host}/api/search/hashtag?keywords=${encodeURIComponent(tag)}`,
  ];
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), 9000);
  try {
    for (const url of urls) {
      const response = await fetch(url, {
        signal: controller.signal,
        headers: {
          'X-RapidAPI-Key': key,
          'X-RapidAPI-Host': host,
        },
      });
      if (!response.ok) continue;
      const json: unknown = await response.json();
      const found: TrendPost[] = [];
      collectPosts(json, found, new WeakSet(), 0);
      if (found.length) return found;
    }
  } catch {
    return [];
  } finally {
    clearTimeout(timer);
  }
  return [];
}

async function apifyHashtags() {
  const token = env.APIFY_TOKEN?.trim();
  if (!token) return [] as TrendPost[];
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), 20000);
  try {
    const response = await fetch(
      `https://api.apify.com/v2/acts/clockworks~tiktok-hashtag-scraper/run-sync-get-dataset-items?token=${encodeURIComponent(token)}&timeout=18`,
      {
        method: 'POST',
        signal: controller.signal,
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ hashtags: TAGS, resultsPerPage: 12 }),
      },
    );
    if (!response.ok) return [];
    const json: unknown = await response.json();
    const found: TrendPost[] = [];
    collectPosts(json, found, new WeakSet(), 0);
    return found;
  } catch {
    return [];
  } finally {
    clearTimeout(timer);
  }
}

export async function farmTrendPosts() {
  const rapid = (await Promise.all(TAGS.map(rapidHashtag))).flat();
  if (rapid.length) return { source: 'rapidapi' as const, posts: rank(rapid) };
  const apify = await apifyHashtags();
  if (apify.length) return { source: 'apify' as const, posts: rank(apify) };
  return { source: 'none' as const, posts: [] as TrendPost[] };
}
