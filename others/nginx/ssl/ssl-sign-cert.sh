#!/bin/bash

CA_CERT_CN="ca.self.sign.com"
CA_CERT_IP=192.168.99.122
CA_CERT_DIR=ca

SERVER_CERT_CN="server.self.sign.com"
SERVER_CERT_IP=192.168.99.122
SERVER_CERT_DIR=server

CLIENT_CERT_CN="client.self.sign.com"
CLIENT_CERT_IP=192.168.99.122
CLIENT_CERT_DIR=client

SCRIPT_DIR=$(cd $(dirname $0); pwd)
echo "Current Script Dir: ${SCRIPT_DIR}"
cd ${SCRIPT_DIR}

rm -rf ${CA_CERT_DIR} ${SERVER_CERT_DIR} ${CLIENT_CERT_DIR}
mkdir -p ${CA_CERT_DIR} ${SERVER_CERT_DIR} ${CLIENT_CERT_DIR}

echo "============================== SELF SIGN CA CERT =============================="

# 1.创建 CA 私钥文件
openssl genrsa -out ${CA_CERT_DIR}/ca.key 2048

# 2.创建 CA 证书请求文件
# 方式1.创建 CA 证书请求文件没有 SAN 配置
openssl req -new -subj "/C=CN/ST=Shanghai/L=Shanghai/O=SelfCaInstitution/OU=sign/CN=${CA_CERT_CN}" -key ${CA_CERT_DIR}/ca.key -out ${CA_CERT_DIR}/ca-no-san.csr
# -new：生成新的 CSR 请求
# -subj：指定证书主题信息（Distinguished Name），格式为 /属性=值/属性=值/...
# -key：指定私钥文件路径（若无私钥则需先生成）
# -out：指定输出的 CSR 文件路径

# 方式2.使用配置方式生成带有 SAN 配置（推荐）
cat > ${CA_CERT_DIR}/ca.cnf << EOF
[req]
default_bits = 2048
default_md = sha256
prompt = no
distinguished_name = dn
# 特别注意: CA 证书应使用 x509_extensions 而不是 req_extensions
x509_extensions = v3_ca

[dn]
countryName = CN
stateOrProvinceName = Shanghai
localityName = Shanghai
organizationName = SelfCaInstitution
organizationalUnitName = sign
commonName = ${CA_CERT_CN}

[v3_ca]
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints = critical, CA:true
keyUsage = critical, digitalSignature, cRLSign, keyCertSign
subjectAltName = @alt_names

[alt_names]
DNS.1 = ${CA_CERT_CN}
IP.1 = ${CA_CERT_IP}
email.1 = ca@${CA_CERT_CN}
URI.1 = https://${CA_CERT_CN}/ca
EOF

openssl req -new -key ${CA_CERT_DIR}/ca.key -out ${CA_CERT_DIR}/ca.csr -config ${CA_CERT_DIR}/ca.cnf

# 查看 CA 证书请求文件内容
openssl req -in ${CA_CERT_DIR}/ca.csr -noout -text

echo "============================================================"

# 3.创建 CA 证书，有效期10年
# 方式1.创建 CA 证书请求文件没有 SAN 配置，所以可按照下述命令，创建扩展配置文件（ca.ext） ，并在生成证书文件时指定扩展配置文件路径
cat > ${CA_CERT_DIR}/v3_ca.ext << EOF
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints = critical, CA:true
keyUsage = critical, digitalSignature, cRLSign, keyCertSign
subjectAltName = @alt_names

[alt_names]
DNS.1 = ${CA_CERT_CN}
IP.1 = ${CA_CERT_IP}
email.1 = ca@${CA_CERT_CN}
URI.1 = https://${CA_CERT_CN}/ca
EOF

openssl x509 -req -sha256 -days 3650 -key ${CA_CERT_DIR}/ca.key -in ${CA_CERT_DIR}/ca-no-san.csr -out ${CA_CERT_DIR}/ca-no-san.crt -extfile ${CA_CERT_DIR}/v3_ca.ext

# 方式2.直接使用配置方式生成带有 SAN 配置的 CA 证书
openssl x509 -req -sha256 -days 3650 -key ${CA_CERT_DIR}/ca.key -in ${CA_CERT_DIR}/ca.csr -out ${CA_CERT_DIR}/ca.crt -extfile ${CA_CERT_DIR}/ca.cnf -extensions v3_ca
# Certificate request self-signature ok
# subject=C = CN, ST = Chongqing, L = Chongqing, O = WeiyiGeek, OU = root, CN = ca.weiyigeek.top

# 4.查看 CA 证书内容
openssl x509 -in ${CA_CERT_DIR}/ca.crt -noout -text

echo "============================================================"

# 使用 CA 颁发 Nginx 服务端证书

echo "============================== SELF SIGN SERVER CERT =============================="

# 生成 Diffie-Hellman keys
openssl dhparam -out ${SERVER_CERT_DIR}/dhparam.pem 2048

# 1.创建 Nginx 服务端私钥文件
openssl genrsa -out ${SERVER_CERT_DIR}/server.key 2048

# 2.创建 Nginx 服务端证书请求文件
openssl req -new -key ${SERVER_CERT_DIR}/server.key -out ${SERVER_CERT_DIR}/server.csr -subj "/C=CN/ST=Shanghai/L=Shanghai/O=SelfServerInstitution/OU=Nginx Server/CN=${SERVER_CERT_CN}"

# 3.创建服务端证书扩展配置 (server.ext)
cat > ${SERVER_CERT_DIR}/server.ext << EOF
authorityKeyIdentifier = keyid,issuer
basicConstraints = CA:FALSE
keyUsage = digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[ v3_req ]
authorityKeyIdentifier = keyid,issuer:always
basicConstraints = CA:FALSE
keyUsage = digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth,clientAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = ${SERVER_CERT_CN}
IP.1 = ${SERVER_CERT_IP}
EOF

# 4.使用 CA 签发 Nginx 服务端证书
openssl x509 -req -sha256 -days 3650 \
  -in ${SERVER_CERT_DIR}/server.csr \
  -CA ${CA_CERT_DIR}/ca.crt -CAkey ${CA_CERT_DIR}/ca.key \
  -CAcreateserial \
  -out ${SERVER_CERT_DIR}/server.crt \
  -extfile ${SERVER_CERT_DIR}/server.ext \
  -extensions v3_req

# 5.查看 CA 证书内容
openssl x509 -in ${SERVER_CERT_DIR}/server.crt -noout -text

# 6.验证签发的证书是否正确
openssl verify -CAfile ${CA_CERT_DIR}/ca.crt ${SERVER_CERT_DIR}/server.crt
# server.crt: OK

echo "============================== SELF SIGN CLIENT CERT =============================="

# 客户端证书生成与签发

# 1.创建客户端私钥文件
openssl genrsa -out ${CLIENT_CERT_DIR}/client.key 2048

# 2.创建客户端证书请求文件
openssl req -new -key ${CLIENT_CERT_DIR}/client.key -out ${CLIENT_CERT_DIR}/client.csr -subj "/C=CN/ST=Shanghai/L=Shanghai/O=SelfClientInstitution/OU=Client/CN=${CLIENT_CERT_CN}"

# 3.创建客户端证书扩展配置 (client.ext)
cat > ${CLIENT_CERT_DIR}/client.ext << EOF
authorityKeyIdentifier = keyid,issuer
basicConstraints = CA:FALSE
keyUsage = digitalSignature, keyEncipherment
extendedKeyUsage = clientAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = ${CLIENT_CERT_CN}
IP.1 = ${CLIENT_CERT_IP}
EOF

# 4.使用 CA 签发客户端证书
openssl x509 -req -sha256 -days 365 \
  -in ${CLIENT_CERT_DIR}/client.csr \
  -CA ${CA_CERT_DIR}/ca.crt -CAkey ${CA_CERT_DIR}/ca.key \
  -CAcreateserial \
  -out ${CLIENT_CERT_DIR}/client.crt \
  -extfile ${CLIENT_CERT_DIR}/client.ext
# Certificate request self-signature ok
# subject=C = CN, ST = Chongqing, L = Chongqing, O = WeiyiGeek, OU = Client Department, CN = client.weiyigeek.top

# 5.查看 CA 证书内容
openssl x509 -in ${CLIENT_CERT_DIR}/client.crt -noout -text

# 6.验证签发的证书是否正确
openssl verify -CAfile ${CA_CERT_DIR}/ca.crt ${CLIENT_CERT_DIR}/client.crt
# server.crt: OK

# 7.根据证书密钥与公钥生成为p12格式证书，它是一对公私钥的合体文件，通常会有密码保护，文件扩展名为 .p12 /.fpx 格式。
openssl pkcs12 -export \
  -in ${CLIENT_CERT_DIR}/client.crt \
  -inkey ${CLIENT_CERT_DIR}/client.key \
  -out ${CLIENT_CERT_DIR}/client.pfx \
  -name "client" -passout pass:123456

# 8.若需要将证书转换为 Java 的 keystore 格式可利用 keytool 工具进行转换，命令如下：

keytool -importkeystore \
  -srcstoretype PKCS12 -srckeystore ${CLIENT_CERT_DIR}/client.pfx \
  -srcstorepass 123456 -srcalias client -deststoretype pkcs12 \
  -destalias client -deststorepass 123456 -destkeypass 123456 \
  -destkeystore ${CLIENT_CERT_DIR}/client.jks
