# Validation script for Yellowbook EKS deployment (PowerShell)
# This script checks if all required components are deployed and working

$ErrorActionPreference = "Continue"
$NAMESPACE = "yellowbooks"

function Write-Success {
    param($Message)
    Write-Host "✓ $Message" -ForegroundColor Green
}

function Write-Error {
    param($Message)
    Write-Host "✗ $Message" -ForegroundColor Red
}

function Write-Warning {
    param($Message)
    Write-Host "! $Message" -ForegroundColor Yellow
}

function Check-Resource {
    param(
        [string]$ResourceType,
        [string]$ResourceName,
        [string]$Namespace = ""
    )
    
    try {
        if ($Namespace) {
            kubectl get $ResourceType $ResourceName -n $Namespace 2>$null | Out-Null
        } else {
            kubectl get $ResourceType $ResourceName 2>$null | Out-Null
        }
        
        if ($LASTEXITCODE -eq 0) {
            Write-Success "$ResourceType/$ResourceName exists"
            return $true
        } else {
            Write-Error "$ResourceType/$ResourceName not found"
            return $false
        }
    } catch {
        Write-Error "$ResourceType/$ResourceName not found"
        return $false
    }
}

function Check-PodStatus {
    param(
        [string]$Deployment,
        [string]$Namespace
    )
    
    $ready = kubectl get deployment $Deployment -n $Namespace -o jsonpath='{.status.readyReplicas}' 2>$null
    $desired = kubectl get deployment $Deployment -n $Namespace -o jsonpath='{.spec.replicas}' 2>$null
    
    if (-not $ready) { $ready = "0" }
    if (-not $desired) { $desired = "0" }
    
    if ($ready -eq $desired -and [int]$ready -gt 0) {
        Write-Success "Deployment/$Deployment : $ready/$desired pods ready"
        return $true
    } else {
        Write-Error "Deployment/$Deployment : $ready/$desired pods ready"
        return $false
    }
}

Write-Host "===================================================================" -ForegroundColor Cyan
Write-Host "Yellowbook Deployment Validation" -ForegroundColor Cyan
Write-Host "===================================================================" -ForegroundColor Cyan
Write-Host ""

# Check if namespace exists
Write-Host "Checking namespace..." -ForegroundColor Yellow
Check-Resource -ResourceType "namespace" -ResourceName $NAMESPACE
Write-Host ""

# Check ConfigMap and Secret
Write-Host "Checking configuration..." -ForegroundColor Yellow
Check-Resource -ResourceType "configmap" -ResourceName "yellowbook-config" -Namespace $NAMESPACE
Check-Resource -ResourceType "secret" -ResourceName "yellowbook-secrets" -Namespace $NAMESPACE
Write-Host ""

# Check PostgreSQL
Write-Host "Checking PostgreSQL..." -ForegroundColor Yellow
Check-Resource -ResourceType "deployment" -ResourceName "postgres" -Namespace $NAMESPACE
Check-Resource -ResourceType "service" -ResourceName "postgres-service" -Namespace $NAMESPACE
Check-Resource -ResourceType "pvc" -ResourceName "postgres-pvc" -Namespace $NAMESPACE
Check-PodStatus -Deployment "postgres" -Namespace $NAMESPACE
Write-Host ""

# Check API deployment
Write-Host "Checking API application..." -ForegroundColor Yellow
Check-Resource -ResourceType "deployment" -ResourceName "yellowbook-api" -Namespace $NAMESPACE
Check-Resource -ResourceType "service" -ResourceName "yellowbook-api-service" -Namespace $NAMESPACE
Check-PodStatus -Deployment "yellowbook-api" -Namespace $NAMESPACE
Write-Host ""

# Check Web deployment
Write-Host "Checking Web application..." -ForegroundColor Yellow
Check-Resource -ResourceType "deployment" -ResourceName "yellowbook-web" -Namespace $NAMESPACE
Check-Resource -ResourceType "service" -ResourceName "yellowbook-web-service" -Namespace $NAMESPACE
Check-PodStatus -Deployment "yellowbook-web" -Namespace $NAMESPACE
Write-Host ""

# Check HPA
Write-Host "Checking Horizontal Pod Autoscalers..." -ForegroundColor Yellow
Check-Resource -ResourceType "hpa" -ResourceName "yellowbook-api-hpa" -Namespace $NAMESPACE
Check-Resource -ResourceType "hpa" -ResourceName "yellowbook-web-hpa" -Namespace $NAMESPACE

Write-Host ""
Write-Host "HPA Status:" -ForegroundColor Cyan
kubectl get hpa -n $NAMESPACE
Write-Host ""

# Check Ingress
Write-Host "Checking Ingress..." -ForegroundColor Yellow
Check-Resource -ResourceType "ingress" -ResourceName "yellowbook-ingress" -Namespace $NAMESPACE
Write-Host ""

# Get Ingress URL
Write-Host "Ingress Details:" -ForegroundColor Cyan
$INGRESS_HOST = kubectl get ingress yellowbook-ingress -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>$null
if (-not $INGRESS_HOST) { $INGRESS_HOST = "pending" }
Write-Host "Load Balancer: $INGRESS_HOST"
Write-Host ""

# Check if migration job completed
Write-Host "Checking migration job..." -ForegroundColor Yellow
$JOB_STATUS = kubectl get job yellowbook-migration -n $NAMESPACE -o jsonpath='{.status.conditions[?(@.type=="Complete")].status}' 2>$null

if ($JOB_STATUS -eq "True") {
    Write-Success "Migration job completed successfully"
} elseif (-not $JOB_STATUS) {
    Write-Warning "Migration job not found (may have been cleaned up)"
} else {
    Write-Error "Migration job not completed"
    Write-Host "Check migration logs: kubectl logs job/yellowbook-migration -n $NAMESPACE" -ForegroundColor Yellow
}
Write-Host ""

# Check RBAC
Write-Host "Checking RBAC resources..." -ForegroundColor Yellow
Check-Resource -ResourceType "serviceaccount" -ResourceName "yellowbook-deployer" -Namespace $NAMESPACE
Check-Resource -ResourceType "role" -ResourceName "yellowbook-deployer-role" -Namespace $NAMESPACE
Check-Resource -ResourceType "rolebinding" -ResourceName "yellowbook-deployer-binding" -Namespace $NAMESPACE
Write-Host ""

# List all pods
Write-Host "All Pods in namespace:" -ForegroundColor Cyan
kubectl get pods -n $NAMESPACE
Write-Host ""

# Check pod health
Write-Host "Pod Health Details:" -ForegroundColor Yellow
$UNHEALTHY_PODS = @(kubectl get pods -n $NAMESPACE --field-selector=status.phase!=Running --no-headers 2>$null).Count
if ($UNHEALTHY_PODS -eq 0) {
    Write-Success "All pods are running"
} else {
    Write-Error "$UNHEALTHY_PODS unhealthy pod(s) found"
    kubectl get pods -n $NAMESPACE --field-selector=status.phase!=Running
}
Write-Host ""

# Check AWS Load Balancer Controller
Write-Host "Checking AWS Load Balancer Controller..." -ForegroundColor Yellow
$LBC_RUNNING = kubectl get deployment aws-load-balancer-controller -n kube-system -o jsonpath='{.status.readyReplicas}' 2>$null
if ($LBC_RUNNING -and [int]$LBC_RUNNING -gt 0) {
    Write-Success "AWS Load Balancer Controller is running"
} else {
    Write-Error "AWS Load Balancer Controller not found"
}
Write-Host ""

# Check External DNS
Write-Host "Checking External DNS..." -ForegroundColor Yellow
$EXTDNS_RUNNING = kubectl get deployment external-dns -n kube-system -o jsonpath='{.status.readyReplicas}' 2>$null
if ($EXTDNS_RUNNING -and [int]$EXTDNS_RUNNING -gt 0) {
    Write-Success "External DNS is running"
} else {
    Write-Warning "External DNS not found"
}
Write-Host ""

# Check Metrics Server
Write-Host "Checking Metrics Server..." -ForegroundColor Yellow
$METRICS_RUNNING = kubectl get deployment metrics-server -n kube-system -o jsonpath='{.status.readyReplicas}' 2>$null
if ($METRICS_RUNNING -and [int]$METRICS_RUNNING -gt 0) {
    Write-Success "Metrics Server is running"
    Write-Host ""
    Write-Host "Node Metrics:" -ForegroundColor Cyan
    kubectl top nodes 2>$null
    Write-Host ""
    Write-Host "Pod Metrics:" -ForegroundColor Cyan
    kubectl top pods -n $NAMESPACE 2>$null
} else {
    Write-Error "Metrics Server not found (required for HPA)"
}
Write-Host ""

# Test endpoints (if ingress is ready)
if ($INGRESS_HOST -ne "pending") {
    Write-Host "Testing endpoints..." -ForegroundColor Yellow
    
    # Get domain names from ingress
    $DOMAINS = kubectl get ingress yellowbook-ingress -n $NAMESPACE -o jsonpath='{.spec.rules[*].host}'
    
    Write-Host "Configured domains: $DOMAINS" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "To test your deployment:" -ForegroundColor Yellow
    foreach ($domain in $DOMAINS -split ' ') {
        Write-Host "  curl -k https://$domain"
    }
    Write-Host ""
    Write-Host "Note: DNS propagation may take a few minutes" -ForegroundColor Yellow
}
Write-Host ""

# Recent events
Write-Host "Recent Events:" -ForegroundColor Cyan
kubectl get events -n $NAMESPACE --sort-by='.lastTimestamp' | Select-Object -Last 10
Write-Host ""

# Summary
Write-Host "===================================================================" -ForegroundColor Cyan
Write-Host "Validation Summary" -ForegroundColor Cyan
Write-Host "===================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Verify HTTPS access: https://your-domain.com"
Write-Host "2. Check for padlock in browser"
Write-Host "3. Take screenshots for submission:"
Write-Host "   - Browser with HTTPS padlock"
Write-Host "   - kubectl get pods -n $NAMESPACE"
Write-Host "   - GitHub Actions workflow run"
Write-Host ""
Write-Host "For detailed logs:" -ForegroundColor Cyan
Write-Host "  kubectl logs -f deployment/yellowbook-api -n $NAMESPACE"
Write-Host "  kubectl logs -f deployment/yellowbook-web -n $NAMESPACE"
Write-Host ""
Write-Host "To check HPA scaling:" -ForegroundColor Cyan
Write-Host "  kubectl get hpa -n $NAMESPACE -w"
Write-Host ""
Write-Host "===================================================================" -ForegroundColor Cyan
