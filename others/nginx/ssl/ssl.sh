#!/bin/bash

SSL_DOMAIN=labs.yzx

# 生成 Diffie-Hellman keys
openssl dhparam -out dhparam.pem 2048

openssl genrsa -out ca.key 2048
openssl req -x509 -new -nodes -key ca.key -subj "/CN=ROOT SELF SIGN CA" -days 3560 -out ca.crt

# 生成一个 2048 位的 server.key 文件
openssl genrsa -out ${SSL_DOMAIN}.key 2048

cat <<EOF > csr.conf
[ req ]
default_bits = 2048
prompt = no
default_md = sha256
req_extensions = req_ext
x509_extensions = v3_req
distinguished_name = dn

[ dn ]
# C = <country>
# ST = <state>
# L = <city>
# O = <organization>
# OU = <organization unit>
# CN = <SSL_DOMAIN>
C = CN
ST = Shanghai
L = Shanghai
O = Labs
OU = Labs Team
CN = ${SSL_DOMAIN}

[ req_ext ]
subjectAltName = @alt_names

[ alt_names ]
DNS.1 = ${SSL_DOMAIN}
DNS.3 = *.${SSL_DOMAIN}
IP.1 = 192.168.99.20

[ v3_ext ]
authorityKeyIdentifier=keyid,issuer:always
basicConstraints=CA:FALSE
keyUsage=keyEncipherment,dataEncipherment
extendedKeyUsage=serverAuth,clientAuth
subjectAltName=@alt_names

[ v3_req ]
authorityKeyIdentifier = keyid,issuer:always
basicConstraints = CA:FALSE
keyUsage = digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth,clientAuth
subjectAltName = @alt_names

EOF

# 基于配置文件生成证书签名请求
openssl req -new -key ${SSL_DOMAIN}.key -out ${SSL_DOMAIN}.csr -config csr.conf

# 基于 ca.key、ca.crt 和 server.csr 等三个文件生成服务端证书
openssl x509 -req -in ${SSL_DOMAIN}.csr -CA ca.crt -CAkey ca.key \
    -CAcreateserial -out ${SSL_DOMAIN}.crt -days 3650 \
    -extensions v3_req -extfile csr.conf -sha256

# 查看证书签名请求
openssl req  -noout -text -in ${SSL_DOMAIN}.csr

# 查看证书
openssl x509  -noout -text -in ${SSL_DOMAIN}.crt

