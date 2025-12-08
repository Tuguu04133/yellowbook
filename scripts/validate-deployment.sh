#!/bin/bash
# Validation script for Yellowbook EKS deployment
# This script checks if all required components are deployed and working

set -e

NAMESPACE="yellowbooks"
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "==================================================================="
echo "Yellowbook Deployment Validation"
echo "==================================================================="
echo ""

# Function to check if resource exists
check_resource() {
    local resource_type=$1
    local resource_name=$2
    local namespace=$3
    
    if [ -z "$namespace" ]; then
        kubectl get $resource_type $resource_name &>/dev/null
    else
        kubectl get $resource_type $resource_name -n $namespace &>/dev/null
    fi
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓${NC} $resource_type/$resource_name exists"
        return 0
    else
        echo -e "${RED}✗${NC} $resource_type/$resource_name not found"
        return 1
    fi
}

# Function to check pod status
check_pod_status() {
    local deployment=$1
    local namespace=$2
    
    local ready=$(kubectl get deployment $deployment -n $namespace -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
    local desired=$(kubectl get deployment $deployment -n $namespace -o jsonpath='{.spec.replicas}' 2>/dev/null || echo "0")
    
    if [ "$ready" -eq "$desired" ] && [ "$ready" -gt 0 ]; then
        echo -e "${GREEN}✓${NC} Deployment/$deployment: $ready/$desired pods ready"
        return 0
    else
        echo -e "${RED}✗${NC} Deployment/$deployment: $ready/$desired pods ready"
        return 1
    fi
}

# Check if namespace exists
echo "Checking namespace..."
check_resource namespace $NAMESPACE
echo ""

# Check ConfigMap and Secret
echo "Checking configuration..."
check_resource configmap yellowbook-config $NAMESPACE
check_resource secret yellowbook-secrets $NAMESPACE
echo ""

# Check PostgreSQL
echo "Checking PostgreSQL..."
check_resource deployment postgres $NAMESPACE
check_resource service postgres-service $NAMESPACE
check_resource pvc postgres-pvc $NAMESPACE
check_pod_status postgres $NAMESPACE
echo ""

# Check API deployment
echo "Checking API application..."
check_resource deployment yellowbook-api $NAMESPACE
check_resource service yellowbook-api-service $NAMESPACE
check_pod_status yellowbook-api $NAMESPACE
echo ""

# Check Web deployment
echo "Checking Web application..."
check_resource deployment yellowbook-web $NAMESPACE
check_resource service yellowbook-web-service $NAMESPACE
check_pod_status yellowbook-web $NAMESPACE
echo ""

# Check HPA
echo "Checking Horizontal Pod Autoscalers..."
check_resource hpa yellowbook-api-hpa $NAMESPACE
check_resource hpa yellowbook-web-hpa $NAMESPACE

# Show HPA status
echo ""
echo "HPA Status:"
kubectl get hpa -n $NAMESPACE
echo ""

# Check Ingress
echo "Checking Ingress..."
check_resource ingress yellowbook-ingress $NAMESPACE
echo ""

# Get Ingress URL
echo "Ingress Details:"
INGRESS_HOST=$(kubectl get ingress yellowbook-ingress -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "pending")
echo "Load Balancer: $INGRESS_HOST"
echo ""

# Check if migration job completed
echo "Checking migration job..."
JOB_STATUS=$(kubectl get job yellowbook-migration -n $NAMESPACE -o jsonpath='{.status.conditions[?(@.type=="Complete")].status}' 2>/dev/null || echo "NotFound")

if [ "$JOB_STATUS" == "True" ]; then
    echo -e "${GREEN}✓${NC} Migration job completed successfully"
elif [ "$JOB_STATUS" == "NotFound" ]; then
    echo -e "${YELLOW}!${NC} Migration job not found (may have been cleaned up)"
else
    echo -e "${RED}✗${NC} Migration job not completed"
    echo "Check migration logs: kubectl logs job/yellowbook-migration -n $NAMESPACE"
fi
echo ""

# Check RBAC
echo "Checking RBAC resources..."
check_resource serviceaccount yellowbook-deployer $NAMESPACE
check_resource role yellowbook-deployer-role $NAMESPACE
check_resource rolebinding yellowbook-deployer-binding $NAMESPACE
echo ""

# List all pods
echo "All Pods in namespace:"
kubectl get pods -n $NAMESPACE
echo ""

# Check pod health
echo "Pod Health Details:"
UNHEALTHY_PODS=$(kubectl get pods -n $NAMESPACE --field-selector=status.phase!=Running --no-headers 2>/dev/null | wc -l)
if [ "$UNHEALTHY_PODS" -eq 0 ]; then
    echo -e "${GREEN}✓${NC} All pods are running"
else
    echo -e "${RED}✗${NC} $UNHEALTHY_PODS unhealthy pod(s) found"
    kubectl get pods -n $NAMESPACE --field-selector=status.phase!=Running
fi
echo ""

# Check AWS Load Balancer Controller
echo "Checking AWS Load Balancer Controller..."
LBC_RUNNING=$(kubectl get deployment aws-load-balancer-controller -n kube-system -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
if [ "$LBC_RUNNING" -gt 0 ]; then
    echo -e "${GREEN}✓${NC} AWS Load Balancer Controller is running"
else
    echo -e "${RED}✗${NC} AWS Load Balancer Controller not found"
fi
echo ""

# Check External DNS
echo "Checking External DNS..."
EXTDNS_RUNNING=$(kubectl get deployment external-dns -n kube-system -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
if [ "$EXTDNS_RUNNING" -gt 0 ]; then
    echo -e "${GREEN}✓${NC} External DNS is running"
else
    echo -e "${YELLOW}!${NC} External DNS not found"
fi
echo ""

# Check Metrics Server
echo "Checking Metrics Server..."
METRICS_RUNNING=$(kubectl get deployment metrics-server -n kube-system -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
if [ "$METRICS_RUNNING" -gt 0 ]; then
    echo -e "${GREEN}✓${NC} Metrics Server is running"
    echo ""
    echo "Node Metrics:"
    kubectl top nodes 2>/dev/null || echo "Metrics not available yet"
    echo ""
    echo "Pod Metrics:"
    kubectl top pods -n $NAMESPACE 2>/dev/null || echo "Metrics not available yet"
else
    echo -e "${RED}✗${NC} Metrics Server not found (required for HPA)"
fi
echo ""

# Test endpoints (if ingress is ready)
if [ "$INGRESS_HOST" != "pending" ]; then
    echo "Testing endpoints..."
    
    # Get domain names from ingress
    DOMAINS=$(kubectl get ingress yellowbook-ingress -n $NAMESPACE -o jsonpath='{.spec.rules[*].host}')
    
    echo "Configured domains: $DOMAINS"
    echo ""
    echo "To test your deployment:"
    for domain in $DOMAINS; do
        echo "  curl -k https://$domain"
    done
    echo ""
    echo "Note: DNS propagation may take a few minutes"
fi

# Recent events
echo "Recent Events:"
kubectl get events -n $NAMESPACE --sort-by='.lastTimestamp' | tail -10
echo ""

# Summary
echo "==================================================================="
echo "Validation Summary"
echo "==================================================================="
echo ""
echo "Next steps:"
echo "1. Verify HTTPS access: https://your-domain.com"
echo "2. Check for padlock in browser"
echo "3. Take screenshots for submission:"
echo "   - Browser with HTTPS padlock"
echo "   - kubectl get pods -n $NAMESPACE"
echo "   - GitHub Actions workflow run"
echo ""
echo "For detailed logs:"
echo "  kubectl logs -f deployment/yellowbook-api -n $NAMESPACE"
echo "  kubectl logs -f deployment/yellowbook-web -n $NAMESPACE"
echo ""
echo "To check HPA scaling:"
echo "  kubectl get hpa -n $NAMESPACE -w"
echo ""
echo "==================================================================="
