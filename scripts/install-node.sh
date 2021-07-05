#!/bin/bash

echo "installing docker"
if [ "$(lsb_release -cs)" == "focal" ] ; then
  swapoff -a
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

echo "installing kubeadm and kubectl"
apt-get update && apt-get install -y apt-transport-https
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF
apt-get update
apt-get install -y kubelet kubeadm kubectl
