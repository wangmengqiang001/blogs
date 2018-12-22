把Oracle XE用于为开发者搭建个人的开发环境虽然比较轻便，但是要想做到可随时的环境重建，最好还是借助容器技术。目前Oracle还没有官方提供的XE版镜像，在docker hub上却能找到很多人做出的镜像了。  

# 问题  
用 docker.io/alexeiled/docker-oracle-xe-11g 是不错的选择，但再好的选择也不能包治百病，在使用中也会遇到需要你自己来理的问题，比如字符集这个'水土不服'的问题。在通过容器提供的机制执行建库和数据库导入时也会遇到汉字出现乱码，以及插入数据超长，和sql脚本执行中提示语句不完整等错误。

# 原因
当然出现中文乱码要从字符集来来考虑原因，在与数据库相关时则要考虑的更多，比如：数据库的字符集，会话的字符集，客户端显示所用的字符集，所执行的sql脚本的字符集等。其中处理不当就会出现脚本不能被正常解释(提示脚本错误)，数据不能被正常显示(数据被混乱转码，最终显示为乱码)，数据溢出(在不同字符集下长度不同导致子串超长)等。   
# 处理
在制作oracle xe镜像中执行的类似于静默安装，在11g中还不能指定数据库的字符集(在高版本中可以了)，建立的数据库的字符集是AL32UTF8，如果通过容器启动中执行sql进行数据库的初始化，则也会因为sqlplus会话与所执行的sql文件的字符集的不匹配导致转码后数据编码损坏而变乱的。所以要做到如下三点：  
> 1. 修改数据库的字符集  
> 2. 通过环境变量控制会话的字符集
> 3. 确保sql文件的字符集和会话字符集一致    

最后虽然做到客户端显示所用的字符集与会话的字符集一致也很关键，但却它只影响显示，不会导致数据损坏或执行异常，不如以上几点重要。

- 修改数据库的字符集

修改字符集的操作是通过如下的代码
````
sql> shutdown immediate;
sql> startup restrict;
sql> ALTER DATABASE character set INTERNAL_USE ZHS16GBK;
sql> shutdown immediate;
sql> startup;
sql> quit;
````
上述命令将字符集转变为ZHS16GBK。
为能在容器启动时执行以上命令，把它们写入的一个shell脚本中，通过控制台输入重定向加载以在容器启动时被执行，另外为了能直接以sysdba执行把执行的用户切换为oracle, 因此才有【参见链接】内中的脚本文件。
 
**在shell脚本中通过输入重定向执行sql脚本**
````
[root@002 ]# cat changeset.shx 
#!/bin/sh

/u01/app/oracle/product/11.2.0/xe/bin/sqlplus / as sysdba<<EOF
shutdown ...;
...
startup;
quit;
EOF

````
**作为oracle用户执行shell脚本**
````
#!/bin/sh

su  oracle -s /etc/entrypoint-initdb.d/changeset.shx

````


- 通过环境变量控制会话的字符集
在容器中通过sqlplus执行挂载目录中的sql文件，但sqlplus在执行时根据其环境选择与服务器会话的字符集，为保证包含着中文信息的sql文件能被正确解析，需要通过设置NLS_LANG来确保会话使用了预定的字符集。去构建新的镜像设置语言环境是一种方式，但也仅为此就去构建一个新的镜像。通过启动容器时用-e 设置环境变量就可以实现，比如：
````
docker run -d --shm-size=1g -p 8080:8080 -p 1521:1521 \
-e NLS_LANG="SIMPLIFIED CHINESE_CHINA.UTF8" \
-v /local-initdb:/etc/entrypoint-initdb.d alexeiled/docker-oracle-xe-11g
````
它把会话字符集设置为了UTF8

- 确保sql文件的字符集和会话字符集一致 
通过notepad++等工具把sql文件的字符集转换为和会话一致的(如上是UTF8)。

示例参见[链接]()
脚本名称为a.sh是为了它能被第一执行。


另外，虽然用容器启动oracle xe是比较便捷的，但是缺点是在容器重新启动时会出现重新初始化数据和数据丢失的问题，为避免应该通过存储挂载把库文件持久化到容器外面，并需要在初始化脚本中加上判断和处理，在数据文件已经存在时不执行初始化脚本而是进行已有文件的导入处理，这计划另起篇章。

- 参考
[oracle字符集转换(ZHS16GBK转AL32UTF8)](http://blog.itpub.net/25462274/viewspace-2135855/)   
[Docker hub: alexeiled/docker-oracle-xe-11g](https://hub.docker.com/r/alexeiled/docker-oracle-xe-11g)  
[sqlplus 与 shell 结合--shell中执行sql 脚本](https://blog.csdn.net/fxyfdf/article/details/59626298)



