#!/bin/bash
terraform_version='1.9.5'
wget "https://releases.hashicorp.com/terraform/$terraform_version/terraform_${terraform_version}_linux_amd64.zip"
unzip "terraform_${terraform_version}_linux_amd64.zip"
sudo install terraform /usr/local/bin
rm terraform terraform_*_linux_amd64.zip LICENSE.txt

cilium_version='0.16.16'
cilium_url="https://github.com/cilium/cilium-cli/releases/download/v$cilium_version/cilium-linux-amd64.tar.gz"
wget -O- "$cilium_url" | tar xzf - cilium
sudo install cilium /usr/local/bin/cilium
rm cilium

hubble_version='1.16.0'
hubble_url="https://github.com/cilium/hubble/releases/download/v$hubble_version/hubble-linux-amd64.tar.gz"
wget -O- "$hubble_url" | tar xzf - hubble
sudo install hubble /usr/local/bin/hubble
rm hubble

talos_version='1.7.6'
wget https://github.com/siderolabs/talos/releases/download/v$talos_version/talosctl-linux-amd64
sudo install talosctl-linux-amd64 /usr/local/bin/talosctl
rm talosctl-linux-amd64

kubectl_version='1.31.0'
wget https://dl.k8s.io/release/v$kubectl_version/bin/linux/amd64/kubectl
sudo install kubectl /usr/local/bin/kubectl
rm kubectl

flux_version='2.4.0'
wget https://github.com/fluxcd/flux2/releases/download/v$flux_version/flux_${flux_version}_linux_amd64.tar.gz
tar -zxvf flux_${flux_version}_linux_amd64.tar.gz
sudo install flux /usr/local/bin/flux
rm flux_${flux_version}_linux_amd64.tar.gz flux

k9s_version='0.32.7'
wget https://github.com/derailed/k9s/releases/download/v$k9s_version/k9s_Linux_amd64.tar.gz
tar -zxvf k9s_Linux_amd64.tar.gz
sudo install k9s /usr/local/bin/k9s
rm k9s k9s_Linux_amd64.tar.gz LICENSE README.md

kubectl_linstor_version='0.3.1'
wget https://github.com/piraeusdatastore/kubectl-linstor/releases/download/v$kubectl_linstor_version/kubectl-linstor_v${kubectl_linstor_version}_linux_amd64.tar.gz
tar -zxvf kubectl-linstor_v${kubectl_linstor_version}_linux_amd64.tar.gz
sudo install kubectl-linstor /usr/local/bin/kubectl-linstor
rm kubectl-linstor* LICENSE README.md

weave_gitops_version='0.38.0'
curl --silent --location "https://github.com/weaveworks/weave-gitops/releases/download/v0.38.0/gitops-$(uname)-$(uname -m).tar.gz" | tar xz -C /tmp
sudo install /tmp/gitops /usr/local/bin/gitops
rm /tmp/gitops /tmp/README.md /tmp/LICENSE

if type dnf; then
	sudo dnf install qemu -y
elif type apt; then
	sudo apt install qemu -y
else
	echo "What package manager do you use?" >&2
	exit 1
fi
