
# b, k, m, g
nerdctl run -d --name app8 --memory="1g" -p 54100:54100 app8:v1

nerdctl run -d --name app --memory="1g" -p 8080:8080 app17:v1

docker run -d --cap-add=SYS_PTRACE --name app --memory="4g" -p 39999:38888 app11:v1

docker run -d --cap-add=SYS_PTRACE --name app --memory="4g" -p 39999:38888 jdk8-app:v1

CONTAINER_NAME=app8
IMAGE_NAME=openjdk-app8:v1
nerdctl stop ${CONTAINER_NAME}
nerdctl rm ${CONTAINER_NAME}
nerdctl run -d --name ${CONTAINER_NAME} --memory="1g" -p 28080:28080 ${IMAGE_NAME}
