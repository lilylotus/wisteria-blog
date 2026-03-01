#!/bin/bash
JDK_IMAGE="jdk8-8u431-ubuntu-2404:v1"
nerdctl rmi ${JDK_IMAGE}
nerdctl build -t ${JDK_IMAGE} .
nerdctl run --rm ${JDK_IMAGE}