FROM ubuntu:24.04

COPY ./sources.list /etc/apt/sources.list.d/ubuntu.sources

RUN apt-get update -y \ 
    && apt-get upgrade -y \
    && apt-get install -y tzdata curl vim iputils-ping locales telnet \
    && sed -i 's/# zh_CN.UTF-8 UTF-8/zh_CN.UTF-8 UTF-8/ ; s/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen \
    && locale-gen \
    && ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

ADD jdk-8u431-linux-x64.tar.gz /usr/local/src/

ENV TERM=xterm
ENV LANG=en_US.UTF-8
ENV TZ=Asia/Shanghai
ENV JAVA_VERSION=8u431
ENV JAVA_HOME=/usr/local/src/jdk1.8.0_431
ENV CLASSPATH=.:${JAVA_HOME}/lib/dt.jar:${JAVA_HOME}/lib/tools.jar:${JAVA_HOME}/jre/lib/rt.jar
ENV PATH=${PATH}:${JAVA_HOME}/bin

WORKDIR /opt/

CMD ["java", "-version"]