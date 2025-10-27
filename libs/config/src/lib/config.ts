/**
 * Application Configuration
 * Environment тохиргоог энд төвлөрүүлнэ
 */

export const config = {
  api: {
    port: process.env['API_PORT'] || 3333,
    host: process.env['API_HOST'] || 'localhost',
  },
  web: {
    port: process.env['WEB_PORT'] || 4200,
    apiUrl: process.env['NEXT_PUBLIC_API_URL'] || 'http://localhost:3333',
  },
  database: {
    url: process.env['DATABASE_URL'] || 'file:./dev.db',
  },
} as const;

export type Config = typeof config;
