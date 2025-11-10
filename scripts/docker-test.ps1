# Local Docker Build & Test Script for Windows
# Usage: .\scripts\docker-test.ps1 [api|web|all]

param(
    [ValidateSet('api', 'web', 'all')]
    [string]$Service = 'all'
)

$ErrorActionPreference = "Stop"
$env:DOCKER_BUILDKIT = "1"

Write-Host "🐳 Yellow Book - Local Docker Build & Test" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

function Build-Image {
    param([string]$ServiceName)
    
    Write-Host "Building $ServiceName image..." -ForegroundColor Yellow
    docker build -f "Dockerfile.$ServiceName" -t "yellowbook-${ServiceName}:test" .
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ $ServiceName image built successfully" -ForegroundColor Green
    } else {
        Write-Host "✗ Failed to build $ServiceName image" -ForegroundColor Red
        exit 1
    }
    Write-Host ""
}

function Test-Image {
    param(
        [string]$ServiceName,
        [int]$Port
    )
    
    Write-Host "Testing $ServiceName image..." -ForegroundColor Yellow
    
    # Clean up any existing container
    docker rm -f "yellowbook-$ServiceName-test" 2>$null
    
    # Run container
    if ($ServiceName -eq "api") {
        docker run -d --name "yellowbook-$ServiceName-test" `
            -e DATABASE_URL="postgresql://test:test@localhost:5432/test" `
            -e PORT=$Port `
            -p "${Port}:${Port}" `
            "yellowbook-${ServiceName}:test"
    } else {
        docker run -d --name "yellowbook-$ServiceName-test" `
            -e NEXT_PUBLIC_API_URL="http://localhost:3333" `
            -e PORT=$Port `
            -p "${Port}:${Port}" `
            "yellowbook-${ServiceName}:test"
    }
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "✗ Failed to start container" -ForegroundColor Red
        exit 1
    }
    
    # Wait for health check
    Write-Host "Waiting for container to be healthy..."
    $timeout = 60
    $elapsed = 0
    $healthy = $false
    
    while ($elapsed -lt $timeout) {
        $healthStatus = docker inspect --format='{{.State.Health.Status}}' "yellowbook-$ServiceName-test" 2>$null
        if ($healthStatus -eq "healthy") {
            $healthy = $true
            break
        }
        Start-Sleep -Seconds 2
        $elapsed += 2
    }
    
    if (-not $healthy) {
        Write-Host "✗ Container failed to become healthy" -ForegroundColor Red
        docker logs "yellowbook-$ServiceName-test"
        docker rm -f "yellowbook-$ServiceName-test"
        exit 1
    }
    
    # Test endpoint
    Write-Host "Testing HTTP endpoint..."
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:$Port/" -TimeoutSec 5 -UseBasicParsing
        if ($response.StatusCode -eq 200) {
            Write-Host "✓ $ServiceName container is healthy and responding" -ForegroundColor Green
        } else {
            throw "Unexpected status code: $($response.StatusCode)"
        }
    } catch {
        Write-Host "✗ $ServiceName endpoint not responding" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        docker logs "yellowbook-$ServiceName-test"
        docker rm -f "yellowbook-$ServiceName-test"
        exit 1
    }
    
    # Show container info
    Write-Host ""
    Write-Host "Container Details:"
    docker ps --filter "name=yellowbook-$ServiceName-test"
    Write-Host ""
    
    # Cleanup
    docker rm -f "yellowbook-$ServiceName-test"
    Write-Host "✓ $ServiceName test completed" -ForegroundColor Green
    Write-Host ""
}

function Build-AndTest {
    param(
        [string]$ServiceName,
        [int]$Port
    )
    
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "Service: $ServiceName" -ForegroundColor Cyan
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host ""
    
    Build-Image -ServiceName $ServiceName
    Test-Image -ServiceName $ServiceName -Port $Port
}

# Main execution
switch ($Service) {
    'api' {
        Build-AndTest -ServiceName 'api' -Port 3333
    }
    'web' {
        Build-AndTest -ServiceName 'web' -Port 3000
    }
    'all' {
        Build-AndTest -ServiceName 'api' -Port 3333
        Build-AndTest -ServiceName 'web' -Port 3000
    }
}

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "🎉 All tests passed!" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Images ready:"
Write-Host "  - yellowbook-api:test"
Write-Host "  - yellowbook-web:test"
Write-Host ""
Write-Host "To run with docker-compose:"
Write-Host "  docker-compose up -d"
Write-Host ""
