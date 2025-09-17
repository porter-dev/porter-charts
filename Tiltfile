load('ext://helm_resource', 'helm_resource', 'helm_repo')

## Setup ChartMuseum
helm_repo(
    'chartmuseum',
    'https://chartmuseum.github.io/charts',
    labels=['z_utils'],
    resource_name='helm-repo-chartmuseum'
)
helm_resource(
    name="chartmuseum",
    chart='chartmuseum/chartmuseum',
    port_forwards=["8888:8080"],
    labels=["z_infra"],
    namespace="default",
    flags=["--values", "zarf/helm/chartmuseum.yaml"],
)

# Setup ChartMuseum as local repo
local_resource(
  name='charts-setup-local-repo',
  cmd='''helm repo add local http://localhost:8888 && \
  helm repo update local
  ''',
  deps=[
    "applications",
    "addons"
  ],
  resource_deps=["chartmuseum"],
  labels=["chartmuseum"],
)

## Upload charts to chartmuseum
local_resource(
  name='charts-applications',
  cmd='''helm cm-push applications/web local && \
  helm cm-push applications/job local && \
  helm cm-push applications/worker local && \
  helm repo update local
  ''',
  deps=[
    "applications",
  ],
  resource_deps=["charts-setup-local-repo"],
  labels=["chartmuseum"],
)

local_resource(
  name='charts-addons',
  cmd='''helm cm-push addons/datadog local && \
  helm cm-push addons/tailscale-relay local && \
  helm cm-push addons/metabase local && \
  helm cm-push addons/elasticache-redis local && \
  helm cm-push addons/elasticsearch local && \
  helm cm-push addons/mongodb local && \
  helm cm-push addons/redis local && \
  helm cm-push addons/postgresql local && \
  helm cm-push addons/logdna local && \
  helm cm-push addons/cert-manager local && \
  helm cm-push addons/circleci-container-agent local && \
  helm cm-push addons/ecr-secrets-updater local && \
  helm cm-push addons/https-issuer local && \
  helm cm-push addons/keda local && \
  helm cm-push addons/local-dns-cache local && \
  helm cm-push addons/loki local && \
  helm cm-push addons/memcached local && \
  helm cm-push addons/n8n local && \
  helm cm-push addons/nri-bundle local && \
  helm cm-push addons/postgres-toolbox local && \
  helm cm-push addons/prometheus local && \
  helm cm-push addons/rabbitmq local && \
  helm cm-push addons/rds-postgresql local && \
  helm cm-push addons/rds-postgresql-aurora local && \
  helm cm-push addons/wallarm-ingress local && \
  helm cm-push addons/postgresql-managed local && \
  helm cm-push addons/redis-managed local && \
  helm cm-push addons/deepgram local && \
  helm cm-push addons/hf-llm-models local && \
  helm cm-push addons/keda-http-add-on local && \
  helm cm-push addons/kube-image-keeper local && \
  helm cm-push addons/prometheus-adapter local && \
  helm cm-push addons/langfuse local && \
  helm cm-push addons/grafana local && \
  helm cm-push addons/porter-agent local && \
  helm cm-push addons/karpenter local && \
  helm cm-push addons/tailscale-operator local && \
  helm cm-push addons/persistent-disk local && \
  helm repo update local
  ''',
  deps=[
    "addons",
  ],
  resource_deps=["charts-setup-local-repo"],
  labels=["chartmuseum"],
)
