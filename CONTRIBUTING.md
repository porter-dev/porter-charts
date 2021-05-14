# Contributing to Porter Charts

First off, thanks for considering contributing to Porter's chart repo! Before you contribute, make sure to read these guidelines thoroughly, so that you can get your pull request reviewed and finalized as quickly as possible.

## Overview

Porter charts are simply [Helm charts](https://helm.sh/) that contain a custom `form.yaml` file. When a chart is deployed on Porter, the following process takes place:

1. The application and addon chart repositories are sent to the Porter dashboard, displaying the latest versions of each chart. 
2. A user clicks into a chart, and the `README.md` file is rendered to explain what the chart does. There is also a version selector, so that the user can select which version of the chart to deploy. 
3. The user clicks the "Launch Template" button, which renders what the `form.yaml` instructs. Each input component in the `form.yaml` file maps to a Helm value in `values.yaml`. 
4. The user clicks the "Deploy" button, which uses the `form.yaml` file to construct a set of Helm values. These are the values that the Helm chart is deployed with. 

Before getting started, it is recommended that you get the Porter server up and running in development mode on your local desktop. Please see the [contributing guide](https://github.com/porter-dev/porter/blob/master/CONTRIBUTING.md#getting-started) in the Porter main repo for instructions. It is also recommended that you are somewhat familiar with Kubernetes resources and Helm charts. 

To get a better sense of the `form.yaml` file, please see the [reference documentation](/docs/form-yaml-reference.md). 

## Developing 

To develop the Helm chart itself, please consult the [Helm documentation](https://helm.sh/docs/chart_template_guide/). We recommend frequently running `helm install --dry-run testing .` to ensure the manifests are rendering as expected. 

Once you are ready to develop the `form.yaml` file and test the chart from the Porter dashboard, ensure that you have the Porter server running in development mode ([instructions](https://github.com/porter-dev/porter/blob/master/CONTRIBUTING.md#getting-started)) with the following `.env` set:

First, in `/dashboard/.env`:

```
HELM_APP_REPO_URL=http://chartmuseum:8080
HELM_ADD_ON_REPO_URL=http://chartmuseum:8080
```

Next, in `/docker/.env`:

```
APPLICATION_CHART_REPO_URL=http://chartmuseum:8080
ADDON_CHART_REPO_URL=http://chartmuseum:8080
```

You will need to restart `docker-compose` for these changes to take effect. 

### Developing `form.yaml` 

On the Porter dashboard, navigate to the "Dashboard" tab and hit the keys `CMD + k + z` at the same time. This will create a preview `form.yaml` environment. You can develop your `form.yaml` file here. Once this is complete, save this file to `form.yaml` in your chart's directory. 

### Testing the Chart

Finally, to test the chart, make sure that the version of the chart is set in `Chart.yaml`, and create `[porterchart]-[version].tgz` using the Helm CLI by running the following command from the chart directory:

```sh
helm package .
```

Then upload this file to the local version of [`ChartMuseum`](https://github.com/helm/chartmuseum) that runs with the `docker-compose` Porter stack:

```
curl --data-binary "@[porterchart]-[version].tgz" http://localhost:5000/api/charts
```

If you navigate to the Porter dashboard, and click "Launch," you should see your chart in the list of charts. 

> **Note:** To delete versions and re-apply, see the full [ChartMuseum API](https://github.com/helm/chartmuseum#api). 

## Making the PR

Make a PR to `master` and request [**@abelanger5**](https://github.com/abelanger5) to review your PR. To test your changes, they may be merged into the `dev` branch, which will upload the changes to the development chart repo, hosted at `charts.dev.getporter.dev` and `chart-addons.dev.getporter.dev`. After your PR is merged into `master`, it will be merged into `staging` and eventually `production` as soon as possible. Changes to charts automatically increment the minor version of the chart, but this can be overriden for breaking changes. 
