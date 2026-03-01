
# server 
yum install nfs-utils

systemctl enable rpcbind
systemctl enable nfs

cat <<EOF > /etc/exports
/data/nfs/  *(rw,sync,no_root_squash,no_all_squash)
EOF

systemctl restart nfs

# mount -t nfs 10.10.10.111:/data/nfs/ /data/nfs/
# /etc/fstab -> 192.168.0.110:/data /data nfs defaults 0 0