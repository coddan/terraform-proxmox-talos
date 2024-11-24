Forked and some stuff redone, and removed.
https://github.com/rgl/terraform-proxmox-talos/tree/main

to not need to work with policis in cilium, enable audit mode instead:
https://docs.cilium.io/en/latest/security/policy-creation/

To install all the tools needed, run the script in tools/tools.sh


# About

[![Lint](https://github.com/rgl/terraform-proxmox-talos/actions/workflows/lint.yml/badge.svg)](https://github.com/rgl/terraform-proxmox-talos/actions/workflows/lint.yml)

An example [Talos Linux](https://www.talos.dev) Kubernetes cluster in Proxmox QEMU/KVM Virtual Machines using terraform.

[Cilium](https://cilium.io) is used to augment the Networking (e.g. the [`LoadBalancer`](https://cilium.io/use-cases/load-balancer/) and [`Ingress`](https://docs.cilium.io/en/stable/network/servicemesh/ingress/) controllers), Observability (e.g. [Service Map](https://cilium.io/use-cases/service-map/)), and Security (e.g. [Network Policy](https://cilium.io/use-cases/network-policy/)).

[LVM](https://en.wikipedia.org/wiki/Logical_Volume_Manager_(Linux)), [DRBD](https://linbit.com/drbd/), [LINSTOR](https://github.com/LINBIT/linstor-server), and the [Piraeus Operator](https://github.com/piraeusdatastore/piraeus-operator), are used for providing persistent storage volumes.

The [spin extension](https://github.com/siderolabs/extensions/tree/main/container-runtime/spin), which installs [containerd-shim-spin](https://github.com/spinkube/containerd-shim-spin), is used to provide the ability to run [Spin Applications](https://developer.fermyon.com/spin/v2/index) ([WebAssembly/Wasm](https://webassembly.org/)).

# Usage (Ubuntu 22.04 host)

Set your Proxmox details:

```bash
# see https://registry.terraform.io/providers/bpg/proxmox/latest/docs#argument-reference
# see https://github.com/bpg/terraform-provider-proxmox/blob/v0.64.0/proxmoxtf/provider/provider.go#L49-L56
cat >secrets-proxmox.sh <<EOF
unset HTTPS_PROXY
#export HTTPS_PROXY='http://localhost:8080'
export TF_VAR_proxmox_pve_node_address='192.168.1.21'
export PROXMOX_VE_INSECURE='1'
export PROXMOX_VE_ENDPOINT="https://$TF_VAR_proxmox_pve_node_address:8006"
export PROXMOX_VE_USERNAME='root@pam'
export PROXMOX_VE_PASSWORD='vagrant'
export AWS_ACCESS_KEY_ID=''
export AWS_SECRET_ACCESS_KEY=''

EOF
source secrets-proxmox.sh
```

Build the talos image, and initialize terraform:

```bash
./do init
```

Create the infrastructure:

```bash
time ./do plan-apply
```

Show talos information:

```bash
export TALOSCONFIG=$PWD/talosconfig.yml
controllers="$(terraform output -raw controllers)"
workers="$(terraform output -raw workers)"
all="$controllers,$workers"
c0="$(echo $controllers | cut -d , -f 1)"
w0="$(echo $workers | cut -d , -f 1)"
talosctl -n $all version
talosctl -n $all dashboard
```

Show kubernetes information:

```bash
export KUBECONFIG=$PWD/kubeconfig.yml
kubectl cluster-info
kubectl get nodes -o wide
```

Show Cilium information:

```bash
export KUBECONFIG=$PWD/kubeconfig.yml
cilium status --wait
kubectl -n kube-system exec ds/cilium -- cilium-dbg status --verbose
```

In another shell, open the Hubble UI:

```bash
export KUBECONFIG=$PWD/kubeconfig.yml
cilium hubble ui
```

Destroy the infrastructure:

```bash
time ./do destroy
```

Update the talos extensions to match the talos version:

```bash
./do update-talos-extensions
```

# Troubleshoot

Talos:

```bash
# see https://www.talos.dev/v1.7/advanced/troubleshooting-control-plane/
talosctl -n $all support && rm -rf support && 7z x -osupport support.zip && code support
talosctl -n $c0 service ext-qemu-guest-agent status
talosctl -n $c0 service etcd status
talosctl -n $c0 etcd status
talosctl -n $c0 etcd alarm list
talosctl -n $c0 etcd members
talosctl -n $c0 get members
talosctl -n $c0 health --control-plane-nodes $controllers --worker-nodes $workers
talosctl -n $c0 inspect dependencies | dot -Tsvg >c0.svg && xdg-open c0.svg
talosctl -n $c0 dashboard
talosctl -n $c0 logs controller-runtime
talosctl -n $c0 logs kubelet
talosctl -n $c0 disks
talosctl -n $c0 mounts | sort
talosctl -n $c0 get resourcedefinitions
talosctl -n $c0 get machineconfigs -o yaml
talosctl -n $c0 get staticpods -o yaml
talosctl -n $c0 get staticpodstatus
talosctl -n $c0 get manifests
talosctl -n $c0 get services
talosctl -n $c0 get extensions
talosctl -n $c0 get addresses
talosctl -n $c0 get nodeaddresses
talosctl -n $c0 netstat --extend --programs --pods --listening
talosctl -n $c0 list -l -r -t f /etc
talosctl -n $c0 list -l -r -t f /system
talosctl -n $c0 list -l -r -t f /var
talosctl -n $c0 list -l -r /dev
talosctl -n $c0 list -l /sys/fs/cgroup
talosctl -n $c0 read /proc/cmdline | tr ' ' '\n'
talosctl -n $c0 read /proc/mounts | sort
talosctl -n $w0 read /proc/modules | sort
talosctl -n $w0 read /sys/module/drbd/parameters/usermode_helper
talosctl -n $c0 read /etc/os-release
talosctl -n $c0 read /etc/resolv.conf
talosctl -n $c0 read /etc/containerd/config.toml
talosctl -n $c0 read /etc/cri/containerd.toml
talosctl -n $c0 read /etc/cri/conf.d/cri.toml
talosctl -n $c0 read /etc/kubernetes/kubelet.yaml
talosctl -n $c0 read /etc/kubernetes/kubeconfig-kubelet
talosctl -n $c0 read /etc/kubernetes/bootstrap-kubeconfig
talosctl -n $c0 ps
talosctl -n $c0 containers -k
```

Cilium:

```bash
cilium status --wait
kubectl -n kube-system exec ds/cilium -- cilium-dbg status --verbose
cilium config view
cilium hubble ui
# **NB** cilium connectivity test is not working out-of-the-box in the default
# test namespaces and using it in kube-system namespace will leave garbage
# behind.
#cilium connectivity test --test-namespace kube-system
kubectl -n kube-system get leases | grep cilium-l2announce-
```

Kubernetes:

```bash
kubectl get events --all-namespaces --watch
kubectl --namespace kube-system get events --watch
kubectl --namespace kube-system debug node/w0 --stdin --tty --image=busybox:1.36 -- cat /host/etc/resolv.conf
kubectl --namespace kube-system get configmaps coredns --output yaml
pod_name="$(kubectl --namespace kube-system get pods --selector k8s-app=kube-dns --output json | jq -r '.items[0].metadata.name')"
kubectl --namespace kube-system debug $pod_name --stdin --tty --image=busybox:1.36 --target=coredns -- sh -c 'cat /proc/$(pgrep coredns)/root/etc/resolv.conf'
kubectl --namespace kube-system run busybox -it --rm --restart=Never --image=busybox:1.36 -- nslookup -type=a talos.dev
kubectl get crds
kubectl api-resources
```

Storage (lvm/drbd/linstor/piraeus):

```bash
# NB kubectl linstor node list is equivalent to:
#    kubectl -n piraeus-datastore exec deploy/linstor-controller -- linstor node list
kubectl linstor node list
kubectl linstor storage-pool list
kubectl linstor volume list
kubectl -n piraeus-datastore exec daemonset/linstor-satellite.w0 -- drbdadm status
kubectl -n piraeus-datastore exec daemonset/linstor-satellite.w0 -- lvdisplay
kubectl -n piraeus-datastore exec daemonset/linstor-satellite.w0 -- vgdisplay
kubectl -n piraeus-datastore exec daemonset/linstor-satellite.w0 -- pvdisplay
w0_csi_node_pod_name="$(
  kubectl -n piraeus-datastore get pods \
    --field-selector spec.nodeName=w0 \
    --selector app.kubernetes.io/component=linstor-csi-node \
    --output 'jsonpath={.items[*].metadata.name}')"
kubectl -n piraeus-datastore exec "pod/$w0_csi_node_pod_name" -- lsblk
kubectl -n piraeus-datastore exec "pod/$w0_csi_node_pod_name" -- bash -c 'mount | grep /dev/drbd'
kubectl -n piraeus-datastore exec "pod/$w0_csi_node_pod_name" -- bash -c 'df -h | grep -P "Filesystem|/dev/drbd"'
```
