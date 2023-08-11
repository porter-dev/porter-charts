# LogDNA

[LogDNA](https://logdna.com) - Easy, beautiful logging in the cloud.

## Introduction

This chart deploys LogDNA collector agents to all nodes in your cluster. Logs will ship from all containers.
We extract pertinent Kubernetes metadata: pod name, container name, container id, namespace, labels, and annotations.
View your logs at https://app.logdna.com or live tail using our [CLI](https://github.com/logdna/logdna-cli).

## Prerequisites

- Kubernetes 1.11.10+

## Installing the Chart

Please follow directions from https://app.logdna.com/pages/add-source to obtain your LogDNA Ingestion Key.

To install the chart with the release name `my-release`:

```bash
$ helm repo add logdna https://assets.logdna.com/charts
$ helm install --set logdna.key=LOGDNA_INGESTION_KEY my-release logdna/agent
```

You should see logs in https://app.logdna.com in a few seconds.

### Tags support:
```bash
$ helm install --set logdna.key=LOGDNA_INGESTION_KEY,logdna.tags=production my-release logdna/agent
```

## Uninstalling the Chart

To uninstall/delete the `my-release` deployment:

```bash
$ helm uninstall my-release
```

The command removes all the Kubernetes components associated with the chart and deletes the release.

## Configuration

The following tables lists the configurable parameters of the LogDNA Agent chart and their default values.

Parameter | Description | Default
--- | --- | ---
`daemonset.tolerations` | List of node taints to tolerate | `[]`
`daemonset.updateStrategy` | Optionally set an update strategy on the daemonset. | None
`image.pullPolicy` | Image pull policy | `IfNotPresent`
`logdna.key` | LogDNA Ingestion Key (Required) | None
`logdna.tags` | Optional tags such as `production` | None
`priorityClassName` | (Optional) Set a PriorityClass on the Daemonset | `""`
`resources.limits.memory` | Memory resource limits |500Mi
`updateOnSecretChange` | Optionally set annotation on daemonset to cause deploy when secret changes | None
`extraEnv` | Additional environment variables | `{}`
`extraVolumeMounts` | Additional Volume mounts | `[]`
`extraVolumes` | Additional Volumes | `[]`
`serviceAccount.create` | Whether to create a service account for this release | `true`
`serviceAccount.name` | The name of the service account. Defaults to `logdna-agent` unless `serviceAccount.create=false` in which case it defaults to `default` | None

Specify each parameter using the `--set key=value[,key=value]` argument to `helm install`. For example,

```bash
$ helm install --set logdna.key=LOGDNA_INGESTION_KEY,logdna.tags=production my-release logdna/agent
```

Alternatively, a YAML file that specifies the values for the above parameters can be provided while installing the
chart. For example,

```bash
$ helm install -f values.yaml my-release logdna/agent
```
