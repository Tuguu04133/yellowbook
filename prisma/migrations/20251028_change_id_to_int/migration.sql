-- Drop existing table and recreate with integer ID
DROP TABLE IF EXISTS "yellow_books" CASCADE;

-- CreateTable with integer ID
CREATE TABLE "yellow_books" (
    "id" SERIAL PRIMARY KEY,
    "businessName" TEXT NOT NULL,
    "category" TEXT NOT NULL,
    "phoneNumber" TEXT NOT NULL,
    "address" TEXT NOT NULL,
    "description" TEXT,
    "website" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL
);
