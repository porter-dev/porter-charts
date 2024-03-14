# LogDNA Kubernetes Agent

<a href="https://logdna.com" target="_blank">LogDNA</a> - Easy, beautiful logging in the cloud.

## Introduction

This chart deploys LogDNA collector agents to all nodes in your cluster. Logs will ship from all containers.
We extract pertinent Kubernetes metadata: pod name, container name, container id, namespace, labels, and annotations.
View your logs at <a href="https://app.logdna.com" target="_blank">https://app.logdna.com</a> or live tail using the <a href="https://github.com/logdna/logdna-cli" target="_blank">LogDNA CLI</a>.
