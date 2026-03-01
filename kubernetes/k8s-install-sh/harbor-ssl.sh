#!/bin/bash

DOMAIN="harbor.labs.yzx"

# This script generates a self-signed SSL certificate for Harbor.
openssl genrsa -out ca.key 4096

openssl req -x509 -new -nodes -sha512 -days 3650 \
 -subj "/C=CN/ST=Shanghai/L=Shanghai/O=Harbor/OU=Harbor/CN=Harbor Root CA" \
 -key ca.key \
 -out ca.crt

# server certificate , yourdomain.com.crt / yourdomain.com.key
openssl genrsa -out ${DOMAIN}.key 4096

# Generate a CSR (Certificate Signing Request)
openssl req -sha512 -new \
    -subj "/C=CN/ST=Shanghai/L=Shanghai/O=Harbor/OU=Harbor/CN=${DOMAIN}" \
    -key ${DOMAIN}.key \
    -out ${DOMAIN}.csr

# Generate an x509 v3 extension file.
cat > v3.ext <<-EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1=${DOMAIN}
IP.1=192.168.50.100
EOF

openssl x509 -req -sha512 -days 3650 \
    -extfile v3.ext \
    -CA ca.crt -CAkey ca.key -CAcreateserial \
    -in ${DOMAIN}.csr \
    -out ${DOMAIN}.crt

# to harbor and docker
# Convert yourdomain.com.crt to yourdomain.com.cert, for use by Docker.
openssl x509 -inform PEM -in ${DOMAIN}.crt -out ${DOMAIN}.cert

# 仅适用与 containerd.io 1.x 版本 - nerdctl 1.x 版本
# containerd.io 2.x 版本适配与 nerdctl 2.x 版本

# /etc/docker/certs.d/
#     └── yourdomain.com:port
#        ├── yourdomain.com.cert  <-- Server certificate signed by CA
#        ├── yourdomain.com.key   <-- Server key signed by CA
#        └── ca.crt               <-- Certificate authority that signed the registry certificate


# nerdctl self-signed certs config

# mkdir -p /etc/containerd/certs.d/${DOMAIN}
# cp ca.crt /etc/containerd/certs.d/${DOMAIN}/ca.crt
# cp ${DOMAIN}.cert /etc/containerd/certs.d/${DOMAIN}/${DOMAIN}.cert
# cp ${DOMAIN}.key /etc/containerd/certs.d/${DOMAIN}/${DOMAIN}.key

# openssl s_client -connect harbor.labs.yzx:443 -CAfile ca.crt -showcerts </dev/null

# #!/bin/bash
# DOMAIN="harbor.labs.yzx"
# mkdir -p /etc/containerd/certs.d/${DOMAIN}
# cat <<EOF > /etc/containerd/certs.d/${DOMAIN}/hosts.toml
# server = "https://${DOMAIN}"
# [host."https://${DOMAIN}"]
#   capabilities = ["pull", "push", "resolve"]
#   ca = "/etc/containerd/certs.d/${DOMAIN}/ca.crt"
#   cert = "/etc/containerd/certs.d/${DOMAIN}/${DOMAIN}.cert"
#   key = "/etc/containerd/certs.d/${DOMAIN}/${DOMAIN}.key"
#   skip_verify = false
# EOF
