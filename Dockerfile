FROM alpine:3.6
EXPOSE 22
USER root

EXPOSE 9870

RUN apk update
RUN apk add --no-cache vim bash openjdk8 curl openssh nss sshpass rsync procps

RUN adduser -h /home/hadoop -s /bin/sh -D hadoop
RUN echo -n 'hadoop:1234' | chpasswd

RUN ssh-keygen -q -N "" -t ed25519 -f /etc/ssh/ssh_host_ed25519_key

# Install and configure hadoop #
ADD hadoop-3.3.5.tar.gz /usr/local/
RUN mkdir -p /opt && ln -s /usr/local/hadoop-3.3.5 /opt/hadoop
RUN mkdir -p /mnt/hadoop/datanode
RUN mkdir -p /mnt/hadoop/namenode
ADD core-site.xml /opt/hadoop/etc/hadoop/core-site.xml
ADD hdfs-site.xml /opt/hadoop/etc/hadoop/hdfs-site.xml
RUN chown -R hadoop:hadoop /usr/local/hadoop-3.3.5 /mnt/hadoop

## This envs doesn't work properly, they need to be appended to the spesific user "hadoop"
RUN echo "export JAVA_HOME=/usr/lib/jvm/java-1.8-openjdk" >> /etc/profile.d/java-config.sh
RUN echo "export PATH=\$PATH:\$JAVA_HOME/bin" >> /etc/profile.d/java-config.sh
RUN echo "export HADOOP_HOME=/opt/hadoop" >> /etc/profile.d/hadoop-config.sh
RUN echo "export PATH=\$PATH:\$HADOOP_HOME/bin:\$HADOOP_HOME/sbin" >> /etc/profile.d/hadoop-config.sh
RUN echo "export HADOOP_CONF_DIR=\$HADOOP_HOME/etc/hadoop" >> /etc/profile.d/hadoop-config.sh
RUN echo "export JAVA_HOME=/usr/lib/jvm/java-1.8-openjdk" | tee -a /opt/hadoop/etc/hadoop/hadoop-env.sh > /dev/null

ENV MASTER_HOSTNAME ""
ENV MASTER_HADOOP_PASSWORD ""

COPY start.sh /tmp/start.sh
RUN chmod +x /tmp/start.sh

ENTRYPOINT [ "/tmp/start.sh" ]
CMD [ "-d" ]