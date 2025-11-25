# Local Testing Guide

This guide explains how to test your Docker setup locally before pushing to GitHub.

## Prerequisites

- Docker Desktop installed and running
- Docker Compose installed (included with Docker Desktop)
- At least 4GB of free disk space
- PowerShell (Windows) or Bash (Linux/Mac)

## Хурдан асаах

### Docker Compose ашиглах (Энэ нь хамгийн хялбар)

```bash
# Бүх зүйлийг эхлүүлэх
docker-compose up --build

# Эсвэл background дээр ажиллуулах
docker-compose up -d --build

# Logs харах
docker-compose logs -f

# Зогсоох
docker-compose down
```

Хаяг:
- Web: http://localhost:3000
- API: http://localhost:3333

## Тусад нь тест хийх

### PowerShell script ашиглах

```powershell
# Бүгдийг тест хийх
.\scripts\docker-test.ps1 all

# API л тест хийх
.\scripts\docker-test.ps1 api

# Web л тест хийх
.\scripts\docker-test.ps1 web
```

### Гараар build хийх

```bash
# API image build
docker build -f Dockerfile.api -t yellowbook-api:test .

# Web image build
docker build -f Dockerfile.web -t yellowbook-web:test .
```

### API ажиллуулах

```bash
# Network үүсгэх
docker network create yellowbook-net

# PostgreSQL эхлүүлэх
docker run -d --name postgres-test \
  --network yellowbook-net \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=yellowbook \
  -p 5432:5432 \
  postgres:16-alpine

# Хэдэн секунд хүлээнэ
sleep 5

# API ажиллуулах
docker run -d --name api-test \
  --network yellowbook-net \
  -e DATABASE_URL="postgresql://postgres:postgres@postgres-test:5432/yellowbook" \
  -e PORT=3333 \
  -p 3333:3333 \
  yellowbook-api:test

# Logs шалгах
docker logs -f api-test
```

### Web ажиллуулах

```bash
docker run -d --name web-test \
  --network yellowbook-net \
  -e NEXT_PUBLIC_API_URL="http://localhost:3333" \
  -e PORT=3000 \
  -p 3000:3000 \
  yellowbook-web:test

# Logs харах
docker logs -f web-test
```

## Health Check

### Container эрүүл байгаа эсэхийг шалгах

```bash
# API эрүүл байгаа эсэх
docker inspect --format='{{.State.Health.Status}}' api-test

# Web эрүүл байгаа эсэх
docker inspect --format='{{.State.Health.Status}}' web-test
```

### Manual test

```bash
# API шалгах
curl http://localhost:3333/

# Хариулт: {"message":"Yellow Book API","version":"1.0.0"}

# Web шалгах
curl http://localhost:3000/
```

## API endpoint тест

### Бүх бизнес авах

```bash
curl http://localhost:3333/yellow-books
```

### Тодорхой бизнес авах

```bash
curl http://localhost:3333/yellow-books/1
```

### Шинэ бизнес үүсгэх

```bash
curl -X POST http://localhost:3333/yellow-books \
  -H "Content-Type: application/json" \
  -d '{
    "businessName": "Test Business",
    "category": "Technology",
    "phoneNumber": "99119911",
    "address": "Ulaanbaatar, Mongolia"
  }'
```

## Алдаа хайх

### Logs харах

```bash
# API logs
docker logs api-test

# Real-time logs
docker logs -f api-test

# Сүүлийн 50 мөр
docker logs --tail 50 api-test
```

### Container дотор команд ажиллуулах

```bash
# Container руу орох
docker exec -it api-test sh

# Node.js version шалгах
node --version

# Environment variable харах
env | grep DATABASE
```

### Resource usage шалгах

```bash
# Real-time stats
docker stats

# Тодорхой container
docker stats api-test web-test
```

## Database тест

### PostgreSQL руу холбогдох

```bash
# Database холбогдох
docker exec -it postgres-test psql -U postgres -d yellowbook

# Table-уудыг харах
\dt

# Yellow books харах
SELECT * FROM yellow_books;

# Гарах
\q
```

### Database reset хийх

```bash
# API зогсоох
docker stop api-test

# Database дахин үүсгэх
docker exec postgres-test psql -U postgres -c "DROP DATABASE IF EXISTS yellowbook;"
docker exec postgres-test psql -U postgres -c "CREATE DATABASE yellowbook;"

# API эхлүүлэх
docker start api-test
```

## Цэвэрлэх

### Container устгах

```bash
# Бүх container зогсоох
docker stop api-test web-test postgres-test

# Container устгах
docker rm api-test web-test postgres-test

# Network устгах
docker network rm yellowbook-net
```

### Image устгах

```bash
# Test images устгах
docker rmi yellowbook-api:test yellowbook-web:test

# Бүх хог image устгана
docker image prune -f
```

### Бүгдийг цэвэрлэх

```bash
# Docker compose бүгдийг зогсоож устгана
docker-compose down -v

# Бүх хэрэггүй зүйл устгана
docker system prune -a --volumes -f
```

## Түгээмэл асуудал

### Port эзэлсэн байна

```bash
# Аль process port ашиглаж байгааг хайх
netstat -ano | findstr :3333

# Эсвэл өөр port ашиглах
docker run -p 3334:3333 ...
```

### Container шууд унана

```bash
# Logs шалга
docker logs api-test

# Ихэвчлэн:
# - DATABASE_URL буруу байна
# - Port эзэлсэн байна
# - Dependencies дутуу
```

### Build амжилтгүй

```bash
# Cache цэвэрлэх
docker builder prune -af

# Cache-гүй build хийх
docker build --no-cache -f Dockerfile.api -t yellowbook-api:test .
```

## Дараагийн алхам

Local тест амжилттай болсон бол:

1. GitHub руу push хий
2. GitHub Actions ногоон болсон эсэхийг шалга
3. Docker images GHCR дээр байгаа эсэхийг шалга
4. AWS ECR setup хий (docs/AWS-ECR-SETUP.md үз)

## Хэрэгтэй командууд

```bash
# Ажиллаж байгаа containers
docker ps

# Бүх containers (зогссон ч гэсэн)
docker ps -a

# Бүх images
docker images

# Disk usage
docker system df

# Container процессүүд
docker top api-test

# Container-с файл хуулах
docker cp api-test:/app/dist ./dist-backup
```

---
