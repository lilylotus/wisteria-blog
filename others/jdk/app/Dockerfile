FROM jdk8-debian:v1
WORKDIR /opt/
COPY app.jar /opt/app.jar
COPY entrypoint.sh /opt/
ENTRYPOINT ["bash","/opt/entrypoint.sh"]