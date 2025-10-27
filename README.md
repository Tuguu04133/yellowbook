# 📒 Yellow Book - Mongolian Business Directory

A full-stack monorepo application built with **Nx**, featuring a **Next.js** frontend, **Express** backend, and shared libraries for type-safe communication.

## 🚀 Features

- ✅ **Nx Monorepo** - Efficient workspace management with caching and affected commands
- ✅ **Next.js 15** - Modern React framework with App Router
- ✅ **Express API** - RESTful backend with TypeScript
- ✅ **Prisma ORM** - Type-safe database access with SQLite
- ✅ **Zod Validation** - Shared schemas between frontend and backend
- ✅ **TypeScript Strict Mode** - Type safety across the entire codebase
- ✅ **ESLint & Prettier** - Code quality and formatting
- ✅ **GitHub Actions CI** - Automated testing with Nx affected commands

## 📁 Project Structure

```
yellowbook/
├── apps/
│   ├── api/          # Express backend API
│   └── web/          # Next.js frontend application
├── libs/
│   ├── contract/     # Shared Zod schemas and TypeScript types
│   └── config/       # Shared configuration
├── prisma/
│   ├── schema.prisma # Database schema
│   ├── seed.ts       # Database seeding script
│   └── migrations/   # Database migrations
└── .github/
    └── workflows/    # CI/CD pipelines
```

## 🛠️ Technology Stack

### Frontend
- **Next.js 15** - React framework with server components
- **TypeScript** - Type-safe development
- **Zod** - Runtime type validation

### Backend
- **Express** - Node.js web framework
- **Prisma** - Modern ORM
- **SQLite** - Development database
- **CORS** - Cross-origin resource sharing

### Dev Tools
- **Nx** - Monorepo management and build system
- **ESLint** - Linting
- **Prettier** - Code formatting
- **tsx** - TypeScript execution
- **GitHub Actions** - CI/CD

## 🏃 Getting Started

### Prerequisites
- Node.js 20+
- npm or yarn

### Installation

```bash
# Clone the repository
git clone https://github.com/Tuguu04133/yellowbook.git
cd yellowbook

# Install dependencies
npm install

# Set up database
npx prisma migrate dev

# Seed database with sample data
npm run db:seed
```

### Running the Application

```bash
# Start the API server (runs on http://localhost:3333)
npx nx serve api

# Start the Next.js app (runs on http://localhost:4200)
npx nx serve web
```

### Available Scripts

```bash
# Linting
npm run lint

# Format code
npm run format

# Type checking
npm run type-check

# Database seeding
npm run db:seed

# Build all projects
npx nx run-many -t build

# Run affected tests
npx nx affected -t test

# View dependency graph
npx nx graph
```

## 🎨 Design Choices

### 1. **Nx Monorepo**
**Why:** Nx provides powerful tooling for managing multiple applications and libraries in a single repository. It offers:
- **Affected commands** - Only build/test what changed
- **Computation caching** - Faster builds
- **Dependency graph visualization** - Better understanding of project structure
- **Integrated dev experience** - Single source of truth

### 2. **Shared Contract Library**
**Why:** Using Zod schemas in a shared library (`libs/contract`) ensures:
- **Single source of truth** for data structures
- **Type safety** across frontend and backend
- **Runtime validation** with the same schemas
- **DRY principle** - Define once, use everywhere

```typescript
// Defined once in libs/contract
export const YellowBookEntrySchema = z.object({
  id: z.string().uuid(),
  businessName: z.string(),
  // ...
});

// Used in API for validation
const validated = YellowBookEntrySchema.parse(data);

// Used in Next.js for type inference
type YellowBookEntry = z.infer<typeof YellowBookEntrySchema>;
```

### 3. **Prisma ORM**
**Why:** Prisma offers:
- **Type-safe database access** - Auto-generated TypeScript types
- **Migration system** - Version-controlled schema changes
- **Easy seeding** - Populate database with test data
- **Query builder** - Intuitive API
- **SQLite for development** - No external database needed

### 4. **TypeScript Strict Mode**
**Why:** Strict mode catches more errors at compile time:
- Prevents `any` types
- Requires explicit null checks
- Enforces consistent typing
- Improves code maintainability

### 5. **Server Components (Next.js 15)**
**Why:** Server components provide:
- **Better performance** - Less JavaScript sent to client
- **Direct database access** - No API needed for data fetching
- **SEO friendly** - Server-rendered content
- **Simplified data fetching** - async/await in components

### 6. **CI with Nx Affected**
**Why:** GitHub Actions with Nx affected commands:
- **Faster CI runs** - Only test/build changed projects
- **Cost efficient** - Less compute time
- **Parallel execution** - Run multiple tasks simultaneously
- **Confidence** - Automated quality checks

## 🗄️ Database Schema

```prisma
model YellowBook {
  id           String   @id @default(uuid())
  businessName String
  category     String
  phoneNumber  String
  address      String
  description  String?
  website      String?
  createdAt    DateTime @default(now())
  updatedAt    DateTime @updatedAt
}
```

## 🔌 API Endpoints

### `GET /yellow-books`
Get all yellow book listings

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": "uuid",
      "businessName": "Улаанбаатар Ресторан",
      "category": "Restaurant",
      "phoneNumber": "+976-7011-1234",
      "address": "Сүхбаатарын талбай",
      "description": "Монгол болон олон улсын хоол",
      "website": "https://example.mn",
      "createdAt": "2025-10-27T...",
      "updatedAt": "2025-10-27T..."
    }
  ],
  "count": 7
}
```

### `GET /yellow-books/:id`
Get a single yellow book entry by ID

## 🧪 Testing

```bash
# Run all tests
npx nx run-many -t test

# Run tests for affected projects
npx nx affected -t test

# Run tests with coverage
npx nx run-many -t test --coverage
```

## 📦 Building for Production

```bash
# Build all apps
npx nx run-many -t build --configuration=production

# Build only affected apps
npx nx affected -t build --configuration=production

# Build specific app
npx nx build api
npx nx build web
```

## 🚀 Deployment

### API Deployment
The Express API can be deployed to:
- Vercel
- Railway
- Render
- DigitalOcean App Platform

### Web Deployment
The Next.js app can be deployed to:
- Vercel (recommended)
- Netlify
- AWS Amplify

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📝 License

ISC

## 👨‍💻 Author

**Tuguu04133**

---

Built with ❤️ using Nx, Next.js, and Express
