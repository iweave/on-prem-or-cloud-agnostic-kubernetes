#!/bin/bash

echo "installing docker"
if [ "$(lsb_release -cs)" == "focal" ] ; then
  swapoff -a
  sed -i 's/\/swapfile /#swapfile /' /etc/fstab
fi
apt-get update
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common \
    ${ADDITIONAL_APT}
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository \
   "deb https://download.docker.com/linux/$(. /etc/os-release; echo "$ID") \
   $(lsb_release -cs) \
   stable"

if [ "$(lsb_release -cs)" == "bionic" ] ; then
  apt-get update && apt-get install -y docker-ce docker-ce-cli containerd.io
elif [ "$(lsb_release -cs)" == "focal" ] ; then
  apt-get update && apt-get install -y docker-ce=$(apt-cache madison docker-ce | grep 20.10 | head -1 | awk '{print $3}')
else
  apt-get update && apt-get install -y docker-ce=$(apt-cache madison docker-ce | grep 17.03 | head -1 | awk '{print $3}')
fi

if [ "$(lsb_release -cs)" == "focal" ] ; then
echo "re-configuring docker to use systemd for cgroups"
  mkdir /etc/docker
cat <<EOF | sudo tee /etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF
  systemctl enable docker
  systemctl daemon-reload
  systemctl restart docker
fi

echo "installing kubernetes"
apt-get update && apt-get install -y apt-transport-https
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF
apt-get update
apt-get install -y kubelet kubeadm kubectl
echo "Freezing k8s packages"
sudo apt-mark hold kubelet kubeadm kubectl

# DigitalOcean without firewall (IP-in-IP allowed) - or any other cloud / on-prem that supports IP-in-IP traffic
# echo "deploying kubernetes (with calico)..."
# kubeadm init --pod-network-cidr=192.168.0.0/16 # add --apiserver-advertise-address="ip" if you want to use a different IP address than the main server IP
# export KUBECONFIG=/etc/kubernetes/admin.conf
# kubectl apply -f https://docs.projectcalico.org/v3.1/getting-started/kubernetes/installation/hosted/rbac-kdd.yaml
# kubectl apply -f https://docs.projectcalico.org/v3.1/getting-started/kubernetes/installation/hosted/kubernetes-datastore/calico-networking/1.7/calico.yaml


# DigitalOcean with firewall (VxLAN with Flannel) - could be resolved in the future by allowing IP-in-IP in the firewall settings
echo "deploying kubernetes (with canal)..."
kubeadm init --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address="10.13.106.11" --apiserver-cert-extra-sans=api.a.wedone.org,192.96.159.198,10.10.138.11 # add --apiserver-advertise-address="ip" if you want to use a different IP address than the main server IP
export KUBECONFIG=/etc/kubernetes/admin.conf
curl https://docs.projectcalico.org/manifests/canal.yaml -O
kubectl apply -f canal.yaml
