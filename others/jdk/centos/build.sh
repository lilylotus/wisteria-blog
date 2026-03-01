#!/bin/bash
JDK_IMAGE="jdk8-8u431-centos-792009:v1"
nerdctl rmi ${JDK_IMAGE}
nerdctl build -t ${JDK_IMAGE} .
nerdctl run --rm ${JDK_IMAGE}
# nerdctl run -it --name jdk8 --rm jdk8-8u431-centos-792009:v1 bash