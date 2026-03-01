#!/bin/bash

K8S_POD_SUBNET=10.244.0.0/16

# calico install
# https://docs.tigera.io/calico/latest/getting-started/kubernetes/quickstart#install-calico
# calico network 配置
wget -O calico-tigera-operator-v3.27.3.yaml \
 https://raw.githubusercontent.com/projectcalico/calico/v3.27.3/manifests/tigera-operator.yaml
wget -O calico-custom-resources-v3.27.3.yaml \
 https://raw.githubusercontent.com/projectcalico/calico/v3.27.3/manifests/custom-resources.yaml

sed -i 's%\(cidr: \)\(.*\)$%\1'${K8S_POD_SUBNET}'%' calico-custom-resources-v3.26.1.yaml

kubectl create -f calico-tigera-operator-v3.27.3.yaml
kubectl create -f calico-custom-resources-v3.27.3.yaml

# watch kubectl get pods -n calico-system
# kubectl taint nodes --all node-role.kubernetes.io/control-plane-
# kubectl taint nodes --all node-role.kubernetes.io/master-

