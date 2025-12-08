import 'dotenv/config';
import express from 'express';
import cors from 'cors';
import { PrismaClient } from '@prisma/client';
import { YellowBookEntrySchema } from '@yellowbook/contract';

const prisma = new PrismaClient();
const app = express();

// Middleware
app.use(cors());
app.use(express.json());

// Health check
app.get('/', (req, res) => {
  res.send({ message: 'Yellow Book API', version: '1.0.0' });
});

app.get('/api/health', (req, res) => {
  res.status(200).json({ status: 'ok', timestamp: new Date().toISOString() });
});

// GET /yellow-books - жагсаалт авах
app.get('/yellow-books', async (req, res) => {
  try {
    const yellowBooks = await prisma.yellowBook.findMany({
      orderBy: {
        createdAt: 'desc',
      },
    });

    // Validate with Zod schema
    const validated = yellowBooks.map((book) =>
      YellowBookEntrySchema.parse(book)
    );

    res.json({
      success: true,
      data: validated,
      count: validated.length,
    });
  } catch (error) {
    console.error('Error fetching yellow books:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch yellow books',
    });
  }
});

// GET /yellow-books/:id - нэг бичлэг авах
app.get('/yellow-books/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const yellowBook = await prisma.yellowBook.findUnique({
      where: { id: parseInt(id, 10) },
    });

    if (!yellowBook) {
      return res.status(404).json({
        success: false,
        error: 'Yellow book entry not found',
      });
    }

    const validated = YellowBookEntrySchema.parse(yellowBook);

    res.json({
      success: true,
      data: validated,
    });
  } catch (error) {
    console.error('Error fetching yellow book:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch yellow book',
    });
  }
});

// POST /yellow-books - шинэ бичлэг нэмэх
app.post('/yellow-books', async (req, res) => {
  try {
    console.log('Received POST data:', req.body);
    
    const validatedData = YellowBookEntrySchema.omit({ 
      id: true, 
      createdAt: true, 
      updatedAt: true 
    }).parse(req.body);

    const yellowBook = await prisma.yellowBook.create({
      data: validatedData,
    });

    res.status(201).json({
      success: true,
      data: yellowBook,
    });
  } catch (error) {
    console.error('Error creating yellow book:', error);
    
    // Zod validation error-ийг илүү дэлгэрэнгүй харуулах
    if (error instanceof Error && 'issues' in error) {
      return res.status(400).json({
        success: false,
        error: 'Validation failed',
        details: error,
      });
    }
    
    res.status(400).json({
      success: false,
      error: 'Failed to create yellow book entry',
      message: error instanceof Error ? error.message : 'Unknown error',
    });
  }
});

const host = process.env['HOST'] || '0.0.0.0';
const port = Number(process.env['PORT']) || 3333;

app.listen(port, host, () => {
  console.log(`🚀 Yellow Book API running at http://${host}:${port}`);
});

// Graceful shutdown
process.on('SIGINT', async () => {
  await prisma.$disconnect();
  process.exit(0);
});
