import 'dotenv/config';
import express from 'express';
import cors from 'cors';
import { PrismaClient } from '@prisma/client';
import { YellowBookEntrySchema } from '@yellowbook/contract';
import { config } from '@yellowbook/config';

const prisma = new PrismaClient();
const app = express();

// Middleware
app.use(cors());
app.use(express.json());

// Health check
app.get('/', (req, res) => {
  res.send({ message: 'Yellow Book API', version: '1.0.0' });
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
      where: { id },
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

const host = config.api.host as string;
const port = config.api.port as number;

app.listen(port, host, () => {
  console.log(`🚀 Yellow Book API running at http://${host}:${port}`);
});

// Graceful shutdown
process.on('SIGINT', async () => {
  await prisma.$disconnect();
  process.exit(0);
});
