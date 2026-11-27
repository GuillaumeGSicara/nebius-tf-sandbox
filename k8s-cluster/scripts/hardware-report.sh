#!/bin/sh
# Hardware report, same output on the VM and in a GPU pod, to compare them.
#   Pod: kubectl -n vllm exec -i deploy/vllm -- sh -s < scripts/hardware-report.sh
#   VM:  ssh <vm> 'sh -s' < scripts/hardware-report.sh
# In a pod, lscpu and /proc/meminfo show the whole node; the cgroup section shows the pod limits.
section() { printf '\n===== %s =====\n' "$1"; }
run() { "$@" 2>&1 || echo "(failed: $*)"; }
have() { command -v "$1" >/dev/null 2>&1; }

section "host"
run uname -a
run grep -E '^(PRETTY_NAME|VERSION)=' /etc/os-release
hostname

section "nvidia-smi"
have nvidia-smi && run nvidia-smi || echo "(nvidia-smi not found)"

section "nvidia-smi gpu summary"
have nvidia-smi && run nvidia-smi --query-gpu=index,name,driver_version,memory.total,pci.bus_id --format=csv

section "nvidia-smi topo -m"
have nvidia-smi && run nvidia-smi topo -m

section "nvlink status"
have nvidia-smi && run nvidia-smi nvlink --status

section "cpu"
if have lscpu; then run lscpu; else run grep -E 'model name|processor' /proc/cpuinfo; fi
echo "nproc: $(nproc)"

section "memory"
run grep -E 'MemTotal|MemAvailable|SwapTotal' /proc/meminfo
have free && run free -h

section "cgroup limits (container view)"
for f in /sys/fs/cgroup/memory.max /sys/fs/cgroup/cpu.max /sys/fs/cgroup/memory/memory.limit_in_bytes; do
  [ -r "$f" ] && echo "$f: $(cat "$f")"
done

section "disks"
have lsblk && run lsblk -o NAME,SIZE,TYPE,MOUNTPOINT,MODEL
run df -hT -x tmpfs -x devtmpfs -x overlay 2>/dev/null || run df -h

section "mounts of interest"
run grep -E ' (/models|/mnt/models|/) ' /proc/mounts

section "shm"
run df -h /dev/shm
