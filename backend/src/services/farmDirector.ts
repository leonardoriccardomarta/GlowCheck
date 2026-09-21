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

const FORMAT_ROTATION: FarmFormat[] = [
  'TIER_LIST_SWIPE',
  'DEEP_DIVE',
  'RED_FLAG_INCI',
  'TIER_LIST_SWIPE',
];

function formatOf(value: string): FarmFormat {
  if (value === 'TIER_LIST_SWIPE' || value === 'RED_FLAG_INCI') return value;
  return 'DEEP_DIVE';
}

function hashSlot(ideas: ReadyFarmIdea[]): number {
  const key = ideas.map((idea) => idea.query || idea.label).join('|') || 'glow';
  let h = 2166136261;
  for (let i = 0; i < key.length; i++) {
    h ^= key.charCodeAt(i);
    h = Math.imul(h, 16777619);
  }
  return (h >>> 0) % FORMAT_ROTATION.length;
}

function redFlagIdea(ideas: ReadyFarmIdea[]): ReadyFarmIdea | undefined {
  return (
    ideas.find((idea) =>
      /fragrance|pore|clog|smell|slugging|balm|oil|cream|ointment|peel|aha|alcohol/i.test(
        `${idea.angle} ${idea.label}`,
      ),
    ) || ideas[0]
  );
}

function slidesFor(format: FarmFormat): FarmBlueprint['slides_blueprint'] {
  if (format === 'TIER_LIST_SWIPE') {
    return [
      { slide: 1, type: 'tier_cover' },
      { slide: 2, type: 'score_worst' },
      { slide: 3, type: 'score_best' },
      { slide: 4, type: 'cta' },
    ];
  }
  if (format === 'RED_FLAG_INCI') {
    return [
      { slide: 1, type: 'inci_red_flags' },
      { slide: 2, type: 'score_worst' },
      { slide: 3, type: 'score_best' },
      { slide: 4, type: 'cta' },
    ];
  }
  return [
    { slide: 1, type: 'hook_comparison' },
    { slide: 2, type: 'score_worst' },
    { slide: 3, type: 'score_best' },
    { slide: 4, type: 'cta' },
  ];
}

export function enforceFormatMix(groqFormat: FarmFormat, ideas: ReadyFarmIdea[]): FarmFormat {
  let format = groqFormat;
  if (format === 'DEEP_DIVE') format = FORMAT_ROTATION[hashSlot(ideas)];
  if (format === 'TIER_LIST_SWIPE' && ideas.length < 2) format = 'RED_FLAG_INCI';
  if (format === 'RED_FLAG_INCI' && !ideas.length) format = 'DEEP_DIVE';
  return format;
}

function pickFromCatalog(format: FarmFormat, ideas: ReadyFarmIdea[]): { queries: string[]; items: string[] } {
  const need = format === 'TIER_LIST_SWIPE' ? 3 : 1;
  const start = format === 'RED_FLAG_INCI' ? redFlagIdea(ideas) : ideas[0];
  const pool = start ? [start, ...ideas.filter((idea) => idea.query !== start.query)] : ideas;
  const unique: ReadyFarmIdea[] = [];
  for (const idea of pool) {
    if (!idea?.query) continue;
    if (unique.some((row) => row.query.toLowerCase() === idea.query.toLowerCase())) continue;
    unique.push(idea);
    if (unique.length >= need) break;
  }
  return {
    queries: unique.map((idea) => idea.query),
    items: unique.map((idea) => idea.label),
  };
}

export function heuristicBlueprint(ideas: ReadyFarmIdea[]): FarmBlueprint {
  const format = enforceFormatMix('DEEP_DIVE', ideas);
  const picked = pickFromCatalog(format, ideas);
  const one = ideas.find((idea) => idea.query === picked.queries[0]) || ideas[0];
  return {
    trending_topic: one?.angle || 'Skintok INCI check',
    recommended_format: format,
    hook_text: one
      ? `Why your skin is still breaking out using ${one.label} 🚩`
      : 'Stop using this if you have clogged pores 🛑',
    items: picked.items.length ? picked.items : ['CeraVe'],
    queries: picked.queries.length ? picked.queries : ['CeraVe PM'],
    slides_blueprint: slidesFor(format),
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
    'You are a Skintok trend director for GlowCheck. JSON only, no markdown. Break pattern blindness: at least half of packs must be TIER_LIST_SWIPE or RED_FLAG_INCI. Do not default to DEEP_DIVE. Do not write TikTok titles or captions.';
  const user = `Live TikTok posts ranked by save rate (may be empty if no scraper key):
${feed || '(no live posts — pick catalog items that match current Skintok demand: clogged pores, CeraVe, LRP, SPF, BHA, rankings, fragrance flags)'}

Unused GlowCheck catalog with INCI:
${catalog || '(empty)'}

Return JSON:
{"trending_topic":"","recommended_format":"TIER_LIST_SWIPE","hook_text":"","items":[""],"queries":[""],"slides_blueprint":[{"slide":1,"type":"tier_cover"},{"slide":2,"type":"score_worst"},{"slide":3,"type":"score_best"},{"slide":4,"type":"cta"}]}
Rules:
- queries MUST be unused catalog products from the list above, never the same bottle as a previous pack
- At least 50% TIER_LIST_SWIPE or RED_FLAG_INCI. DEEP_DIVE at most half the time.
- TIER_LIST_SWIPE: 3 different unused products side by side. Use for comparisons, rankings, dupes, "which is better", or whenever the grid would otherwise be another single white bottle. Then 3 queries.
- RED_FLAG_INCI: 1 product with fragrance, alcohol, essential oil, or pore-clogger drama. Circle flagged INCI.
- DEEP_DIVE: one viral bottle, Dry vs Oily. Only when a single hero bottle is clearly the object AND the last packs were TIER/RED.
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
        temperature: 0.45,
        max_completion_tokens: 600,
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
    const groqFormat = formatOf(String(parsed.recommended_format || ''));
    const recommended_format = enforceFormatMix(groqFormat, ideas);
    const picked = pickFromCatalog(recommended_format, ideas);
    return {
      trending_topic: String(parsed.trending_topic || fallback.trending_topic).slice(0, 80),
      recommended_format,
      hook_text: String(parsed.hook_text || fallback.hook_text).slice(0, 90),
      items: picked.items.length ? picked.items : fallback.items,
      queries: picked.queries.length ? picked.queries : fallback.queries,
      slides_blueprint:
        Array.isArray(parsed.slides_blueprint) && parsed.slides_blueprint.length
          ? parsed.slides_blueprint
          : slidesFor(recommended_format),
    };
  } catch {
    return fallback;
  } finally {
    clearTimeout(timer);
  }
}
