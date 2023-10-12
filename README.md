# Porter Charts

This repository contains [Helm charts](https://helm.sh/) that are offered on [Porter](https://github.com/porter-dev/porter) as application templates or add-ons.

## Applications vs Add-Ons

The [`/applications`](/applications) folder contains templates that are used to deploy your applications onto Porter. Porter currently offers three types of application templates: web, worker, and job templates. Please [read the docs](https://docs.porter.run/deploying-addons/overview) for more info.

The [`/addons`](/addons) folder contains templates for deploying everything that is not application source code: databases, logging/monitoring agents, SSL cert managers, etc.

## Syncing a remote add-on

In order to add new charts to Porter's addon lists, you can sync a chart from a remote repository go to open the [sync charts workflow](porter-charts/.github/workflows/sync-remote-helm-charts.yaml) and add the following information to `.sync-chart.matrix.charts`. This will create a new PR for the remote chart which will be synced on a schedule.

```yaml
- remote_owner: aws
  remote_repository: eks-charts
  remote_directory: stable/aws-cloudwatch-metrics
  target_directory: addons/aws-cloudwatch-metrics
```

The above example will sync the `stable/aws-cloudwatch-metrics` folder from `aws/eks-charts` repo into our `addons/aws-cloudwatch-metrics` folder.

## Bugs and Feature Requests

If chart-specific bugs are encountered while using Porter, or you would like a certain a chart to support a new feature, please file this in [issues](https://github.com/porter-dev/porter-charts/issues).

## Contributing

We welcome all contributors! Consult the [contributing guide](CONTRIBUTING.md) to understand the contributing process.

> **Note:** please file an issue or comment on an existing issue to be assigned. **Only start working on the issue once assigned**.
