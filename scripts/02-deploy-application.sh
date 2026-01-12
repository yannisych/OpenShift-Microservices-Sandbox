#!/bin/bash
#===============================================================================
# Script: 02-deploy-application.sh
# Description: Deploy the complete 3-tier application to OpenShift
# Prerequisites: Must be logged in to OpenShift cluster (oc login)
#===============================================================================

set -e

echo "=============================================="
echo "  Kubernetes Microservices Deployment"
echo "=============================================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() { echo -e "${GREEN}[✓]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[!]${NC} $1"; }
print_error() { echo -e "${RED}[✗]${NC} $1"; }
print_info() { echo -e "${BLUE}[i]${NC} $1"; }

# Check cluster connection
check_connection() {
    echo ">>> Checking cluster connection..."
    if ! oc whoami &>/dev/null; then
        print_error "Not logged in to OpenShift cluster"
        echo "    Run: oc login --token=<token> --server=<server>"
        exit 1
    fi
    print_status "Connected as: $(oc whoami)"
    print_status "Server: $(oc whoami --show-server)"
    print_status "Project: $(oc project -q)"
    echo ""
}

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Deploy Backend
deploy_backend() {
    echo ">>> Deploying Backend (quotes)..."
    
    # Create deployment
    cat << 'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: quotes
  labels:
    app: quotes
    sandbox: learn-kubernetes
spec:
  replicas: 1
  selector:
    matchLabels:
      app: quotes
  template:
    metadata:
      labels:
        app: quotes
    spec:
      containers:
        - name: quotes
          image: quay.io/donschenck/quotes:v1
          imagePullPolicy: Always
          ports:
            - containerPort: 10000
          resources:
            requests:
              memory: "128Mi"
              cpu: "100m"
            limits:
              memory: "256Mi"
              cpu: "200m"
EOF
    
    # Create service (note: targetPort is 10000!)
    cat << 'EOF' | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: quotes
  labels:
    app: quotes
    sandbox: learn-kubernetes
spec:
  type: ClusterIP
  selector:
    app: quotes
  ports:
    - port: 8080
      targetPort: 10000
      name: http
EOF
    
    # Create route
    cat << 'EOF' | kubectl apply -f -
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  name: quotes
  labels:
    app: quotes
    sandbox: learn-kubernetes
spec:
  to:
    kind: Service
    name: quotes
  port:
    targetPort: http
  tls:
    termination: edge
    insecureEdgeTerminationPolicy: Redirect
EOF
    
    kubectl rollout status deployment/quotes --timeout=120s
    print_status "Backend deployed"
}

# Deploy Frontend
deploy_frontend() {
    echo ""
    echo ">>> Deploying Frontend (quotesweb)..."
    
    # Create deployment
    cat << 'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: quotesweb
  labels:
    app: quotesweb
    sandbox: learn-kubernetes
spec:
  replicas: 1
  selector:
    matchLabels:
      app: quotesweb
  template:
    metadata:
      labels:
        app: quotesweb
    spec:
      containers:
        - name: quotesweb
          image: quay.io/rhdevelopers/quotesweb:v1
          imagePullPolicy: Always
          ports:
            - containerPort: 3000
          resources:
            requests:
              memory: "128Mi"
              cpu: "100m"
            limits:
              memory: "256Mi"
              cpu: "200m"
EOF
    
    # Create service
    cat << 'EOF' | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: quotesweb
  labels:
    app: quotesweb
    sandbox: learn-kubernetes
spec:
  type: ClusterIP
  selector:
    app: quotesweb
  ports:
    - port: 3000
      targetPort: 3000
      name: http
EOF
    
    # Create route with TLS
    cat << 'EOF' | kubectl apply -f -
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  name: quotesweb
  labels:
    app: quotesweb
    sandbox: learn-kubernetes
spec:
  to:
    kind: Service
    name: quotesweb
  port:
    targetPort: http
  tls:
    termination: edge
    insecureEdgeTerminationPolicy: Redirect
EOF
    
    kubectl rollout status deployment/quotesweb --timeout=120s
    print_status "Frontend deployed"
}

# Deploy Database
deploy_database() {
    echo ""
    echo ">>> Deploying Database (MariaDB)..."
    
    # Create PVC
    cat << 'EOF' | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mysqlvolume
  labels:
    sandbox: learn-kubernetes
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
EOF
    
    # Create Secret
    cat << 'EOF' | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: mysqlpassword
  labels:
    sandbox: learn-kubernetes
type: Opaque
data:
  password: YWRtaW4=
EOF
    
    # Create Deployment
    cat << 'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mysql
  labels:
    app: mysql
    sandbox: learn-kubernetes
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mysql
      tier: database
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        app: mysql
        tier: database
    spec:
      containers:
        - name: mariadb
          image: docker.io/mariadb:10.5
          ports:
            - containerPort: 3306
          env:
            - name: MARIADB_ROOT_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: mysqlpassword
                  key: password
          volumeMounts:
            - name: mysqlvolume
              mountPath: /var/lib/mysql
          resources:
            requests:
              memory: "256Mi"
              cpu: "200m"
            limits:
              memory: "512Mi"
              cpu: "500m"
      volumes:
        - name: mysqlvolume
          persistentVolumeClaim:
            claimName: mysqlvolume
EOF
    
    # Create Service
    cat << 'EOF' | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: mysql
  labels:
    app: mysql
    sandbox: learn-kubernetes
spec:
  type: ClusterIP
  selector:
    app: mysql
    tier: database
  ports:
    - port: 3306
      targetPort: 3306
EOF
    
    echo "    Waiting for MariaDB to be ready..."
    kubectl rollout status deployment/mysql --timeout=180s
    sleep 10
    print_status "Database deployed"
}

# Initialize database
init_database() {
    echo ""
    echo ">>> Initializing database..."
    
    PODNAME=$(kubectl get pods -l app=mysql -o jsonpath='{.items[0].metadata.name}')
    
    # Create database and table
    kubectl exec $PODNAME -- mysql -uroot -padmin -e "
        CREATE DATABASE IF NOT EXISTS quotesdb;
        USE quotesdb;
        CREATE TABLE IF NOT EXISTS quotes (
            id INT AUTO_INCREMENT PRIMARY KEY,
            quotation VARCHAR(500) NOT NULL,
            author VARCHAR(100) NOT NULL
        );
        INSERT INTO quotes (quotation, author) VALUES
        ('Yeah, well, that''s just like, your opinion, man.', 'The Dude'),
        ('It is not only what you do but also the attitude you bring to it, that makes you a success.', 'Don Schenck'),
        ('Knowledge is power.', 'Sir Francis Bacon'),
        ('Life is really simple, but we insist on making it complicated.', 'Confucius'),
        ('This above all: To thine own self be true.', 'William Shakespeare'),
        ('I got a fever, and the only prescription is more cowbell.', 'Will Ferrell'),
        ('Anyone who has ever made anything of importance was disciplined.', 'Andrew Hendrixson'),
        ('Strive not to be a success, but rather to be of value.', 'Albert Einstein'),
        ('The greatest glory in living lies not in never falling, but in rising every time we fall.', 'Nelson Mandela'),
        ('The way to get started is to quit talking and begin doing.', 'Walt Disney'),
        ('Your time is limited so don''t waste it living someone else''s life.', 'Steve Jobs'),
        ('If life were predictable it would cease to be life, and be without flavor.', 'Eleanor Roosevelt'),
        ('If you look at what you have in life you''ll always have more.', 'Oprah Winfrey'),
        ('If you set your goals ridiculously high, and it''s a failure, you will fail above everyone else''s success.', 'James Cameron'),
        ('Life is what happens when you''re busy making other plans.', 'John Lennon'),
        ('The best and most beautiful things in the world cannot be seen or even touched - they must be felt with the heart.', 'Helen Keller');
    "
    
    print_status "Database initialized with 16 quotes"
}

# Upgrade to v2
upgrade_to_v2() {
    echo ""
    echo ">>> Upgrading backend to v2 (database connection)..."
    
    kubectl set env deployment/quotes DB_SERVICE_NAME=mysql
    kubectl set image deployment/quotes quotes=quay.io/donschenck/quotes:v2
    kubectl rollout status deployment/quotes --timeout=120s
    
    print_status "Backend upgraded to v2"
}

# Display results
display_results() {
    echo ""
    echo "=============================================="
    echo "  Deployment Complete!"
    echo "=============================================="
    echo ""
    
    FRONTEND_URL=$(kubectl get route quotesweb -o jsonpath='{.spec.host}')
    BACKEND_URL=$(kubectl get route quotes -o jsonpath='{.spec.host}')
    
    print_info "Frontend URL: https://${FRONTEND_URL}"
    print_info "Backend URL:  https://${BACKEND_URL}/quotes/random"
    echo ""
    print_warning "In the frontend, enter the backend URL to start:"
    echo "    https://${BACKEND_URL}/quotes/random"
    echo ""
    
    echo "Resources created:"
    kubectl get pods
    echo ""
    kubectl get services
    echo ""
    kubectl get routes
}

# Main
main() {
    check_connection
    deploy_backend
    deploy_frontend
    deploy_database
    init_database
    upgrade_to_v2
    display_results
}

main "$@"
