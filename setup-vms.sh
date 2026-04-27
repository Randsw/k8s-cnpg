#!/usr/bin/env bash

set -e

kubectl create namespace victoria-metrics || true

helm upgrade --install --wait --timeout 35m --atomic --namespace victoria-metrics \
  --repo https://prometheus-community.github.io/helm-charts prometheus-crd prometheus-operator-crds

helm upgrade --install --wait --timeout 35m --atomic --namespace victoria-metrics --create-namespace  \
  --repo https://victoriametrics.github.io/helm-charts vm victoria-metrics-k8s-stack --values - <<EOF
victoria-metrics-operator:
  createCRD: true
vmsingle:
  enabled: true
  ingress:
    enabled: true
    hosts:
      - single.kind.cluster
    ingressClassName: istio
vmagent:
  ingress:
    enabled: true
    hosts:
      - agent.kind.cluster
    ingressClassName: istio
alertmanager:
  enabled: true
  ingress:
    enabled: true
    ingressClassName: istio
    hosts:
      - alertmanager.kind.cluster
grafana:
  enabled: true
  sidecar:
    datasources:
      searchNamespace: ALL
    dashboards:
      searchNamespace: ALL
  ingress:
    enabled: true
    ingressClassName: istio
    hosts:
        - grafana.kind.cluster
  plugins:
    - victoriametrics-metrics-datasource
kubeEtcd:
  enabled: true
  service:
    # -- Enable service for ETCD metrics scraping
    enabled: true
    # -- ETCD service port
    port: 2381
    # -- ETCD service target port
    targetPort: 2381
    # -- ETCD service pods selector
    selector:
      component: etcd
  vmScrape:
    enabled: true
    # spec for VMServiceScrape crd 
    # https://github.com/VictoriaMetrics/operator/blob/master/docs/api.MD#vmservicescrapespec
    spec:
      jobLabel: jobLabel
      endpoints:
        - bearerTokenFile: /var/run/secrets/kubernetes.io/serviceaccount/token
          # bearerTokenSecret:
          #   key: ""
          port: http-metrics
          scheme: http
          tlsConfig:
            caFile: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
            insecureSkipVerify: true
kubeScheduler:
  enabled: true
  vmScrape:
    enabled: true
    # spec for VMServiceScrape crd 
    # https://github.com/VictoriaMetrics/operator/blob/master/docs/api.MD#vmservicescrapespec
    spec:
      jobLabel: jobLabel
      endpoints:
        - bearerTokenFile: /var/run/secrets/kubernetes.io/serviceaccount/token
          # bearerTokenSecret:
          #   key: ""
          port: http-metrics
          scheme: https
          tlsConfig:
            caFile: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
            insecureSkipVerify: true
kubeControllerManager:
  enabled: true
  vmScrape:
    enabled: true
    # spec for VMServiceScrape crd 
    # https://github.com/VictoriaMetrics/operator/blob/master/docs/api.MD#vmservicescrapespec
    spec:
      jobLabel: jobLabel
      endpoints:
        - bearerTokenFile: /var/run/secrets/kubernetes.io/serviceaccount/token
          # bearerTokenSecret:
          #   key: ""
          port: http-metrics
          scheme: https
          tlsConfig:
            caFile: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
            insecureSkipVerify: true
            serverName: kubernetes
EOF