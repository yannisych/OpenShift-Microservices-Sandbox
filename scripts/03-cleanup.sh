#!/bin/bash
#===============================================================================
# Script: 03-cleanup.sh
# Description: Remove all deployed resources
#===============================================================================

set -e

echo "=============================================="
echo "  Cleanup - Remove All Resources"
echo "=============================================="
echo ""

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() { echo -e "${GREEN}[✓]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[!]${NC} $1"; }

# Confirm
read -p "Are you sure you want to delete all resources? (y/N): " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
fi

echo ""
echo ">>> Removing deployments..."
kubectl delete deployment quotes quotesweb mysql 2>/dev/null || true

echo ""
echo ">>> Removing services..."
kubectl delete service quotes quotesweb mysql 2>/dev/null || true

echo ""
echo ">>> Removing routes..."
kubectl delete route quotes quotesweb 2>/dev/null || true

echo ""
echo ">>> Removing PVC..."
kubectl delete pvc mysqlvolume 2>/dev/null || true

echo ""
echo ">>> Removing secrets..."
kubectl delete secret mysqlpassword 2>/dev/null || true

echo ""
echo ">>> Remaining resources:"
kubectl get all -l sandbox=learn-kubernetes 2>/dev/null || echo "None"

echo ""
print_status "Cleanup complete!"
