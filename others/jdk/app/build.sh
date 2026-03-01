#!/bin/bash
APP_IMAGE="app8:v1"
nerdctl rmi ${APP_IMAGE}
nerdctl build -t ${APP_IMAGE} .
