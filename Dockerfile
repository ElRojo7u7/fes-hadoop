# syntax=docker/dockerfile:1-labs

FROM alpine:3.6 as base

EXPOSE 22

EXPOSE 9000

######## HDFS #######
# NameNode WebUI (dfs.namenode.http-address / dfs.namenode.https-address) 
EXPOSE 9870 9871

# DataNode (dfs.datanode.http.address / dfs.datanode.https.address)
EXPOSE 9864 9865

# DataNode (dfs.datanode.address)
EXPOSE 9866

# DataNode (dfs.datanode.ipc.address) [IPC]
EXPOSE 9867

# SecondaryNameNode (dfs.namenode.secondary.http-address / dfs.namenode.secondary.https-address)
EXPOSE 9868 9869

# JournalNode (dfs.journalnode.rpc-address) [IPC]
EXPOSE 8485

# JournalNode (dfs.journalnode.http-address / dfs.journalnode.https-address)
EXPOSE 8480 8481

# AliasMapServer (dfs.provided.aliasmap.inmemory.dnrpc-address)
EXPOSE 50200

######## MapReduce ########
# MapReduce Job History (mapreduce.jobhistory.address)
EXPOSE 10020

# MapReduce Job History WebUI (mapreduce.jobhistory.webapp.address / mapreduce.jobhistory.webapp.https.address)
EXPOSE 19888 19890

# History server admin (mapreduce.jobhistory.admin.address) [IPC]
EXPOSE 10033

######## YARN ##########
# yarn.resourcemanager.address [IPC]
EXPOSE 8032

# yarn.resourcemanager.scheduler.address [IPC]
EXPOSE 8030

# yarn.resourcemanager.webapp.address / yarn.resourcemanager.webapp.https.address
EXPOSE 8088 8090

# yarn.resourcemanager.resource-tracker.address
EXPOSE 8031

# yarn.resourcemanager.admin.address
EXPOSE 8030

# yarn.nodemanager.address
EXPOSE 0

# yarn.nodemanager.localizer.address
EXPOSE 8090

# yarn.nodemanager.collector-service.address
EXPOSE 8048

# yarn.nodemanager.webapp.address / yarn.nodemanager.webapp.https.address
EXPOSE 8042 8044

# yarn.timeline-service.address
EXPOSE 10200

# yarn.timeline-service.webapp.address / yarn.timeline-service.webapp.https.address
EXPOSE 8188 8190

# yarn.sharedcache.admin.address
EXPOSE 8047

# yarn.sharedcache.webapp.address
EXPOSE 8788

# yarn.sharedcache.uploader.server.address
EXPOSE 8046

# yarn.sharedcache.client-server.address
EXPOSE 8045

# yarn.nodemanager.amrmproxy.address
EXPOSE 8049

# yarn.router.webapp.address / yarn.router.webapp.https.address
EXPOSE 8089 8091

USER root
RUN apk add --update --no-cache bash openssh openssl nss sshpass
RUN adduser -h /home/hadoop -s /bin/sh -D hadoop
RUN ssh-keygen -qN "" -t ed25519 -f /etc/ssh/ssh_host_ed25519_key


FROM --platform=$BUILDPLATFORM alpine:3.6 as hadoop_extract
ARG BUILDPLATFORM
ARG TARGETPLATFORM
ARG HADOOP_FILE
WORKDIR /root
RUN mkdir -p /usr/local
ADD ${HADOOP_FILE}.tar.gz /root
RUN if [ "${TARGETPLATFORM}" != "linux/arm64" ] && [ "${TARGETPLATFORM}" != "linux/arm64/v8" ]; then \
    mv ${HADOOP_FILE} /usr/local; \
    else rm -rf ${HADOOP_FILE}; \
    fi
ADD ${HADOOP_FILE}-aarch64.tar.gz /root
RUN if [ "${TARGETPLATFORM}" == "linux/arm64" ] || [ "${TARGETPLATFORM}" == "linux/arm64/v8" ]; then \
    mv ${HADOOP_FILE} /usr/local; \
    fi

FROM base as hadoop_install
ARG HADOOP_FILE
COPY --from=hadoop_extract --chown=1000:1000 /usr/local/${HADOOP_FILE} /usr/local/${HADOOP_FILE}
RUN mkdir -p /opt && ln -s /usr/local/${HADOOP_FILE} /opt/hadoop
RUN mkdir -p /mnt/hadoop/datanode /mnt/hadoop/namenode \
    && chown -R 1000:1000 /mnt/hadoop
ADD --chown=1000:1000 core-site.xml /opt/hadoop/etc/hadoop/core-site.xml
ADD --chown=1000:1000 hdfs-site.xml /opt/hadoop/etc/hadoop/hdfs-site.xml
ADD --chown=1000:1000 mapred-site.xml /opt/hadoop/etc/hadoop/mapred-site.xml
ADD --chown=1000:1000 yarn-site.xml /opt/hadoop/etc/hadoop/yarn-site.xml


# Install java

FROM --platform=$BUILDPLATFORM alpine:3.6 as java_extract
ARG BUILDPLATFORM
ARG TARGETPLATFORM
WORKDIR /root
RUN mkdir -p /usr/lib/jvm
ADD jdk-8u371-linux-x64.tar.gz /root
RUN if [ "${TARGETPLATFORM}" != "linux/amd64" ]; then \
    rm -rf jdk1.8.0_371; \
    echo "removed amd64"; \
    else mv jdk1.8.0_371 /usr/lib/jvm; \
    fi
ADD jdk-8u371-linux-i586.tar.gz /root
RUN if [ "${TARGETPLATFORM}" != "linux/386" ]; then \
    rm -rf jdk1.8.0_371; \
    echo "remover x86"; \
    else mv jdk1.8.0_371 /usr/lib/jvm; \
    fi
ADD jdk-8u371-linux-arm32-vfp-hflt.tar.gz /root
RUN if [ "${TARGETPLATFORM}" != "linux/arm/v6" ] && [ "${TARGETPLATFORM}" != "linux/arm/v7" ]; then \
    rm -rf jdk1.8.0_371; \
    echo "removed arm x86"; \
    else mv jdk1.8.0_371 /usr/lib/jvm; \
    fi
ADD jdk-8u371-linux-aarch64.tar.gz /root
RUN if [ "${TARGETPLATFORM}" == "linux/arm64" ] || [ "${TARGETPLATFORM}" == "linux/arm64/v8" ] || [ "${TARGETPLATFORM}" == "linux/arm/v8" ]; then \
    mv jdk1.8.0_371 /usr/lib/jvm; \
    fi
ENV JAVA_HOME /usr/lib/jvm/jdk1.8.0_371
RUN rm -rf $JAVA_HOME/*src.zip \
    $JAVA_HOME/lib/missioncontrol \
    $JAVA_HOME/lib/visualvm \
    $JAVA_HOME/lib/*javafx* \
    $JAVA_HOME/jre/lib/plugin.jar \
    $JAVA_HOME/jre/lib/ext/jfxrt.jar \
    $JAVA_HOME/jre/bin/javaws \
    $JAVA_HOME/jre/lib/javaws.jar \
    $JAVA_HOME/jre/lib/desktop \
    $JAVA_HOME/jre/plugin \
    $JAVA_HOME/jre/lib/deploy* \
    $JAVA_HOME/jre/lib/*javafx* \
    $JAVA_HOME/jre/lib/*jfx* \
    $JAVA_HOME/jre/lib/amd64/libdecora_sse.so \
    $JAVA_HOME/jre/lib/amd64/libprism_*.so \
    $JAVA_HOME/jre/lib/amd64/libfxplugins.so \
    $JAVA_HOME/jre/lib/amd64/libglass.so \
    $JAVA_HOME/jre/lib/amd64/libgstreamer-lite.so \
    $JAVA_HOME/jre/lib/amd64/libjavafx*.so \
    $JAVA_HOME/jre/lib/amd64/libjfx*.so \
    $JAVA_HOME/jre/bin/jjs \
    $JAVA_HOME/jre/bin/keytool \
    $JAVA_HOME/jre/bin/orbd \
    $JAVA_HOME/jre/bin/pack200 \
    $JAVA_HOME/jre/bin/policytool \
    $JAVA_HOME/jre/bin/rmid \
    $JAVA_HOME/jre/bin/rmiregistry \
    $JAVA_HOME/jre/bin/servertool \
    $JAVA_HOME/jre/bin/tnameserv \
    $JAVA_HOME/jre/bin/unpack200 \
    $JAVA_HOME/jre/lib/ext/nashorn.jar \
    $JAVA_HOME/jre/lib/jfr.jar \
    $JAVA_HOME/jre/lib/jfr \
    $JAVA_HOME/jre/lib/oblique-fonts

FROM hadoop_install as java_install
ARG TARGETPLATFORM
COPY glibc-2.32-r0.apk ./
COPY glibc-2.32-r0-aarch64.apk ./
RUN if [ "${TARGETPLATFORM}" == "linux/arm64" ] || [ "${TARGETPLATFORM}" == "linux/arm64/v8" ] || [ "${TARGETPLATFORM}" == "linux/arm/v8" ]; then \
    apk add --no-cache --allow-untrusted glibc-2.32-r0-aarch64.apk; \
    else apk add --no-cache --allow-untrusted glibc-2.32-r0.apk; \
    fi
RUN rm glibc-2.32-r0.apk glibc-2.32-r0-aarch64.apk
COPY --from=java_extract /usr/lib/jvm/ /usr/lib/jvm
ENV JAVA_HOME /usr/lib/jvm/jdk1.8.0_371

FROM java_install as env_conf
RUN echo -e "export JAVA_HOME=$JAVA_HOME\n \
    export PATH=\$PATH:\$JAVA_HOME/bin" > /etc/profile.d/jdk-env.sh
# I've done this cause i need the user hadoop can have this envs
RUN echo -e "export HADOOP_HOME=/opt/hadoop\n\
    export PATH=\$PATH:\$HADOOP_HOME/bin:\$HADOOP_HOME/sbin\n\
    export HADOOP_CONF_DIR=\$HADOOP_HOME/etc/hadoop" > /etc/profile.d/hadoop-env.sh
RUN echo "export JAVA_HOME=$JAVA_HOME" | tee -a /opt/hadoop/etc/hadoop/hadoop-env.sh > /dev/null

FROM env_conf
ENV MASTER_HOSTNAME ""
ENV MASTER_HADOOP_PASSWORD ""
ENV REPLICAS 0
ENV PASSWORD "1234"
ENV HOSTNAME ""

COPY start.sh /entry/start.sh
RUN chmod +x /entry/start.sh
WORKDIR /home/hadoop

ENTRYPOINT [ "/entry/start.sh" ]
CMD [ "-d" ]