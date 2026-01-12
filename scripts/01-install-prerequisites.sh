#!/bin/bash
#===============================================================================
# Script: 01-install-prerequisites.sh
# Description: Install kubectl, oc CLI, and configure shell completion
# Platform: Debian/Ubuntu Linux
#===============================================================================

set -e

echo "=============================================="
echo "  Kubernetes CLI Tools Installation Script"
echo "=============================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

# Check if running as root or with sudo
check_sudo() {
    if [[ $EUID -ne 0 ]]; then
        print_warning "This script requires sudo privileges for installation"
        SUDO="sudo"
    else
        SUDO=""
    fi
}

# Update system packages
update_system() {
    echo ""
    echo ">>> Updating system packages..."
    $SUDO apt update && $SUDO apt upgrade -y
    $SUDO apt install -y curl wget git jq unzip ca-certificates gnupg
    print_status "System packages updated"
}

# Install kubectl
install_kubectl() {
    echo ""
    echo ">>> Installing kubectl..."
    
    # Get latest stable version
    KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)
    echo "    Latest version: ${KUBECTL_VERSION}"
    
    # Download kubectl
    curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
    
    # Download and verify checksum
    curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl.sha256"
    echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check
    
    # Install
    $SUDO install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    
    # Cleanup
    rm -f kubectl kubectl.sha256
    
    print_status "kubectl ${KUBECTL_VERSION} installed"
    kubectl version --client
}

# Install OpenShift CLI (oc)
install_oc() {
    echo ""
    echo ">>> Installing OpenShift CLI (oc)..."
    
    # Download latest stable oc
    curl -LO "https://mirror.openshift.com/pub/openshift-v4/clients/ocp/stable/openshift-client-linux.tar.gz"
    
    # Extract
    tar -xvf openshift-client-linux.tar.gz
    
    # Install
    $SUDO mv oc /usr/local/bin/
    $SUDO mv kubectl /usr/local/bin/ 2>/dev/null || true
    
    # Cleanup
    rm -f openshift-client-linux.tar.gz README.md
    
    print_status "OpenShift CLI installed"
    oc version --client
}

# Configure shell completion
configure_completion() {
    echo ""
    echo ">>> Configuring shell completion..."
    
    # kubectl completion
    if ! grep -q "kubectl completion bash" ~/.bashrc 2>/dev/null; then
        echo 'source <(kubectl completion bash)' >> ~/.bashrc
        print_status "kubectl completion added to .bashrc"
    fi
    
    # oc completion
    if ! grep -q "oc completion bash" ~/.bashrc 2>/dev/null; then
        echo 'source <(oc completion bash)' >> ~/.bashrc
        print_status "oc completion added to .bashrc"
    fi
    
    # kubectl alias
    if ! grep -q "alias k=kubectl" ~/.bashrc 2>/dev/null; then
        echo 'alias k=kubectl' >> ~/.bashrc
        echo 'complete -o default -F __start_kubectl k' >> ~/.bashrc
        print_status "kubectl alias 'k' added"
    fi
    
    print_status "Shell completion configured"
}

# Verify installation
verify_installation() {
    echo ""
    echo "=============================================="
    echo "  Installation Verification"
    echo "=============================================="
    
    echo ""
    echo "kubectl version:"
    kubectl version --client --short 2>/dev/null || kubectl version --client
    
    echo ""
    echo "oc version:"
    oc version --client
    
    echo ""
    print_status "All tools installed successfully!"
    echo ""
    print_warning "Run 'source ~/.bashrc' or open a new terminal to enable completion"
}

# Main execution
main() {
    check_sudo
    update_system
    install_kubectl
    install_oc
    configure_completion
    verify_installation
}

main "$@"
