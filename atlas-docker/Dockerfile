FROM openjdk:8-jdk-alpine

RUN apk add --no-cache \
    bash \
    su-exec \
    python

ADD apache-atlas-1.1.0-server.tar.gz /



WORKDIR /apache-atlas-1.1.0

EXPOSE 21000

ENV PATH=$PATH:/apache-atlas-1.1.0

# if the memory is enough large
# ENV ATLAS_SERVER_HEAP="-Xms15360m -Xmx15360m -XX:MaxNewSize=5120m -XX:MetaspaceSize=100M -XX:MaxMetaspaceSize=512m"
ENV MANAGE_LOCAL_HBASE=true
ENV MANAGE_LOCAL_SOLR=true
ENV MANAGE_EMBEDDED_CASSANDRA=false
ENV MANAGE_LOCAL_ELASTICSEARCH=false

CMD ["/bin/bash", "-c", "/apache-atlas-1.1.0/bin/atlas_start.py; tail -f /apache-atlas-1.1.0/logs/application.log"]
