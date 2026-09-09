import { z } from 'zod';

export const skinTypeSchema = z.enum(['oily', 'dry', 'combination', 'sensitive']);
export const mainGoalSchema = z.enum(['pores', 'hydration', 'budget']);

export const analyzeRequestSchema = z
  .object({
    imageBase64: z.string().min(80).max(8_000_000).optional(),
    mimeType: z.enum(['image/jpeg', 'image/png']).optional(),
    barcode: z.string().max(32).optional(),
    readInci: z.boolean().optional(),
    profile: z.object({
      skinType: skinTypeSchema,
      mainGoal: mainGoalSchema,
      spendBand: z.enum(['low', 'mid', 'high']).optional(),
      locale: z.enum(['it', 'en', 'es', 'fr', 'de']).optional(),
    }),
  })
  .refine((value) => Boolean(value.imageBase64) || Boolean(value.barcode && value.barcode.replace(/\D/g, '').length >= 8), {
    message: 'Provide a photo or a barcode',
  });

export const analyzeResponseSchema = z.object({
  readable: z.boolean(),
  productName: z.string().nullable().optional(),
  compatibilityScore: z.number().int().min(0).max(100),
  statusBadge: z.enum(['COMPATIBLE', 'CAUTION', 'NOT_IDEAL']),
  headline: z.string(),
  whyForYou: z.string().optional().default(''),
  occlusionAlert: z.enum(['low', 'medium', 'high']),
  flaggedIngredients: z
    .array(
      z.object({
        name: z.string(),
        kind: z.enum(['warning', 'good']),
        note: z.string(),
      })
    )
    .optional()
    .default([]),
  ingredients: z
    .array(
      z.object({
        name: z.string(),
        tag: z.enum(['watch', 'fit', 'listed']),
        note: z.string().nullable(),
      })
    )
    .optional()
    .default([]),
  dupeId: z.string().nullable().optional(),
  dupe: z
    .object({
      id: z.string().nullable().optional(),
      brand: z.string(),
      name: z.string(),
      estimatedPrice: z.string(),
      blurb: z.string(),
      whyThis: z.string(),
    })
    .nullable()
    .optional(),
  errorCode: z.enum(['UNREADABLE', 'NOT_COSMETIC', 'INTERNAL', 'NEED_INCI']).nullable().optional(),
});

export type AnalyzeRequest = z.infer<typeof analyzeRequestSchema>;
export type AnalyzeResponse = {
  readable: boolean;
  productName: string | null;
  compatibilityScore: number;
  statusBadge: 'COMPATIBLE' | 'CAUTION' | 'NOT_IDEAL';
  headline: string;
  whyForYou: string;
  occlusionAlert: 'low' | 'medium' | 'high';
  flaggedIngredients: { name: string; kind: 'warning' | 'good'; note: string }[];
  ingredients: { name: string; tag: 'watch' | 'fit' | 'listed'; note: string | null }[];
  dupeId: string | null;
  dupe: {
    id?: string | null;
    brand: string;
    name: string;
    estimatedPrice: string;
    blurb: string;
    whyThis: string;
  } | null;
  errorCode: 'UNREADABLE' | 'NOT_COSMETIC' | 'INTERNAL' | 'NEED_INCI' | null;
};
