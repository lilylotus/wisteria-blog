FROM centos:7.9.2009

COPY ./Centos7.repo /opt/CentOS-Base.repo

RUN ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && mkdir -p /etc/yum.repos.d/backup \
    && mv /etc/yum.repos.d/*.repo /etc/yum.repos.d/backup/ \
    && mv /opt/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo \
    && yum clean all \
    && yum makecache \
    && yum install -y curl wget telnet vim \
    && yum clean all 

ADD jdk-8u431-linux-x64.tar.gz /usr/local/src/

ENV TZ=Asia/Shanghai
ENV LANG=en_US.UTF-8
ENV JAVA_VERSION=8u431
ENV JAVA_HOME=/usr/local/src/jdk1.8.0_431
ENV CLASSPATH=.:${JAVA_HOME}/lib/dt.jar:${JAVA_HOME}/lib/tools.jar:${JAVA_HOME}/jre/lib/rt.jar
ENV PATH=${PATH}:${JAVA_HOME}/bin

WORKDIR /opt/

CMD ["java", "-version"]