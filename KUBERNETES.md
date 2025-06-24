# Kubernetes Deployment Guide

This guide explains how to deploy the beam-messenger Phoenix application to Kubernetes.

## Prerequisites

- Kubernetes cluster (minikube, kind, or cloud provider)
- kubectl configured to access your cluster
- Docker for building images
- Elixir/Phoenix development environment

## Quick Start

### 1. Generate Secret Key

First, generate a secret key base for your Phoenix application:

```bash
mix phx.gen.secret
```

Copy the output and base64 encode it:

```bash
echo "YOUR_SECRET_KEY_HERE" | base64
```

### 2. Update Secrets

Edit `k8s/secrets.yaml` and replace the `secret-key-base` value with your base64-encoded secret:

```yaml
data:
  secret-key-base: YOUR_BASE64_ENCODED_SECRET_HERE
```

### 3. Build Docker Image

Build and tag the Docker image:

```bash
docker build -t beam-messenger:latest .
```

### 4. Deploy to Kubernetes

Deploy all manifests using kustomize:

```bash
kubectl apply -k k8s/
```

Or apply individual files:

```bash
kubectl apply -f k8s/storage.yaml
kubectl apply -f k8s/secrets.yaml
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
```

### 5. Access the Application

Add the following line to your `/etc/hosts` file:

```
127.0.0.1 beam-messenger.local
```

Then access the application at: http://beam-messenger.local

## Kubernetes Resources

### Deployment (`k8s/deployment.yaml`)
- Runs 2 replicas of the Phoenix application
- Configures environment variables for production
- Mounts persistent storage for SQLite database
- Includes health checks and resource limits

### Service & Ingress (`k8s/service.yaml`)
- ClusterIP service exposing port 80
- Nginx ingress for external access
- Routes traffic to `beam-messenger.local`

### Storage (`k8s/storage.yaml`)
- 5GB persistent volume for SQLite database
- Uses local storage class
- Mounted at `/app/data` in the container

### Secrets (`k8s/secrets.yaml`)
- Stores Phoenix secret key base
- Must be updated with your actual secret

### Kustomization (`k8s/kustomization.yaml`)
- Manages all resources together
- Adds common labels and metadata

## Scaling

Scale the deployment:

```bash
kubectl scale deployment beam-messenger --replicas=3
```

## Monitoring

Check deployment status:

```bash
kubectl get pods -l app=beam-messenger
kubectl logs -l app=beam-messenger
```

## Database Migration

Run migrations inside a pod:

```bash
kubectl exec -it deployment/beam-messenger -- /app/bin/messenger eval "Messenger.Release.migrate"
```

## Cleanup

Remove all resources:

```bash
kubectl delete -k k8s/
```

## Production Considerations

1. **Database**: Consider using PostgreSQL instead of SQLite for production
2. **Secrets**: Use external secret management (HashiCorp Vault, AWS Secrets Manager)
3. **Storage**: Use cloud storage classes for better reliability
4. **Ingress**: Configure TLS/SSL certificates
5. **Monitoring**: Add Prometheus monitoring and logging
6. **Resource Limits**: Adjust CPU/memory based on actual usage