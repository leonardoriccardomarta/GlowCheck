import { Router } from 'express';
import { analyzeRequestSchema } from '../schemas/analyze';
import { analyzeProduct } from '../services/analyzeProduct';

export const analyzeRouter = Router();

analyzeRouter.post('/', async (req, res) => {
  const parsed = analyzeRequestSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({
      readable: false,
      productName: null,
      compatibilityScore: 0,
      statusBadge: 'CAUTION',
      headline: 'Invalid scan request',
      whyForYou: '',
      occlusionAlert: 'low',
      flaggedIngredients: [],
      ingredients: [],
      dupeId: null,
      dupe: null,
      errorCode: 'INTERNAL',
    });
  }

  const result = await analyzeProduct(parsed.data);
  return res.status(200).json(result);
});
