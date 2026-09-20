import { env } from '../config/env';
import { extractVisionJson } from './visionJson';
import type { ReadyFarmIdea } from './farmUsed';
import type { TrendPost } from './farmTrends';

export type FarmFormat = 'DEEP_DIVE' | 'TIER_LIST_SWIPE' | 'RED_FLAG_INCI';

export type FarmBlueprint = {
  trending_topic: string;
  recommended_format: FarmFormat;
  hook_text: string;
  items: string[];
  queries: string[];
  slides_blueprint: { slide: number; type: string; verdict?: string; text?: string; items?: string[] }[];
};

function formatOf(value: string): FarmFormat {
  if (value === 'TIER_LIST_SWIPE' || value === 'RED_FLAG_INCI') return value;
  return 'DEEP_DIVE';
}

export function heuristicBlueprint(ideas: ReadyFarmIdea[]): FarmBlueprint {
  const top = ideas.slice(0, 3);
  const items = top.map((idea) => idea.label);
  const queries = top.map((idea) => idea.query);
  const one = top[0];
  return {
    trending_topic: one?.angle || 'Skintok INCI check',
    recommended_format: 'DEEP_DIVE',
    hook_text: one
      ? `Why your skin is still breaking out using ${one.label} 🚩`
      : 'Stop using this if you have clogged pores 🛑',
    items: items.length ? items.slice(0, 1) : ['CeraVe'],
    queries: queries.length ? queries.slice(0, 1) : ['CeraVe PM'],
    slides_blueprint: [
      { slide: 1, type: 'hook_comparison' },
      { slide: 2, type: 'score_worst' },
      { slide: 3, type: 'score_best' },
      { slide: 4, type: 'cta' },
    ],
  };
}

export async function farmDirector(posts: TrendPost[], ideas: ReadyFarmIdea[]): Promise<FarmBlueprint> {
  const fallback = heuristicBlueprint(ideas);
  const key = env.GROQ_API_KEY?.trim();
  if (!key) return fallback;
  const catalog = ideas
    .slice(0, 12)
    .map((idea) => `${idea.label} | query=${idea.query}`)
    .join('\n');
  const feed = posts
    .slice(0, 12)
    .map(
      (post, i) =>
        `${i + 1}. views=${post.views} likes=${post.likes} saves=${post.saves} saveRate=${post.saveRate.toFixed(4)} | ${post.caption.replace(/\s+/g, ' ').slice(0, 220)}`,
    )
    .join('\n');
  const system =
    'You are a Skintok trend director for GlowCheck. JSON only, no markdown. Pick unused catalog products that match the viral posts. Default format is DEEP_DIVE (one bottle, Dry vs Oily). Do not write TikTok titles or captions.';
  const user = `Live TikTok posts ranked by save rate (may be empty if no scraper key):
${feed || '(no live posts — pick the catalog item that best matches current Skintok demand: clogged pores, CeraVe, LRP, SPF, BHA)'}

Unused GlowCheck catalog with INCI:
${catalog || '(empty)'}

Return JSON:
{"trending_topic":"","recommended_format":"DEEP_DIVE","hook_text":"","items":[""],"queries":[""],"slides_blueprint":[{"slide":1,"type":"hook_comparison"},{"slide":2,"type":"score_worst"},{"slide":3,"type":"score_best"},{"slide":4,"type":"cta"}]}
Rules:
- queries must be searchable product names from the catalog
- Default DEEP_DIVE: one viral bottle, existing GlowCheck cover
- TIER_LIST_SWIPE only if posts compare 3 named products; then 3 queries
- RED_FLAG_INCI only for one product with fragrance or pore-clogger drama
- hook_text is internal, under 12 words, pain or contrast, no "I scanned"`;

  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), 12000);
  try {
    const response = await fetch('https://api.groq.com/openai/v1/chat/completions', {
      method: 'POST',
      signal: controller.signal,
      headers: {
        Authorization: `Bearer ${key}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: env.DUPE_MODEL,
        temperature: 0.3,
        max_completion_tokens: 500,
        messages: [
          { role: 'system', content: system },
          { role: 'user', content: user },
        ],
      }),
    });
    if (!response.ok) return fallback;
    const json = (await response.json()) as { choices?: { message?: { content?: string } }[] };
    const raw = extractVisionJson(json.choices?.[0]?.message?.content ?? '');
    if (!raw) return fallback;
    const parsed = JSON.parse(raw) as Partial<FarmBlueprint>;
    const items = Array.isArray(parsed.items) ? parsed.items.map(String).filter(Boolean).slice(0, 3) : fallback.items;
    const queries = Array.isArray(parsed.queries)
      ? parsed.queries.map(String).filter(Boolean).slice(0, 3)
      : fallback.queries;
    const recommended_format = formatOf(String(parsed.recommended_format || ''));
    const need = recommended_format === 'TIER_LIST_SWIPE' ? 3 : 1;
    return {
      trending_topic: String(parsed.trending_topic || fallback.trending_topic).slice(0, 80),
      recommended_format,
      hook_text: String(parsed.hook_text || fallback.hook_text).slice(0, 90),
      items: (items.length ? items : fallback.items).slice(0, need),
      queries: (queries.length ? queries : fallback.queries).slice(0, need),
      slides_blueprint: Array.isArray(parsed.slides_blueprint) && parsed.slides_blueprint.length
        ? parsed.slides_blueprint
        : fallback.slides_blueprint,
    };
  } catch {
    return fallback;
  } finally {
    clearTimeout(timer);
  }
}
