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
# Fork the repository on GitHub
# Then clone your fork
git clone https://github.com/YOUR_USERNAME/yellowbook.git
cd yellowbook
```

### 2. Install Dependencies

```bash
npm install
```

### 3. Set Up Environment

```bash
# Copy environment template
cp .env.example .env

# Update .env with your local settings
```

### 4. Database Setup

```bash
# Generate Prisma Client
npx prisma generate

# Run migrations
npx prisma migrate dev

# Seed database (optional)
npm run db:seed
```

### 5. Create a Branch

```bash
# Create a new branch for your feature
git checkout -b feature/your-feature-name

# Or for bug fixes
git checkout -b fix/bug-description
```

### 6. Make Changes

Follow the [Code Standards](#code-standards) below.

### 7. Test Locally

```bash
# Run linting
npm run lint

# Run format check
npm run format:check

# Run type checking
npm run type-check

# Run tests
npx nx affected -t test

# Build affected projects
npx nx affected -t build

# Test Docker builds
.\scripts\docker-test.ps1 all  # Windows
./scripts/docker-test.sh all   # Linux/Mac
```

### 8. Commit Changes

We follow conventional commits:

```bash
# Format: <type>(<scope>): <subject>
# Examples:
git commit -m "feat(api): add new endpoint for categories"
git commit -m "fix(web): resolve navigation bug"
git commit -m "docs: update README with Docker instructions"
git commit -m "chore: update dependencies"
```

Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation only
- `style`: Code style changes (formatting)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks
- `perf`: Performance improvements
- `ci`: CI/CD changes

### 9. Push and Create PR

```bash
# Push to your fork
git push origin feature/your-feature-name

# Create Pull Request on GitHub
```

## 💻 Code Standards

### TypeScript

- Use strict TypeScript mode
- Define proper types (no `any` unless absolutely necessary)
- Use interfaces for objects
- Export types when shared across modules

Example:

```typescript
// ✅ Good
interface YellowBookEntry {
  id: number;
  businessName: string;
  category: string;
}

// ❌ Bad
const data: any = {};
```

### Code Formatting

We use Prettier for formatting:

```bash
# Check formatting
npm run format:check

# Auto-format
npm run format
```

### Linting

We use ESLint:

```bash
# Check linting
npm run lint

# Auto-fix linting issues
npx nx run-many -t lint --fix
```

### Naming Conventions

- **Variables/Functions**: `camelCase`
- **Classes/Interfaces**: `PascalCase`
- **Constants**: `UPPER_SNAKE_CASE`
- **Files**: `kebab-case.ts` or `PascalCase.tsx` (for React components)
- **Folders**: `kebab-case`

Example:

```typescript
// ✅ Good
const userName = 'John';
const MAX_RETRIES = 3;

class UserService {}
interface UserData {}

// ❌ Bad
const user_name = 'John';
const maxretries = 3;
```

### React/Next.js Best Practices

- Use functional components with hooks
- Implement proper error boundaries
- Use TypeScript for props
- Keep components small and focused
- Extract reusable logic to custom hooks

Example:

```typescript
// ✅ Good
interface Props {
  title: string;
  onClose: () => void;
}

export function Modal({ title, onClose }: Props) {
  return <div>{title}</div>;
}

// ❌ Bad
export function Modal(props: any) {
  return <div>{props.title}</div>;
}
```

### API Best Practices

- Use proper HTTP status codes
- Implement error handling
- Validate input with Zod schemas
- Use try-catch blocks
- Return consistent response format

Example:

```typescript
// ✅ Good
app.get('/yellow-books', async (req, res) => {
  try {
    const books = await prisma.yellowBook.findMany();
    res.json({ success: true, data: books });
  } catch (error) {
    res.status(500).json({ 
      success: false, 
      error: 'Failed to fetch yellow books' 
    });
  }
});

// ❌ Bad
app.get('/yellow-books', async (req, res) => {
  const books = await prisma.yellowBook.findMany();
  res.json(books);
});
```

## 🧪 Testing Requirements

### Unit Tests

```bash
# Run tests
npx nx affected -t test

# Run with coverage
npx nx affected -t test --coverage

# Watch mode
npx nx test api --watch
```

### Test Structure

```typescript
describe('YellowBookService', () => {
  it('should fetch all yellow books', async () => {
    // Arrange
    const expected = [{ id: 1, businessName: 'Test' }];
    
    // Act
    const result = await service.getAll();
    
    // Assert
    expect(result).toEqual(expected);
  });
});
```

### Integration Tests

Test API endpoints with actual database:

```typescript
describe('GET /yellow-books', () => {
  it('should return all yellow books', async () => {
    const response = await request(app).get('/yellow-books');
    
    expect(response.status).toBe(200);
    expect(response.body.success).toBe(true);
    expect(Array.isArray(response.body.data)).toBe(true);
  });
});
```

### E2E Tests

Playwright tests for web application:

```bash
# Run E2E tests
npx nx e2e web-e2e
```

## 🐳 Docker Guidelines

### Building Images

Always test Docker builds before pushing:

```bash
# Test individual service
.\scripts\docker-test.ps1 api
.\scripts\docker-test.ps1 web

# Test all services
.\scripts\docker-test.ps1 all

# Or use Docker Compose
docker-compose up --build
```

### Dockerfile Best Practices

- Use multi-stage builds
- Minimize layers
- Use specific image versions (not `latest`)
- Set proper health checks
- Run as non-root user (for production)
- Use .dockerignore to reduce context size

### Health Checks

All services must have health checks:

```dockerfile
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3333/', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"
```

## 📤 Pull Request Process

### Before Creating PR

- ✅ All tests pass locally
- ✅ Linting passes
- ✅ Format check passes
- ✅ Type checking passes
- ✅ Docker builds successfully
- ✅ Code is documented
- ✅ Commits follow conventional commits

### PR Template

When creating a PR, include:

1. **Description**: What does this PR do?
2. **Motivation**: Why is this change needed?
3. **Changes**: List of changes made
4. **Testing**: How was this tested?
5. **Screenshots**: If applicable
6. **Breaking Changes**: Any breaking changes?

### PR Review Process

1. Automated CI checks must pass
2. At least one code review approval
3. All conversations resolved
4. Branch is up to date with main
5. No merge conflicts

### After PR Merge

1. Delete your branch
2. Pull latest changes
3. Update your local environment

## 🔍 Code Review Guidelines

### For Reviewers

- Be constructive and respectful
- Test the changes locally if possible
- Check for security issues
- Verify tests are adequate
- Ensure documentation is updated

### For Authors

- Respond to all comments
- Make requested changes promptly
- Don't take feedback personally
- Ask for clarification if needed
- Thank reviewers for their time

## 🚀 Release Process

Releases are automated:

1. Merge to `main` triggers CI/CD
2. Docker images are built and pushed
3. Images are tagged with commit SHA
4. Health checks validate images
5. Images ready for deployment

## 📚 Additional Resources

- [Nx Documentation](https://nx.dev)
- [Next.js Documentation](https://nextjs.org/docs)
- [Prisma Documentation](https://www.prisma.io/docs)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [TypeScript Handbook](https://www.typescriptlang.org/docs/)

## 💡 Tips

- Use Nx affected commands to only test/build changed projects
- Leverage Nx cache for faster builds
- Run Docker tests before pushing
- Keep PRs small and focused
- Write descriptive commit messages
- Update documentation as you code

## ❓ Questions?

If you have questions:

1. Check existing issues and discussions
2. Review documentation
3. Ask in pull request comments
4. Contact maintainers

Thank you for contributing! 🎉
