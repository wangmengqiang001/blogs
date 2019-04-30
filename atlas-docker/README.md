# Apache Atlas in Docker

在按照apache atlas的文档启动应用时，总是失败，发现其对运行环境有些要求，但在文档中并没有说明，比如在运行环境中必须要有JAVA_HOME，否则hbase是不能被启动起来的，但是却没有错误提示，而给出的提示确是hbase已启动。

在多天的折腾后，在另外一台机器上才启动成功了。看来还是需要通过容器摆脱对环境的依赖。

编译成功后在distro/target下有文件apache-atlas-1.1.0-server.tar.gz，它是要打入镜像中的程序包。

以下为制作镜像的Dockerfile文件的内容：
````
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
````




- 验证hbase启动的方法

方法一：
````
[root@002 ~]# jps
1238 WrapperSimpleApp
21686 HMaster
21771 jar
21933 Jps

````

方法二：

````
[root@002 hbase]# bin/hbase shell
2019-04-29 09:56:54,732 WARN  [main] util.NativeCodeLoader: Unable to load native-hadoop library for your platform... using builtin-java classes where applicable
HBase Shell; enter 'help<RETURN>' for list of supported commands.
Type "exit<RETURN>" to leave the HBase Shell
Version 1.1.2, rcc2b70cf03e3378800661ec5cab11eb43fafe0fc, Wed Aug 26 20:11:27 PDT 2015

hbase(main):001:0> list
TABLE 

````


- 验证solr启动的方法

````
cd solr
bin/solr status

````

* 注:     
hbase会启动一个内置的zookeeper, 所以如果hbase正常启动应该可以看到zookeeper 被成功启动了，存在了2181端口的服务。

- 参考资料    
[atlas-docker](https://github.com/michalmiklas/atlas-docker)  


