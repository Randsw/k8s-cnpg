# Use CloudNative PG in Kubernetes

This guide details how to deploy **CloudNative-PG** as PostgreSQL database and deploy example application.

## Prerequisites

Ensure the following are installed and updated for 2026:

- **Docker** (Engine or Desktop)
- **kubectl**
- **Kind CLI**
- **Helm** (v3.x+)

---

## 1. Cluster Infrastructure Setup

Initialize the environment by running the setup script. This creates a multi-node cluster (1 Control Plane, 3 Workers) pre-configured with MetaLB (LoadBalancer support) and local image registries.

```bash
chmod +x ./cluster-setup.sh
./cluster-setup.sh
```

## 2. Deploy VictoriaMetrics Kubernetes stack with Grafana

Run `./setup-vms.sh`

### Get grafana password

Login - admin

Password:

`kubectl get secret --namespace victoria-metrics vm-grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo`

## 3. Deploy CloudNative-PG

Run `./setup-cnpg.sh`

## 4. Deploy example app

Run `kubectl apply -f app/k8s.yaml`

### Check application

Open in browser `http://app.kind.cluster`

Add test entry to database:

```sh
Team - Manchester United
Year - 1999
Manager - Alex Ferguson
```

and click `Save`.

Press `List` to show all entry in table.

### Check monitoring

- [Grafana](http://grafana.kind.cluster)

Check dashboard `CloudNativePG`.
