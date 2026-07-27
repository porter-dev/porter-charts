# sandbox-cilium

Cilium in aws-cni chaining mode, scoped to the sandbox node group. This is the
enforcement backend for sandbox egress allowlists when sandbox-api runs with
`SANDBOX_EGRESS_ENFORCEMENT=cilium`: instead of forcing restricted sandboxes
through the egress proxy, sandbox-api renders one CiliumNetworkPolicy per
restricted sandbox whose `toFQDNs` rules allow the sandbox's domains directly
at L3/L4, so non-HTTP clients (psql, ssh, raw TCP) work without proxy
awareness.

The upstream cilium chart is a dependency pinned in `Chart.yaml`,
digest-locked in `Chart.lock`, and vendored as a tgz under `charts/` like the
other addon dependencies; `values.yaml` holds the chaining preset. The VPC CNI keeps IPAM and routing on every node; Cilium's agent runs
only on nodes labeled `porter.run/workload-kind: sandbox` and attaches policy
enforcement there.

## Prerequisites

- AWS VPC CNI >= 1.11.2 (chaining compatibility floor).
- No Kubernetes NetworkPolicy may select a pod on the sandbox nodes. The VPC
  CNI's network policy agent stays enabled on the cluster, but it programs
  every pod a NetworkPolicy selects regardless of node, and two enforcers on
  one pod is unsupported by both AWS and Cilium. Policies over sandbox-node
  pods must be CiliumNetworkPolicies instead, which the agent ignores (the
  sandbox-api chart switches its own policies over when egressCilium is on).
- Pods running on sandbox nodes before the install keep their unchained
  networking (no policy enforcement) until restarted; drain or roll the warm
  pool after installing.

## Install

```sh
helm install sandbox-cilium charts/addons/sandbox-cilium -n kube-system
```

Then enable the backend on sandbox-api (`egressCilium.enabled` in the
sandbox-api chart).
