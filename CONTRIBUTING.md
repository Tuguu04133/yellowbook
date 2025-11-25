# Contributing to Yellow Book

Thank you for your interest in contributing to Yellow Book! This guide will help you get started.

## 📋 Table of Contents

- [Development Workflow](#development-workflow)
- [Code Standards](#code-standards)
- [Testing Requirements](#testing-requirements)
- [Docker Guidelines](#docker-guidelines)
- [Pull Request Process](#pull-request-process)

## 🔄 Development Workflow

### 1. Fork and Clone

```bash
git clone https://github.com/Tuguu04133/yellowbook.git
cd yellowbook
```

### 2. Dependencies суулгах

```bash
npm install
```

### 3. Environment тохируулах

```bash
cp .env.example .env
# .env файлыг засаж тохируул
```

### 4. Database

```bash
npx prisma generate
npx prisma migrate dev
npm run db:seed
```

### 5. Branch үүсгэх

```bash
# Feature
git checkout -b feature/your-feature-name

# Bug fix
git checkout -b fix/bug-description
```

### 6. Тест хийх

```bash
# Lint
npm run lint

# Format
npm run format:check

# Type check
npm run type-check

# Test
npx nx affected -t test

# Build
npx nx affected -t build

# Docker test
.\scripts\docker-test.ps1 all  # Windows
```

### 7. Commit

```bash
# Жишээ:
git commit -m "feat(api): add new endpoint"
git commit -m "fix(web): resolve bug"
git commit -m "docs: update README"
```

Types:
- `feat`: Шинэ feature
- `fix`: Bug засах
- `docs`: Documentation
- `style`: Formatting
- `refactor`: Code refactor
- `test`: Test нэмэх
- `chore`: Бусад

### 8. Push болон PR

```bash
git push origin feature/your-feature-name
# GitHub дээр Pull Request үүсгэ
```

## Code стандарт

### TypeScript

- Strict mode ашигла
- `any` бүү ашигла
- Interface ашигла
- Type export хий

```typescript
// ✅ Зөв
interface YellowBookEntry {
  id: number;
  businessName: string;
}

// ❌ Буруу
const data: any = {};
```

### Naming

- Variables/Functions: `camelCase`
- Classes/Interfaces: `PascalCase`
- Constants: `UPPER_SNAKE_CASE`
- Files: `kebab-case.ts` эсвэл `PascalCase.tsx`

### React

- Functional components ашигла
- TypeScript props
- Компонент жижиг байлга

```typescript
// ✅ Зөв
interface Props {
  title: string;
  onClose: () => void;
}

export function Modal({ title, onClose }: Props) {
  return <div>{title}</div>;
}
```

## Тест

### Unit tests

```bash
npx nx affected -t test
npx nx affected -t test --coverage
```

## Docker

### Build тест

```bash
.\scripts\docker-test.ps1 api
.\scripts\docker-test.ps1 web
docker-compose up --build
```

### Best practices

- Multi-stage builds ашигла
- Specific versions (not `latest`)
- Health checks нэм
- .dockerignore ашигла

## Pull Request

### PR өмнө

- ✅ Бүх тест ногоон
- ✅ Lint ногоон
- ✅ Format зөв
- ✅ Docker build амжилттай
- ✅ Commit conventional format

### PR агуулга

1. **Description**: Юу хийсэн вэ?
2. **Changes**: Жагсаалт
3. **Testing**: Яаж тест хийсэн вэ?
4. **Screenshots**: Хэрэв байвал

## Нэмэлт

- Nx affected commands ашигла
- Docker тест хий push хийхээс өмнө
- PR жижиг байлга
- Тодорхой commit message бич
- Documentation update хий

---

**Тэмдэглэл:** Энэ бол даалгаврын хэсэг. Энгийн contributing guide-аас илүү хялбаршуулсан.
