import { z } from 'zod';

/**
 * Yellow Book Entry Schema
 * Энэ schema нь yellow book-н жагсаалтын бүтцийг тодорхойлно
 */
export const YellowBookEntrySchema = z.object({
  id: z.number().int().positive(),
  businessName: z.string().min(1, 'Business name is required'),
  category: z.string().min(1, 'Category is required'),
  phoneNumber: z.string().regex(/^[0-9\-\+\(\)\s]+$/, 'Invalid phone number'),
  address: z.string().min(1, 'Address is required'),
  description: z.string().optional().nullable(),
  website: z.string().url().optional().or(z.literal('')).nullable(),
  createdAt: z.date().or(z.string()),
  updatedAt: z.date().or(z.string()),
});

/**
 * Create Yellow Book Entry Schema (without id and timestamps)
 */
export const CreateYellowBookEntrySchema = YellowBookEntrySchema.omit({
  id: true,
  createdAt: true,
  updatedAt: true,
});

/**
 * Update Yellow Book Entry Schema (partial)
 */
export const UpdateYellowBookEntrySchema = CreateYellowBookEntrySchema.partial();

/**
 * TypeScript Types
 */
export type YellowBookEntry = z.infer<typeof YellowBookEntrySchema>;
export type CreateYellowBookEntry = z.infer<typeof CreateYellowBookEntrySchema>;
export type UpdateYellowBookEntry = z.infer<typeof UpdateYellowBookEntrySchema>;
