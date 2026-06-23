#!/bin/bash

# ==========================================
# SYSTEM UPDATE
# ==========================================

apt-get update -y
apt-get upgrade -y

# ==========================================
# INSTALL UTILITIES
# ==========================================

apt-get install -y curl jq awscli

# ==========================================
# INSTALL K3S
# ==========================================

curl -sfL https://get.k3s.io | sh -

# ==========================================
# WAIT FOR K3S TO START
# ==========================================

sleep 30

# ==========================================
# CONFIGURE KUBECTL FOR UBUNTU USER
# ==========================================

mkdir -p /home/ubuntu/.kube

cp /etc/rancher/k3s/k3s.yaml \
   /home/ubuntu/.kube/config

chown -R ubuntu:ubuntu \
   /home/ubuntu/.kube

# ==========================================
# VERIFY CLUSTER
# ==========================================

kubectl get nodes > /tmp/k3s-status.txt