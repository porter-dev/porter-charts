# Node Local DNS Cache
** Currently only supported on EKS **

This installs a node local DNS cache in your cluster for faster DNS lookups per [this documentation](https://kubernetes.io/docs/tasks/administer-cluster/nodelocaldns/). 

## Motivation

During traffic spikes and heavy loads, CoreDNS (responsible for DNS resolution on clusters provisioned by Porter) may throw DNS lookup errors under too much load. This is a risk for languages like node.js that do not have a native caching mechanism in their DNS modules. This addon significantly reduces the load on CoreDNS by inserting a caching layer within each node.

## Implementation

The DNS cache addon is installed as a daemonset in every node of the cluster. Instead of directly making a request to coredns at all times, pods will send requests to the DNS cache pod that is running on the same node first to decrease lookup times. Listens on internal IP: `169.254.20.10`.

Support on GKE and DOKS is coming soon.