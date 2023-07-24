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
    flags=["--values", "zarf/helm/chartmuseum.yaml"]
)

# Setup ChartMuseum as local repo
local_resource(
  name='charts-setup-local-repo',
  cmd='''helm repo add local http://localhost:8888 && \
  helm repo update local
  ''',
  deps=[
    "applications",
  ],
  resource_deps=["chartmuseum"]
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
  resource_deps=["charts-setup-local-repo"]
)