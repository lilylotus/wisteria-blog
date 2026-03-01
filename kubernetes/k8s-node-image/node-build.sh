#!/bin/bash

nerdctl -n k8s.io load -i node_22.3.0-alpine3.20.tar.gz
nerdctl -n k8s.io build -t node:v1 .

cd /root/node/ && nerdctl -n k8s.io build -t node:v1 .

nerdctl -n k8s.io save node:v1 | gzip > node_v1.tar.gz

cd /root/node/ && nerdctl -n k8s.io  load -i node_v1.tar.gz

