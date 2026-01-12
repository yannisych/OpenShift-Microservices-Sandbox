# 🚀 Kubernetes Microservices on OpenShift Developer Sandbox

A hands-on learning project deploying a complete 3-tier microservices application on Red Hat OpenShift Developer Sandbox using pure Kubernetes manifests.

![Kubernetes](https://img.shields.io/badge/kubernetes-%23326ce5.svg?style=for-the-badge&logo=kubernetes&logoColor=white)
![OpenShift](https://img.shields.io/badge/OpenShift-EE0000?style=for-the-badge&logo=red-hat-open-shift&logoColor=white)
![Python](https://img.shields.io/badge/python-3670A0?style=for-the-badge&logo=python&logoColor=ffdd54)
![React](https://img.shields.io/badge/react-%2320232a.svg?style=for-the-badge&logo=react&logoColor=%2361DAFB)
![MariaDB](https://img.shields.io/badge/MariaDB-003545?style=for-the-badge&logo=mariadb&logoColor=white)

## 📋 Table of Contents

- [Project Overview](#-project-overview)
- [Architecture](#-architecture)
- [Prerequisites](#-prerequisites)
- [Quick Start](#-quick-start)
- [Step-by-Step Tutorial](#-step-by-step-tutorial)
- [Troubleshooting](#-troubleshooting)
- [Kubernetes Concepts Learned](#-kubernetes-concepts-learned)
- [Screenshots](#-screenshots)
- [Cleanup](#-cleanup)
- [What I Learned](#-what-i-learned)
- [References](#-references)

## 🎯 Project Overview

This project deploys a **Quote of the Day** application consisting of:

| Component | Technology | Description |
|-----------|------------|-------------|
| **Frontend** | React.js | Web UI displaying random quotes |
| **Backend** | Python Flask | REST API serving quotes |
| **Database** | MariaDB | Persistent storage for quotes |

### Key Features Demonstrated

- ✅ Kubernetes Deployments with rolling updates
- ✅ Services (ClusterIP) for internal communication
- ✅ Routes (OpenShift) for external HTTPS access
- ✅ Secrets for credential management
- ✅ PersistentVolumeClaims for data persistence
- ✅ Horizontal scaling (replicas)
- ✅ Self-healing capabilities
- ✅ Rolling updates (v1 → v2)

## 🏗 Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              INTERNET                                       │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                     OpenShift Router (HAProxy)                              │
│                         TLS Termination                                     │
└─────────────────────────────────────────────────────────────────────────────┘
                          │                    │
                          ▼                    ▼
              ┌──────────────────┐   ┌──────────────────┐
              │   Route:         │   │   Route:         │
              │   quotesweb      │   │   quotes         │
              │   (HTTPS)        │   │   (HTTPS)        │
              └────────┬─────────┘   └────────┬─────────┘
                       │                      │
                       ▼                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                          KUBERNETES CLUSTER                                 │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │                         NAMESPACE: openstack-yy-dev                 │    │
│  │                                                                     │    │
│  │   ┌─────────────────┐        ┌─────────────────┐                    │    │
│  │   │  Service:       │        │  Service:       │                    │    │
│  │   │  quotesweb      │        │  quotes         │                    │    │
│  │   │  ClusterIP:3000 │        │  ClusterIP:8080 │                    │    │
│  │   └────────┬────────┘        └────────┬────────┘                    │    │
│  │            │                          │                             │    │
│  │            ▼                          ▼                             │    │
│  │   ┌─────────────────┐        ┌─────────────────┐                    │    │
│  │   │  Deployment:    │        │  Deployment:    │                    │    │
│  │   │  quotesweb      │        │  quotes         │                    │    │
│  │   │  ┌───────────┐  │        │  ┌───────────┐  │                    │    │
│  │   │  │  Pod      │  │        │  │  Pod (x3) │  │                    │    │
│  │   │  │  React    │  │───────▶│  │  Python   │  │                   │     │
│  │   │  │  :3000    │  │  HTTP  │  │  :10000   │  │                    │    │
│  │   │  └───────────┘  │        │  └───────────┘  │                    │    │
│  │   └─────────────────┘        └────────┬────────┘                    │    │
│  │                                       │                             │    │
│  │                                       │ MySQL Protocol              │    │ 
│  │                                       ▼                             │    │
│  │                              ┌─────────────────┐                    │    │
│  │                              │  Service:       │                    │    │
│  │                              │  mysql          │                    │    │
│  │                              │  ClusterIP:3306 │                    │    │
│  │                              └────────┬────────┘                    │    │
│  │                                       │                             │    │
│  │                                       ▼                             │    │
│  │                              ┌─────────────────┐                    │    │
│  │                              │  Deployment:    │                    │    │
│  │                              │  mysql          │                    │    │
│  │                              │  ┌───────────┐  │                    │    │
│  │                              │  │  Pod      │  │                    │    │
│  │                              │  │  MariaDB  │  │                    │    │
│  │                              │  │  :3306    │  │                    │    │
│  │                              │  └─────┬─────┘  │                    │    │
│  │                              └────────┼────────┘                    │    │
│  │                                       │                             │    │
│  │                                       ▼                             │    │
│  │                              ┌─────────────────┐                    │    │
│  │                              │  PVC:           │                    │    │
│  │                              │  mysqlvolume    │                    │    │
│  │                              │  5Gi Storage    │                    │    │
│  │                              └─────────────────┘                    │    │
│  │                                                                     │    │
│  │   ┌─────────────────┐                                               │    │
│  │   │  Secret:        │                                               │    │
│  │   │  mysqlpassword  │◀── Referenced by mysql & quotes deployments  │    │
│  │   └─────────────────┘                                               |    │
│  │                                                                     │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Data Flow

1. **User** → Browser accesses `https://quotesweb-xxx.apps.openshiftapps.com`
2. **OpenShift Router** → Terminates TLS, forwards to `quotesweb` Service
3. **Frontend Pod** → React app makes API call to `https://quotes-xxx.apps.openshiftapps.com/quotes/random`
4. **Backend Pod** → Python Flask queries MariaDB via `mysql` Service
5. **Database Pod** → Returns quote data from `quotesdb` database
6. **Response** → Quote displayed in browser with hostname (load balancing proof)

## 📦 Prerequisites

- **Operating System**: Debian 13 (Trixie) or any Linux distribution
- **Red Hat Account**: Free account at [developers.redhat.com](https://developers.redhat.com)
- **Developer Sandbox**: Access at [developers.redhat.com/developer-sandbox](https://developers.redhat.com/developer-sandbox)

### Required Tools

| Tool | Version | Purpose |
|------|---------|---------|
| `kubectl` | Latest | Kubernetes CLI |
| `oc` | 4.x | OpenShift CLI |
| `git` | Any | Clone repositories |
| `curl` | Any | Testing endpoints |

## 🚀 Quick Start

```bash
# 1. Clone this repository
git clone https://github.com/yannisych/OpenShift-Microservices-Sandbox
cd OpenShift-Microservices-Sandbox

# 2. Install CLI tools
./scripts/01-install-prerequisites.sh

# 3. Login to OpenShift (get token from Developer Sandbox console)
oc login --token=sha256~YOUR_TOKEN --server=https://api.sandbox-xxx.openshiftapps.com:6443

# 4. Deploy the application
./scripts/02-deploy-application.sh

# 5. Access the application
kubectl get routes
```

## 📖 Step-by-Step Tutorial

### Phase 1: Environment Setup

#### 1.1 Install kubectl

```bash
# Download latest stable version
KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)
curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"

# Verify checksum (security best practice)
curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl.sha256"
echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check

# Install
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
kubectl version --client
```

#### 1.2 Install OpenShift CLI (oc)

```bash
curl -LO "https://mirror.openshift.com/pub/openshift-v4/clients/ocp/stable/openshift-client-linux.tar.gz"
tar -xvf openshift-client-linux.tar.gz
sudo mv oc /usr/local/bin/
oc version --client
```

#### 1.3 Configure Shell Completion

```bash
echo 'source <(kubectl completion bash)' >> ~/.bashrc
echo 'source <(oc completion bash)' >> ~/.bashrc
echo 'alias k=kubectl' >> ~/.bashrc
source ~/.bashrc
```

### Phase 2: Connect to OpenShift Developer Sandbox

1. Go to [Developer Sandbox](https://developers.redhat.com/developer-sandbox)
2. Click **"Start your sandbox for free"**
3. In the OpenShift console, click your username → **"Copy login command"**
4. Click **"Display Token"**
5. Copy the `oc login` command and run it:

```bash
oc login --token=sha256~xxxxx --server=https://api.sandbox-xxx.openshiftapps.com:6443
```

Verify connection:

```bash
oc whoami                    # Your username
oc whoami --show-server      # API server URL
oc project                   # Your namespace
```

### Phase 3: Clone Source Repositories

```bash
mkdir -p ~/kubernetes-sandbox-project/src
cd ~/kubernetes-sandbox-project/src

# Backend - Python Flask API
git clone https://github.com/redhat-developer-demos/qotd-python.git

# Frontend - React Web App
git clone https://github.com/redhat-developer-demos/quotesweb.git

# Database - SQL scripts
git clone https://github.com/redhat-developer-demos/quotemysql.git
```

### Phase 4: Deploy Backend (quotes)

#### 4.1 Create Deployment

```bash
cd ~/kubernetes-sandbox-project/src/qotd-python/k8s
kubectl apply -f quotes-deployment.yaml
```

#### 4.2 Create Service

```bash
kubectl apply -f quotes-service.yaml
```

> ⚠️ **IMPORTANT BUG FIX**: The backend container listens on port **10000**, not 8080!

```bash
# Verify the actual port
kubectl logs -l app=quotes
# Output: Listening at: http://0.0.0.0:10000
```

Fix the service to use correct targetPort:

```bash
kubectl delete svc quotes
cat << 'EOF' | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: quotes
  labels:
    app: quotes
spec:
  type: ClusterIP
  selector:
    app: quotes
  ports:
    - port: 8080
      targetPort: 10000
      name: http
EOF
```

#### 4.3 Create Route (External Access)

```bash
cat << 'EOF' | kubectl apply -f -
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  name: quotes
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
```

#### 4.4 Test Backend

```bash
# Get the route URL
QUOTES_URL=$(kubectl get route quotes -o jsonpath='{.spec.host}')
curl -s "https://${QUOTES_URL}/quotes/random" | jq
```

### Phase 5: Deploy Frontend (quotesweb)

```bash
cd ~/kubernetes-sandbox-project/src/quotesweb/k8s

# Deploy all frontend resources
kubectl apply -f quotesweb-deployment.yaml
kubectl apply -f quotesweb-service.yaml
```

Create Route with TLS:

```bash
kubectl delete route quotesweb 2>/dev/null
cat << 'EOF' | kubectl apply -f -
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  name: quotesweb
spec:
  to:
    kind: Service
    name: quotesweb
  port:
    targetPort: 3000-tcp
  tls:
    termination: edge
    insecureEdgeTerminationPolicy: Redirect
EOF
```

Access the frontend:

```bash
kubectl get route quotesweb -o jsonpath='{.spec.host}'
# Open in browser: https://quotesweb-xxx.apps.openshiftapps.com
```

### Phase 6: Deploy Database (MariaDB)

```bash
cd ~/kubernetes-sandbox-project/src/quotemysql

# Create PVC
kubectl create -f mysqlvolume.yaml

# Create Secret
kubectl create -f mysql-secret.yaml

# Deploy MariaDB
kubectl create -f mysql-deployment.yaml

# Create Service
kubectl create -f mysql-service.yaml

# Wait for pod to be ready
kubectl get pods -w
```

#### 6.1 Populate Database

```bash
# Get pod name
export PODNAME=$(kubectl get pods -o go-template --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}' | grep 'mysql')

# Create database
kubectl cp ./create_database_quotesdb.sql $PODNAME:/tmp/create_database_quotesdb.sql
kubectl cp ./create_database.sh $PODNAME:/tmp/create_database.sh
kubectl exec deploy/mysql -- /bin/bash ./tmp/create_database.sh

# Create tables
kubectl cp ./create_table_quotes.sql $PODNAME:/tmp/create_table_quotes.sql
kubectl cp ./create_tables.sh $PODNAME:/tmp/create_tables.sh
kubectl exec deploy/mysql -- /bin/bash ./tmp/create_tables.sh

# Populate data
kubectl cp ./populate_table_quotes_BASH.sql $PODNAME:/tmp/populate_table_quotes_BASH.sql
kubectl cp ./quotes.csv $PODNAME:/tmp/quotes.csv
kubectl cp ./populate_tables_BASH.sh $PODNAME:/tmp/populate_tables_BASH.sh
kubectl exec deploy/mysql -- /bin/bash ./tmp/populate_tables_BASH.sh

# Verify data
kubectl cp ./query_table_quotes.sql $PODNAME:/tmp/query_table_quotes.sql
kubectl cp ./query_table_quotes.sh $PODNAME:/tmp/query_table_quotes.sh
kubectl exec deploy/mysql -- /bin/bash ./tmp/query_table_quotes.sh
```

### Phase 7: Update Backend to v2 (Database Connection)

```bash
# Set environment variable for database service name
kubectl set env deployment/quotes DB_SERVICE_NAME=mysql

# Update image to v2
kubectl set image deploy quotes quotes=quay.io/donschenck/quotes:v2

# Watch the rolling update
kubectl get pods -w
```

### Phase 8: Test Scaling

```bash
# Scale to 3 replicas
kubectl scale deployment/quotes --replicas=3

# Verify
kubectl get pods -l app=quotes

# Watch different hostnames in the frontend!
```

## 🐛 Troubleshooting

### Issue 1: Backend Service Returns Error

**Symptom**: `curl http://quotes:8080` fails

**Cause**: Container listens on port 10000, not 8080

**Solution**:
```bash
# Check actual port in logs
kubectl logs -l app=quotes
# Fix: Update service targetPort to 10000
```

### Issue 2: Frontend Route Returns "Application not available"

**Symptom**: HTTPS route returns OpenShift error page

**Cause**: Missing TLS configuration on route

**Solution**:
```bash
# Recreate route with TLS
kubectl delete route quotesweb
kubectl apply -f - <<EOF
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  name: quotesweb
spec:
  to:
    kind: Service
    name: quotesweb
  port:
    targetPort: 3000-tcp
  tls:
    termination: edge
EOF
```

### Issue 3: Database Image Pull Error

**Symptom**: Pod stuck in `ErrImagePull` or `ImagePullBackOff`

**Cause**: Red Hat registry image requires authentication

**Solution**: Use Docker Hub image instead:
```yaml
image: docker.io/mariadb:10.5
```

### Issue 4: Frontend Can't Reach Backend

**Symptom**: Frontend loads but no quotes appear

**Cause**: Backend route not created or wrong URL

**Solution**:
```bash
# Ensure backend route exists
kubectl get route quotes

# Use correct URL format in frontend:
# https://quotes-xxx.apps.openshiftapps.com/quotes/random
```

## 📚 Kubernetes Concepts Learned

| Concept | What I Learned |
|---------|----------------|
| **Deployment** | Manages desired state of pods, handles rolling updates |
| **Service** | Provides stable network endpoint for pods (ClusterIP) |
| **Route** | OpenShift-specific ingress for external HTTPS access |
| **Secret** | Securely stores sensitive data (passwords, tokens) |
| **PVC** | Requests persistent storage that survives pod restarts |
| **Labels & Selectors** | How Kubernetes links resources together |
| **Rolling Update** | Zero-downtime deployments with `kubectl set image` |
| **Scaling** | Horizontal scaling with `kubectl scale` |
| **Self-Healing** | Kubernetes automatically restarts failed pods |
| **Port Mapping** | `port` vs `targetPort` vs `containerPort` |

## 📸 Screenshots

Screenshots are available in the `screenshots/` directory:

1. `01-frontend-v1.png` - Initial frontend deployment (backend v1 with hardcoded quotes)
2. `02-openshift-dashboard.png` - OpenShift Developer Console topology view
3. `03-api-token.png` - API token authentication page
4. `04-quotes-deployment.png` - Backend deployment details and configuration
5. `05-database-setup.png` - Database creation and data population
6. `06-secrets.png` - Kubernetes Secrets management in console
7. `07-frontend-manifests.png` - Frontend YAML manifest files
8. `08-final-pods.png` - All pods running successfully in console
9. `09-pods-running.png` - Terminal output showing all running pods
10. `10-scaling.png` - Horizontal pod scaling demonstration
11. `11-frontend-v2-database.png` - Final application with database integration (backend v2)

## 🧹 Cleanup

```bash
# Remove all resources with the learn-kubernetes label
kubectl delete all -l sandbox=learn-kubernetes

# Or remove individually
kubectl delete deployment quotes quotesweb mysql
kubectl delete service quotes quotesweb mysql
kubectl delete route quotes quotesweb
kubectl delete pvc mysqlvolume
kubectl delete secret mysqlpassword
```

## 💡 What I Learned

1. **Port Configuration is Critical**: Always verify which port your container actually listens on using `kubectl logs`. The documented port may differ from reality.

2. **TLS Termination Matters**: OpenShift routes need explicit TLS configuration for HTTPS to work properly.

3. **Service Discovery**: Kubernetes DNS allows pods to communicate using service names (e.g., `mysql:3306`).

4. **Secrets Management**: Never hardcode passwords. Use Kubernetes Secrets and reference them in deployments.

5. **Rolling Updates**: Kubernetes handles zero-downtime deployments automatically with proper configuration.

6. **Debugging Workflow**:
   - Check pod status: `kubectl get pods`
   - View logs: `kubectl logs <pod>`
   - Describe resources: `kubectl describe <resource>`
   - Test connectivity: `kubectl run curl-test --image=curlimages/curl --rm -it -- curl <url>`

## 📚 References

- [Red Hat Developer Sandbox](https://developers.redhat.com/developer-sandbox)
- [Learn Kubernetes using Developer Sandbox](https://developers.redhat.com/learning/learn:openshift:learn-kubernetes-using-developer-sandbox)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [OpenShift Documentation](https://docs.openshift.com/)

## 📝 License

This project is for educational purposes. Based on the Red Hat Developer tutorial.

See [LICENSE](./LICENSE) file for details.
