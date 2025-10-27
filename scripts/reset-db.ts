import { PrismaClient } from '@prisma/client';

async function main() {
  const prisma = new PrismaClient();

  try {
    // Drop all tables
    await prisma.$executeRawUnsafe('DROP TABLE IF EXISTS "_prisma_migrations" CASCADE');
    await prisma.$executeRawUnsafe('DROP TABLE IF EXISTS "yellow_books" CASCADE');
    
    console.log('✅ Database tables dropped successfully');
  } catch (error) {
    console.error('❌ Error:', error);
  } finally {
    await prisma.$disconnect();
  }
}

main();
