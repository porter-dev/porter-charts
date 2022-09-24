# Porter Charts

This repository contains [Helm charts](https://helm.sh/) that are offered on [Porter](https://github.com/porter-dev/porter) as application templates or add-ons. 

## Applications vs Add-Ons

The [`/applications`](/applications) folder contains templates that are used to deploy your applications onto Porter. Porter currently offers three types of application templates: web, worker, and job templates. Please [read the docs](https://docs.porter.run/deploying-addons/overview) for more info. 

The [`/addons`](/addons) folder contains templates for deploying everything that is not application source code: databases, logging/monitoring agents, SSL cert managers, etc.

## Bugs and Feature Requests

If chart-specific bugs are encountered while using Porter, or you would like a certain a chart to support a new feature, please file this in [issues](https://github.com/porter-dev/porter-charts/issues).

## Add-On Requests

If you would like Porter to support a specific add-on, please reach out to us on [Discord](https://discord.gg/mmGAw5nNjr) first. We may already be planning on working on this chart, or it may not be feasible to support this specific add-on.

## Contributing 

We welcome all contributors! Consult the [contributing guide](CONTRIBUTING.md) to understand the contributing process. 

> **Note:** please file an issue or comment on an existing issue to be assigned. **Only start working on the issue once assigned**. 
