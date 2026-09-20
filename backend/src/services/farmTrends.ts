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
  if (typeof value === 'string') {
    const raw = value.trim().toLowerCase().replace(/,/g, '');
    const match = raw.match(/^([\d.]+)\s*([kmb])?$/);
    if (match) {
      const n = Number(match[1]);
      const mul = match[2] === 'k' ? 1e3 : match[2] === 'm' ? 1e6 : match[2] === 'b' ? 1e9 : 1;
      return Number.isFinite(n) && n > 0 ? n * mul : 0;
    }
  }
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
    const caption = String(
      row.desc || row.title || row.text || row.caption || row.video_description || row.content || '',
    ).trim();
    const views = num(stats.playCount ?? stats.play_count ?? row.playCount ?? row.play_count ?? row.views ?? row.play);
    const likes = num(stats.diggCount ?? stats.digg_count ?? row.diggCount ?? row.likes ?? row.digg);
    const saves = num(stats.collectCount ?? stats.collect_count ?? row.collectCount ?? row.saves ?? row.collect);
    if (caption.length > 8) {
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

function challengeIdOf(node: unknown, seen: WeakSet<object>, depth: number): string | null {
  if (!node || depth > 6) return null;
  if (typeof node === 'object') {
    if (seen.has(node)) return null;
    seen.add(node);
  }
  const row = asRecord(node);
  if (row) {
    const direct = row.challenge_id ?? row.challengeId ?? row.ch_id ?? row.cid;
    if (direct && String(direct).length > 2) return String(direct);
    const challenge = asRecord(row.challenge) || asRecord(row.challengeInfo);
    const nested = challenge?.id ?? challenge?.cid ?? asRecord(challenge?.challenge)?.id;
    if (nested && String(nested).length > 2) return String(nested);
    for (const value of Object.values(row)) {
      const found = challengeIdOf(value, seen, depth + 1);
      if (found) return found;
    }
  } else if (Array.isArray(node)) {
    for (const item of node) {
      const found = challengeIdOf(item, seen, depth + 1);
      if (found) return found;
    }
  }
  return null;
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

async function rapidGet(url: string, key: string, host: string, signal: AbortSignal) {
  const response = await fetch(url, {
    signal,
    headers: {
      'X-RapidAPI-Key': key,
      'X-RapidAPI-Host': host,
    },
  });
  if (!response.ok) return { status: response.status, json: null as unknown };
  return { status: response.status, json: await response.json() };
}

async function rapidHashtag(tag: string) {
  const key = env.RAPIDAPI_KEY?.trim();
  const host = env.RAPIDAPI_TIKTOK_HOST?.trim() || 'tiktok-scraper7.p.rapidapi.com';
  if (!key) return { posts: [] as TrendPost[], status: 0 };
  const q = encodeURIComponent(tag);
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), 12000);
  let lastStatus = 0;
  try {
    const firstPass = [
      `https://${host}/feed/search?keywords=${q}&count=20&cursor=0`,
      `https://${host}/search/video?keywords=${q}&count=20&cursor=0`,
      `https://${host}/challenge/info?challenge_name=${q}`,
      `https://${host}/challenge/search?keywords=${q}&count=10`,
      `https://${host}/challenge/posts?name=${q}&count=20`,
      `https://${host}/hashtag/posts?name=${q}&count=20`,
    ];
    for (const url of firstPass) {
      const { status, json } = await rapidGet(url, key, host, controller.signal);
      lastStatus = status || lastStatus;
      if (!json) continue;
      const found: TrendPost[] = [];
      collectPosts(json, found, new WeakSet(), 0);
      if (found.length) return { posts: found, status };
      const challengeId = challengeIdOf(json, new WeakSet(), 0);
      if (challengeId) {
        const postsUrl = `https://${host}/challenge/posts?challenge_id=${encodeURIComponent(challengeId)}&count=20&cursor=0`;
        const nested = await rapidGet(postsUrl, key, host, controller.signal);
        lastStatus = nested.status || lastStatus;
        const nestedFound: TrendPost[] = [];
        collectPosts(nested.json, nestedFound, new WeakSet(), 0);
        if (nestedFound.length) return { posts: nestedFound, status: nested.status };
      }
    }
  } catch {
    return { posts: [] as TrendPost[], status: lastStatus };
  } finally {
    clearTimeout(timer);
  }
  return { posts: [] as TrendPost[], status: lastStatus };
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
  const configured = Boolean(env.RAPIDAPI_KEY?.trim() || env.APIFY_TOKEN?.trim());
  const rapid = await Promise.all(TAGS.map(rapidHashtag));
  const rapidPosts = rapid.flatMap((row) => row.posts);
  const rapidStatus = rapid.reduce((max, row) => Math.max(max, row.status), 0);
  if (rapidPosts.length) return { source: 'rapidapi' as const, posts: rank(rapidPosts), configured, status: rapidStatus };
  const apify = await apifyHashtags();
  if (apify.length) return { source: 'apify' as const, posts: rank(apify), configured, status: 200 };
  return { source: 'none' as const, posts: [] as TrendPost[], configured, status: rapidStatus };
}
