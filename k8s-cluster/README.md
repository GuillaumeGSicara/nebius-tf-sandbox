# vLLM on Nebius Managed Kubernetes

Second way to consume Nebius GPUs: instead of administering a virtual machine (`tf/base`), vLLM runs as a container on a GPU **node group** (the group of GPU machines that Nebius creates and keeps for the cluster) of a **Managed Kubernetes** cluster. Same GPU as the VM blueprint (B300), same model, same project.

This blueprint is a functional test, not a benchmark. The goal is to learn what Nebius provides and what stays with the customer.


## What is created

| Element | Detail |
|---|---|
| `tf/cluster` | One Managed Kubernetes cluster (control plane run by Nebius, 1 etcd) and one GPU node group (default: 1 node, `gpu-b300-sxm`, `1gpu-24vcpu-346gb`, spot). |
| `k8s/` | Namespace `vllm`, a PVC for the weights, a Deployment (1 pod, 1 GPU), a ClusterIP Service, and an optional private load balancer. |
| `scripts/` | `chat.sh` (API test), `hardware-report.sh` (hardware, same output as on the VM), `cluster-report.sh` (what Nebius preinstalls). |

Differences from the VM blueprint:
- No storage layer: the weights live on a **PVC** (`compute-csi-default-sc`, Network SSD, dynamic). **The weights do not survive deletion of the PVC**, unlike the persistent disk of the VM, which `tf:destroy` keeps.
- No SSH: access goes through the Kubernetes API (`kubectl`).
- vLLM is started by Kubernetes (and restarted if the pod dies), not by hand.

## Prerequisites

- Terraform >= 1.5, [Task](https://taskfile.dev), `kubectl`, `jq`.
- The `nebius` CLI, only for `kubectl` access (Terraform does not need it): `brew install --cask nebius` or `curl -sSL https://artifacts.nebius.cloud/cli/install.sh | bash`. Use a **service account profile**, with the same `NEBIUS_SA_*` as Terraform (no browser login): `task nebius:profile`. The task reads the `.env` and never prints the private key.
- The `.env` of the repository root (project, subnet, service account), same as the VM blueprint.
- **GPU quota**: "Total NVIDIA B300 GPUs for regular VMs without reservations" is 0 by default in `uk-south1`. Check it in the console (Administration > Limits > Quotas) or with `nebius quotas quota-allowance list --parent-id <id>`, and request an increase. Also check the "Preemptible VMs" quota (spot). Which quota counts for spot B300 is not confirmed.
- The subnet must be in the region of the project. Region of this test: **`uk-south1`** (the project of the VM). The `region` variable only checks it against the project: the plan fails on mismatch.

## Deploy

```bash
cd k8s-cluster
cp tf/cluster/terraform.tfvars.example tf/cluster/terraform.tfvars   # set allowed_cidrs to your IP, as /32
task tf:init
task tf:validate
task tf:plan
task tf:apply            # BILLED. Creates the cluster and the GPU node (a few minutes).
task nebius:profile      # once: CLI profile from the NEBIUS_SA_* of the .env
task kubeconfig          # writes ~/.kube/config (public endpoint)
task cluster:report      # what Nebius provides: versions, add-ons, storage classes
task k8s:apply
task k8s:wait            # first start: image pull + ~15 GB download, up to 30 min
```

Extra Terraform flags go after `--`, for example `task tf:apply -- -var node_count=2` or `-var preemptible=false` (on-demand).

## Verify

```bash
task k8s:status
task chat -- "Say hello in one sentence."      # answer printed after the JSON
task hw                                        # nvidia-smi, topology, CPU, RAM, disks of the pod
task k8s:restart                               # deletes the pod, Kubernetes recreates it; weights stay on the PVC
task tf:apply -- -var node_count=2             # second node. The pod stays on one node (1 replica, RWO disk).
```

To compare with the VM, run the same script there: `ssh <vm> 'sh -s' < scripts/hardware-report.sh`. In a pod, `lscpu` and `/proc/meminfo` show the whole node; the "cgroup limits" section shows what the pod may use. Run the same model on the VM: `vllm serve Qwen/Qwen2.5-7B-Instruct`.

Private load balancer (optional): `task k8s:lb`, then `kubectl -n vllm get svc vllm-internal` for its address. It is an address inside the VPC, not reachable from your laptop. Its cost is not documented.

## Clean up

```bash
task k8s:delete          # deletes the workload and the PVC (the weights disk is deleted)
task tf:destroy          # deletes the node group and the cluster
```

Delete the workload first: the load balancer and the PVC disk are created by Kubernetes, outside Terraform. Terraform does not delete them. Check the console for orphan disks and load balancers afterwards.

## Who operates what

| Layer | Nebius | Customer |
|---|---|---|
| Kubernetes control plane (API, etcd, scheduler) | Operated and upgraded by Nebius. | Chooses the version and the etcd size. |
| Node machines (GPU VM, OS image) | Image with GPU drivers (`drivers_preset`), node creation, auto repair (setting available). | Chooses platform, preset, count, disk. Pays for every node. |
| Node upgrades | Provides new node images and versions. | Triggers and schedules them (strategy, surge, drain). |
| GPU drivers | Preinstalled with `drivers_preset` (`cuda13.0` here). | Picks the preset. Without a preset, installs the NVIDIA GPU Operator. |
| GPU device plugin, CSI, CNI, DNS | Not itemised in the docs. See `task cluster:report` for the real list. | To check. |
| Block storage | CSI driver and `compute-csi-default-sc` (Network SSD, one node at a time). | Sizes PVCs, backs up weights, owns their lifecycle. |
| Load balancer | Creates it from a Service. `nebius.com/load-balancer-type: internal` makes it private. | Chooses internal or public. Default without annotation is public. |
| Kubernetes API access | Public endpoint with `allowed_cidrs`, or private endpoint. | Restricts it. See the production note. |
| Workload (vLLM image, model, args, probes, resources) | Nothing. | Everything. |
| Observability, logs, alerts | To check. | Cluster and workload monitoring. |
| Security of the workload (RBAC, network policies, secrets, images) | Platform and IAM. | RBAC, network policies, secrets, image provenance. |
| IAM, quotas, billing | Provides them. | Configures them. |

## What Terraform exposes for kubectl

Outputs `public_endpoint`, `private_endpoint` and `cluster_ca_certificate` give the API address and the cluster CA. Terraform does **not** give an access token: kubectl needs one, which the `nebius` CLI provides (`nebius mk8s cluster get-credentials` writes a kubeconfig that uses your Nebius credentials; the exact mechanism is not verified).

## Notes

- **Production (BNPP)**: use the private endpoint (`public_endpoint = false`). The API is then reachable only from inside the network. Plan for access through IPsec or an interconnect from the on-premises network, and keep the AI gateway as the only caller of vLLM. The public endpoint with `allowed_cidrs` is only a test shortcut.
- **Private connectivity**: Nebius documents a VM-based IPsec gateway (Nebius VPN Gateway: AWS, Azure, GCP and Cisco IOS peers documented). A Cloud Interconnect offer is not confirmed in the docs: ask Nebius.
- **Region**: `eu-west2` (France) is a separate test, if BNPP requires French residency. It needs a project and a subnet in `eu-west2` and B300 quota there (`gpu-b300-sxm` is listed in `uk-south1`, `eu-west2` and `us-north1`).
- **Spot**: spot is the default, as for the VM. If the apply fails because of spot on node groups, set `preemptible = false` (on-demand).
- **Image**: `vllm/vllm-openai:v0.34.0` is pinned. Hypothesis: it works with the `cuda13.0` driver on B300. If the pod fails with a CUDA error, try another tag.
- **Two nodes**: with one replica and a RWO disk, the second node stays idle. Scaling vLLM to two nodes needs two replicas, and each needs its own weights (a second PVC, a shared filesystem or a download per pod).
