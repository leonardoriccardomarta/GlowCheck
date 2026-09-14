import { Router } from 'express';
import { copy } from '../i18n/scoreCopy';
import { analyzeRequestSchema } from '../schemas/analyze';
import { userFromRequest } from '../services/auth';
import { analyzeProduct } from '../services/analyzeProduct';
import { consumeFreeScan, freeScanBlocked, syncFreeFromCookie } from '../services/freeScan';

export const analyzeRouter = Router();

function paywallBody() {
  return {
    readable: false,
    productName: null,
    compatibilityScore: 0,
    statusBadge: 'CAUTION' as const,
    headline: 'Unlock lifetime access to keep scanning.',
    whyForYou: '',
    occlusionAlert: 'low' as const,
    flaggedIngredients: [],
    ingredients: [],
    dupeId: null,
    dupe: null,
    errorCode: 'PAYWALL' as const,
  };
}

analyzeRouter.post('/', async (req, res) => {
  const parsed = analyzeRequestSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({
      readable: false,
      productName: null,
      compatibilityScore: 0,
      statusBadge: 'CAUTION',
      headline: copy((req.body as { profile?: { locale?: string } })?.profile?.locale, 'invalid'),
      whyForYou: '',
      occlusionAlert: 'low',
      flaggedIngredients: [],
      ingredients: [],
      dupeId: null,
      dupe: null,
      errorCode: 'INTERNAL',
    });
  }

  const user = await userFromRequest(req);
  await syncFreeFromCookie(req, user);
  if (freeScanBlocked(req, user)) {
    return res.status(402).json(paywallBody());
  }

  const result = await analyzeProduct(parsed.data);
  if (result.readable && !result.errorCode) {
    await consumeFreeScan(req, res, user);
  }
  return res.status(200).json(result);
});
