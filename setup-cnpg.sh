#!/usr/bin/env bash

set -e

helm upgrade --install --wait --timeout 35m --atomic --namespace cnpg --create-namespace  \
  --repo https://cloudnative-pg.github.io/charts cnpg cloudnative-pg --values - <<EOF
monitoring:
  podMonitorEnabled: true
  grafanaDashboard:
    create: true
EOF

kubectl create namespace app || true

kubectl create secret generic app-user-creds -n app \
  --from-literal=username=app_user \
  --from-literal=password=MySecurePassword123

cat << EOF | kubectl apply -f -
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: my-postgres-cluster
  namespace: app
spec:
  instances: 3
  bootstrap:
    initdb:
      database: app_db
      owner: app_user
      secret:
        name: app-user-creds
  storage:
    size: 1Gi
EOF

cat << EOF | kubectl apply -f -
apiVersion: monitoring.coreos.com/v1
kind: PodMonitor
metadata:
  name: my-postgres-cluster
  namespace: app
spec:
  selector:
    matchLabels:
      cnpg.io/cluster: my-postgres-cluster
  podMetricsEndpoints:
  - port: metrics
EOF