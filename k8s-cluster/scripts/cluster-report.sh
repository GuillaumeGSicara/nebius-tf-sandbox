#!/usr/bin/env bash
# What Nebius provides in the cluster: versions, nodes, preinstalled components, storage.
set -uo pipefail
section() { printf '\n===== %s =====\n' "$1"; }

section "kubernetes version"
kubectl version
section "nodes (OS, kernel, runtime)"
kubectl get nodes -o wide
section "node labels and GPU resources"
kubectl get nodes -o json | jq -r '.items[] | .metadata.name, (.metadata.labels | to_entries[] | select(.key|test("nebius|nvidia|node.kubernetes.io/instance-type|topology")) | "  \(.key)=\(.value)"), "  allocatable: \(.status.allocatable | tojson)"'
section "all pods (preinstalled components: GPU plugin, CSI, CNI, DNS...)"
kubectl get pods -A -o wide
section "daemonsets and deployments in system namespaces"
kubectl get ds,deploy -A
section "storage classes"
kubectl get storageclass
section "CSI drivers"
kubectl get csidrivers
section "runtime classes"
kubectl get runtimeclass
section "gpu operator?"
kubectl get ns | grep -iE 'gpu|nvidia' || echo "(no gpu/nvidia namespace)"
