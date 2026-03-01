
#!/bin/bash

ALL_HOSTS=(k8s-master k8s-slave1 k8s-slave2 k8s-slave3)
CMD=$1
for host in ${ALL_HOSTS[@]};
do
    echo operator host ${host} exec ["'${CMD}'"]
    ssh root@${host} "${CMD}"
done


#!/bin/bash
ALL_HOSTS=(k8s-master k8s-slave1 k8s-slave2 k8s-slave3)
SCP_FILE=$1
SCP_DIST=$2
for host in ${ALL_HOSTS[@]};
do
    echo "====== scp to host [${host}]"
    if [[ -d "${SCP_FILE}" ]]; then
        FILES=$(ls ${SCP_FILE})

        if [[ "${SCP_FILE}" =~ /$ ]]; then
                echo "[${SCP_FILE}] end with /"
        else
                echo "[${SCP_FILE}] not end with /"
                SCP_FILE=${SCP_FILE}/
        fi

        for f in ${FILES[@]}
        do
            echo "------ scp [${SCP_FILE}${f}] to [${SCP_DIST}]"
            scp ${SCP_FILE}${f} root@${host}:${SCP_DIST}
        done
    else
       echo "------ scp [${SCP_FILE}] to [${SCP_DIST}]"
        scp $SCP_FILE root@${host}:${SCP_DIST}
    fi
done

# ==================================

cat <<EOF > /etc/hosts
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
192.168.50.91 k8s-master
192.168.50.96 k8s-slave1
192.168.50.97 k8s-slave2
192.168.50.98 k8s-slave3
EOF

sed -i '/BOOTPROTO/s/dhcp/static/g' /etc/sysconfig/network-scripts/ifcfg-ens192

cat <<EOF >> /etc/sysconfig/network-scripts/ifcfg-ens192
IPADDR=192.168.50.98
GATEWAY=192.168.50.1
NETMASK=255.255.255.0
DNS1=223.5.5.5
EOF

hostnamectl --static set-hostname k8s-slave3

kubeadm join 192.168.50.91:6443 --token abcdef.0123456789abcdef --discovery-token-ca-cert-hash sha256:454fd84c673d0683942597b193ae51fb3e003432632be528c2c520d8c1ca9a88
