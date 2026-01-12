# Troubleshooting Guide

This document describes common issues encountered during the project and their solutions.

## Issue 1: Backend Service Connection Failure

### Symptom
```bash
kubectl run curl-test --image=curlimages/curl --rm -it --restart=Never -- curl -s http://quotes:8080/quotes
# Returns: pod terminated (Error)
```

### Root Cause
The container image `quay.io/donschenck/quotes` listens on **port 10000**, not 8080 as documented.

### Diagnosis
```bash
# Check actual listening port
kubectl logs -l app=quotes
# Output: Listening at: http://0.0.0.0:10000
```

### Solution
Update the Service to use correct `targetPort`:
```yaml
spec:
  ports:
    - port: 8080        # External port (what clients use)
      targetPort: 10000 # Actual container port
```

---

## Issue 2: Frontend Route Returns "Application not available"

### Symptom
Accessing `https://quotesweb-xxx.apps.openshiftapps.com` shows OpenShift error page.

### Root Cause
Route missing TLS configuration. OpenShift router expects TLS termination settings.

### Diagnosis
```bash
kubectl get route quotesweb -o yaml | grep -A5 tls
# If empty, TLS is not configured
```

### Solution
Recreate route with TLS:
```bash
kubectl delete route quotesweb
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
    targetPort: http
  tls:
    termination: edge
    insecureEdgeTerminationPolicy: Redirect
EOF
```

---

## Issue 3: Database Pod ErrImagePull

### Symptom
```bash
kubectl get pods
# mysql-xxx   0/1   ErrImagePull   0   1m
```

### Root Cause
Red Hat registry images require authentication:
- `registry.access.redhat.com/rhscl/mariadb-103-rhel7` may not be accessible

### Solution
Use Docker Hub image instead:
```yaml
containers:
  - name: mariadb
    image: docker.io/mariadb:10.5  # Public image
    env:
      - name: MARIADB_ROOT_PASSWORD  # Note: MARIADB_ not MYSQL_
        valueFrom:
          secretKeyRef:
            name: mysqlpassword
            key: password
```

---

## Issue 4: Frontend Can't Reach Backend

### Symptom
Frontend loads but clicking "Start" shows no quotes.

### Root Cause
1. Backend route not created
2. Wrong URL entered in frontend
3. CORS issues (if applicable)

### Diagnosis
```bash
# Check if backend route exists
kubectl get route quotes

# Test backend externally
BACKEND_URL=$(kubectl get route quotes -o jsonpath='{.spec.host}')
curl -s "https://${BACKEND_URL}/quotes/random"
```

### Solution
1. Create backend route (see `quotes-route.yaml`)
2. Use correct URL format: `https://quotes-xxx.apps.openshiftapps.com/quotes/random`

---

## Issue 5: Database Connection from Backend v2

### Symptom
Backend v2 crashes with database connection error.

### Diagnosis
```bash
kubectl logs -l app=quotes
# Look for: "Connection refused" or "Unknown host"
```

### Solution
1. Ensure MySQL service exists:
```bash
kubectl get svc mysql
```

2. Set environment variable:
```bash
kubectl set env deployment/quotes DB_SERVICE_NAME=mysql
```

3. Verify backend can reach database:
```bash
kubectl exec -it $(kubectl get pod -l app=quotes -o jsonpath='{.items[0].metadata.name}') -- \
  python -c "import socket; socket.create_connection(('mysql', 3306)); print('OK')"
```

---

## Useful Debug Commands

```bash
# View all resources
kubectl get all

# Check pod status and events
kubectl describe pod <pod-name>

# View logs
kubectl logs <pod-name>
kubectl logs -l app=quotes --tail=50

# Test internal connectivity
kubectl run curl-test --image=curlimages/curl --rm -it --restart=Never -- \
  curl -sv http://quotes:8080/quotes/random

# Port-forward for local testing
kubectl port-forward svc/quotes 8080:8080
# Then: curl localhost:8080/quotes/random

# Check endpoints (Service → Pod mapping)
kubectl get endpoints

# Exec into pod
kubectl exec -it <pod-name> -- /bin/sh
```

---

## Key Learnings

1. **Always verify actual ports** - Don't trust documentation blindly
2. **TLS is required** - OpenShift routes need explicit TLS configuration
3. **Use public images** - Red Hat registry requires authentication
4. **Environment variables differ** - `MYSQL_*` vs `MARIADB_*` depending on image
5. **Service discovery works** - Use service names (`mysql:3306`) not IPs
