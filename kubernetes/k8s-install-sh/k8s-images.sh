#!/bin/bash

# K8S_VERSION=1.28.14
# K8S_VERSION=1.29.12
# K8S_VERSION=1.30.8
K8S_VERSION=1.31.4
K8S_IMAGE_FILE=kubeadm-images-${K8S_VERSION}.txt
IMAGEDIR=k8s-images-${K8S_VERSION}

# kubernetes v1.31.4 pause -> 3.10
# sed -i '/sandbox_image/s/3.[0-9]\{1,2\}/3.10/' /etc/containerd/config.toml

# kubernetes v1.30.8 / v1.29.12 / v1.28.14 pause -> 3.9
sed -i '/sandbox_image/s/3.[0-9]\{1,2\}/3.9/' /etc/containerd/config.toml

nerdctl -n k8s.io rmi -f $(nerdctl -n k8s.io images -q)

kubeadm config images pull \
    --kubernetes-version=${K8S_VERSION} \
    --image-repository=registry.aliyuncs.com/google_containers

kubeadm config images list \
    --kubernetes-version=${K8S_VERSION} \
    --image-repository=registry.aliyuncs.com/google_containers \
    > ${K8S_IMAGE_FILE}

# kubeadm config images list \
# --kubernetes-version=1.30.4 \
# --image-repository=registry.aliyuncs.com/google_containers

# sed -i 's/registry.aliyuncs.com\/google_containers/registry.k8s.io/' 
sed -i 's/registry.aliyuncs.com\/google_containers\///' ${K8S_IMAGE_FILE}

rm -rf $IMAGEDIR && rm -f ${IMAGEDIR}.tar.gz && mkdir $IMAGEDIR 

# 注意 coredns 需特殊处理
# registry.aliyuncs.com/google_containers/coredns:v1.11.1
# registry.k8s.io/coredns/coredns:v1.11.1

for line in $( cat ${K8S_IMAGE_FILE} )
do
    result=$(echo ${line} | grep coredns)
    if [[ "${result}" == "" ]]
    then
        k8s_img="registry.k8s.io/${line}"
    else
        k8s_img="registry.k8s.io/coredns/${line}"
    fi
    ali_img="registry.aliyuncs.com/google_containers/${line}"
    nerdctl -n k8s.io tag ${ali_img} ${k8s_img}

    dist=$(echo ${k8s_img} | awk -F'/' '{print $NF}' | sed 's/:/_/g').tar.gz
	echo "save k8s image ${k8s_img} to ${dist}"
	nerdctl -n k8s.io save ${k8s_img} | gzip > ${IMAGEDIR}/${dist}
done

pause_image36=pause:3.6
pause_image39=pause:3.9

nerdctl -n k8s.io pull registry.aliyuncs.com/google_containers/${pause_image36}
nerdctl -n k8s.io tag registry.aliyuncs.com/google_containers/${pause_image36} registry.k8s.io/${pause_image36}
nerdctl -n k8s.io save registry.k8s.io/${pause_image36} | gzip > ${IMAGEDIR}/pause_3.6.tar.gz

nerdctl -n k8s.io pull registry.aliyuncs.com/google_containers/${pause_image39}
nerdctl -n k8s.io tag registry.aliyuncs.com/google_containers/${pause_image39} registry.k8s.io/${pause_image39}
nerdctl -n k8s.io save registry.k8s.io/${pause_image39} | gzip > ${IMAGEDIR}/pause_3.9.tar.gz

tar -czf ${IMAGEDIR}.tar.gz ${IMAGEDIR}
