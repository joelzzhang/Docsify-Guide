## 一. 环境准备

### 1. 环境规划

| IP             | hostname  | 角色                                                         | 组件                                                         |
| -------------- | --------- | ------------------------------------------------------------ | ------------------------------------------------------------ |
| 192.168.31.100 | bigdata01 | Zookeeper、JournalNode、NameNode、ResourceManager、ZKFC      | HDFS、YARN、Zookeeper                                        |
| 192.168.31.101 | bigdata02 | Zookeeper、JournalNode、NameNode、ResourceManager、ZKFC、HistoryServer | HDFS、YARN、Zookeeper                                        |
| 192.168.31.102 | bigdata03 | Zookeeper、JournalNode、DataNode  、NodeManager、KDC、JobHistoryServer | HDFS、YARN、Zookeeper、krb5-server、krb5-workstation、krb5-libs |
| 192.168.31.103 | bigdata04 | DataNode 、NodeManager、KDC                                  | HDFS、YARN、krb5-server、krb5-workstation、krb5-libs         |

### 2. 安装包准备

```shell
tar -zxvf hadoop-3.3.6.tar.gz -C /opt
```

### 3. 配置环境变量

```shell
# 将hadoop-3.3.6软连接到/usr/local/hadoop3
ln -s /opt/hadoop-3.3.6 /usr/local/hadoop3

# 添加hadoop.sh，配置HADOOP_HOME的环境变量
vim /etc/profile.d/hadoop.sh
#!/bin/bash

export HADOOP_HOME=/usr/local/hadoop3
export PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin 

# 刷新变量
source /etc/profile
```

### 4. 数据盘挂载

## 二. HADOOP高可用集群配置

> [!TIP|label:配置参考]
>
> https://hadoop.apache.org/docs/r3.3.6/hadoop-project-dist/hadoop-common/ClusterSetup.html

### 1.  配置hadoop-env.sh

```shell
export JAVA_HOME=/usr/local/java/jdk-11.0.28
export HDFS_ZKFC_OPTS="-Djava.security.auth.login.config=/usr/local/hadoop3/etc/hadoop/zk-jaas.conf -Djava.security.krb5.conf=/etc/krb5.conf"
```

### 2. 配置core-site.xml

```xml
<configuration>
    <property>
        <name>fs.defaultFS</name>
        <value>hdfs://hadoopcluster</value>
        <description>namenode的hdfs协议文件系统的通信地址,客户端连接HDFS时,为Hadoop客户端配置默认的高可用路径前缀</description>
    </property>
    <property>
        <name>hadoop.tmp.dir</name>
        <value>/data/hadoop</value>
        <description>
            指定 hadoop 运行时产生文件的存储目录
            Hadoop数据存放的路径namenode,datanode数据存放路径都依赖本路径。
            不要使用"file:///"开头，使用绝对路径即可。
            namenode默认存储路径:
            file://${hadoop.tmp.dir}/dfs/name
            datanode默认存储路径
            file://${hadoop.tmp.dir}/dfs/data
        </description>
    </property>
    <property>
        <name>ha.zookeeper.quorum</name>
        <value>hadoop1:2181,hadoop2:2181,hadoop3:2181</value>
        <description>指定 zkfc 要连接的 zkServer 地址</description>
    </property>
    <property>
        <name>ha.zookeeper.session-timeout.ms</name>
        <value>8000</value>
        <description>ZKFC连接到ZooKeeper的超时时长</description>
    </property>
    <property>
        <name>ha.health-monitor.rpc-timeout.ms</name>
        <value>180000</value>
        <description>实际monitorHealth()调用超时时间</description>
    </property>
    <property>
        <name>ipc.client.connect.max.retries</name>
        <value>20</value>
        <description>NN 连接 JN 重试次数，默认是 10 次</description>
    </property>
    <property>
        <name>ipc.client.connection.maxidletime</name>
        <value>30000</value>
        <description>空间连接断开时间，单位为毫秒</description>
    </property>
    <property>
        <name>ipc.client.connect.retry.interval</name>
        <value>5000</value>
        <description>重试时间间隔，默认 1s</description>
    </property>
    <property>
        <name>io.compression.codec.lzo.class</name>
        <value>com.hadoop.compression.lzo.LzoCodec</value>
        <description>配置lzo编解码器相关参数</description>
    </property>
    <property>
        <name>io.compression.codecs</name>
        <value>
            org.apache.hadoop.io.compress.GzipCodec,org.apache.hadoop.io.compress.DefaultCodec,org.apache.hadoop.io.compress.SnappyCodec,com.hadoop.compression.lzo.LzoCodec,com.hadoop.compression.lzo.LzopCodec</value>
        <description>一组可用于压缩/解压缩的表列表, 使用逗号进行分隔</description>
    </property>
    <property>
        <name>io.file.buffer.size</name>
        <value>131072</value>
        <description>在序列文件中使用的缓冲区大小</description>
    </property>
    <property>
        <name>fs.du.interval</name>
        <value>43200000</value>
        <description>文件空间使用统计情况的刷新时间间隔</description>
    </property>
    <property>
        <name>fs.trash.checkpoint.interval</name>
        <value>360</value>
        <description>检查点之间的时间间隔, 此属性的值应该小于fs.trash.interval属性的值</description>
    </property>
    <property>
        <name>fs.trash.interval</name>
        <value>10080</value>
        <description>检查点被删除的时间间隔, 单位为分钟</description>
    </property>
    <property>
        <name>fs.permissions.umask-mode</name>
        <value>022</value>
        <description>创建文件或目录时的umask</description>
    </property>
</configuration>
```

### 3. 配置hdfs-site.xml

```xml
<configuration>
    <property>
        <name>dfs.namenode.name.dir</name>
        <value>file:${hadoop.tmp.dir}/name</value>
        <description>NameNode 元数据存放位置,多个目录以逗号分隔</description>
    </property>
    <property>
        <name>dfs.journalnode.edits.dir</name>
        <value>${hadoop.tmp.dir}/journalnode</value>
        <description>JournalNode 数据存储目录</description>
    </property>
    <property>
        <name>dfs.datanode.data.dir</name>
        <value>/data01/hdfs</value>
        <description>DataNode 数据存储目录，多个目录则用,分割</description>
    </property>

    <property>
        <name>dfs.blocksize</name>
        <value>134217728</value>
        <description>blocksize 数据块大小128M</description>
    </property>
    <property>
        <name>dfs.replication</name>
        <value>2</value>
        <description>数据副本数量</description>
    </property>
    <property>
        <name>dfs.datanode.max.transfer.threads</name>
        <value>4096</value>
        <description>datanode进行传输数据的最大线程数</description>
    </property>
    <property>
        <name>dfs.datanode.failed.volumes.tolerated</name>
        <value>1</value>
        <description>决定停止数据节点提供服务允许卷的出错次数, 0则表示任何卷出错都要停止数据节点</description>
    </property>

    <property>
        <name>dfs.permissions.superusergroup</name>
        <value>hadoop</value>
        <description>超级用户用户组</description>
    </property>

    <property>
        <name>dfs.internal.nameservices</name>
        <value>hadoopcluster</value>
        <description>集群内部通信名称</description>
    </property>
    <property>
        <name>dfs.nameservices</name>
        <value>hadoopcluster</value>
        <description>完全分布式集群名称</description>
    </property>
    <property>
        <name>dfs.ha.namenodes.hadoopcluster</name>
        <value>nn1,nn2</value>
        <description>集群中 NameNode 节点都有哪些</description>
    </property>
    <property>
        <name>dfs.namenode.rpc-address.hadoopcluster.nn1</name>
        <value>hadoop1:54310</value>
        <description>NameNode 的 RPC 通信地址(客户端连接使用)</description>
    </property>
    <property>
        <name>dfs.namenode.servicerpc-address.hadoopcluster.nn1</name>
        <value>hadoop1:53310</value>
        <description>NameNode 的 RPC 通信地址(DataNode等内部服务连接使用,为空则与rpc-address地址相同)</description>
    </property>
    <property>
        <name>dfs.namenode.http-address.hadoopcluster.nn1</name>
        <value>hadoop1:50070</value>
        <description>NameNode 的 RPC 通信地址</description>
        <description>
            NameNode 的 http 通信地址
            语法格式: "dfs.namenode.rpc-address.[nameservice ID].[namenode ID]"
        </description>
    </property>
    <property>
        <name>dfs.namenode.rpc-address.hadoopcluster.nn1</name>
        <value>hadoop1:54310</value>
        <description>NameNode 的 RPC 通信地址</description>
    </property>
    <property>
        <name>dfs.namenode.servicerpc-address.hadoopcluster.nn1</name>
        <value>hadoop1:53310</value>
    </property>
    <property>
        <name>dfs.namenode.http-address.hadoopcluster.nn2</name>
        <value>hadoop3:50070</value>
        <description>
            NameNode 的 http 通信地址
            语法格式: "dfs.namenode.rpc-address.[nameservice ID].[namenode ID]"
        </description>
    </property>

    <property>
        <name>dfs.namenode.shared.edits.dir</name>
        <value>qjournal://hadoop1:8485;hadoop2:8485;hadoop3:8485/hadoopcluster</value>
        <description>指定 NameNode 元数据在 JournalNode 上的存放位置 </description>
    </property>
    <property>
        <name>dfs.journalnode.rpc-address</name>
        <value>0.0.0.0:8485</value>
        <description>JournalNode RPC地址</description>
    </property>
    <property>
        <name>dfs.journalnode.http-address</name>
        <value>0.0.0.0:8480</value>
        <description>JournalNode HTTP地址</description>
    </property>

    <property>
        <name>dfs.ha.automatic-failover.enabled</name>
        <value>true</value>
        <description>启用 nn 故障自动转移</description>
    </property>
    <property>
        <name>dfs.client.failover.proxy.provider.hadoopcluster</name>
        <value>org.apache.hadoop.hdfs.server.namenode.ha.ConfiguredFailoverProxyProvider</value>
        <description>访问代理类:client 用于确定哪个 NameNode 为 Active</description>
    </property>

    <property>
        <name>dfs.ha.fencing.methods</name>
        <value>sshfence(hdfs:22)
            shell(/bin/true)
        </value>
        <description>配置隔离机制，即同一时刻只能有一台服务器对外响应</description>
    </property>
    <property>
        <name>dfs.ha.fencing.ssh.private-key-files</name>
        <value>/root/.ssh/id_rsa</value>
        <description>使用隔离机制时需要 ssh 秘钥登录</description>
    </property>

    <property>
        <name>dfs.permissions.enabled</name>
        <value>true</value>
        <description>HDFS中是否启用权限检查</description>
    </property>

    <property>
        <name>dfs.namenode.handler.count</name>
        <value>10</value>
    </property>
    <property>
        <name>dfs.datanode.handler.count</name>
        <value>10</value>
    </property>
    <property>
        <name>dfs.namenode.service.handler.count</name>
        <value>10</value>
    </property>

    <property>
        <name>dfs.webhdfs.enabled</name>
        <value>true</value>
    </property>
    <property>
        <name>dfs.namenode.acls.enabled</name>
        <value>true</value>
    </property>
    <property>
        <name>dfs.namenode.audit.log.async</name>
        <value>true</value>
    </property>
    <property>
        <name>dfs.qjournal.write-txns.timeout.ms</name>
        <value>120000</value>
    </property>
    <property>
        <name>dfs.cluster.administrators</name>
        <value>hdfs</value>
    </property>
    <property>
        <name>dfs.client.socket-timeout</name>
        <value>180000</value>
    </property>
</configuration>
```
### 4. 配置yarn-site.xml

```xml
<configuration>
    <property>
        <name>yarn.resourcemanager.recovery.enabled</name>
        <value>true</value>
        <description>启用自动恢复</description>
    </property>
    <property>
        <name>yarn.resourcemanager.store.class</name>
        <value>org.apache.hadoop.yarn.server.resourcemanager.recovery.ZKRMStateStore</value>
        <description>指定 resourcemanager 的状态信息存储在 zookeeper 集群</description>
    </property>

    <property>
        <name>yarn.resourcemanager.zk-address</name>
        <value>hadoop1:2181,hadoop2:2181,hadoop3:2181</value>
        <description>指定 zookeeper 集群的地址</description>
    </property>
    <property>
        <name>yarn.resourcemanager.ha.enabled</name>
        <value>true</value>
        <description>启用 resourcemanager ha</description>
    </property>

    <property>
        <name>yarn.resourcemanager.cluster-id</name>
        <value>rm</value>
        <description>声明两台 resourcemanager 的地址</description>
    </property>

    <property>
        <name>yarn.resourcemanager.ha.rm-ids</name>
        <value>rm1,rm2</value>
        <description>指定 resourcemanager 的逻辑列表</description>
    </property>

    <!-- ========== rm1 的配置 ========== -->
    <property>
        <name>yarn.resourcemanager.hostname.rm1</name>
        <value>hadoop1</value>
        <description>指定 rm1 的主机名</description>
    </property>
    <property>
        <name>yarn.resourcemanager.webapp.address.rm1</name>
        <value>hadoop1:8088</value>
        <description>指定 rm1 的 web 端地址</description>
    </property>
    <property>
        <name>yarn.resourcemanager.address.rm1</name>
        <value>hadoop1:8032</value>
        <description>指定 rm1 的内部通信地址</description>
    </property>
    <property>
        <name>yarn.resourcemanager.scheduler.address.rm1</name>
        <value>hadoop1:8030</value>
        <description>指定 AM(Application Master) 向 rm1 申请资源的地址</description>
    </property>
    <property>
        <name>yarn.resourcemanager.resource-tracker.address.rm1</name>
        <value>hadoop1:8031</value>
        <description>指定供 NM 连接的地址</description>
    </property>

    <!-- ========== rm2 的配置 ========== -->
    <property>
        <name>yarn.resourcemanager.hostname.rm2</name>
        <value>hadoop2</value>
        <description>指定 rm2 的主机名</description>
    </property>
    <property>
        <name>yarn.resourcemanager.webapp.address.rm2</name>
        <value>hadoop2:8088</value>
        <description>指定 rm2 的 web 端地址</description>
    </property>
    <property>
        <name>yarn.resourcemanager.address.rm2</name>
        <value>hadoop2:8032</value>
        <description>指定 rm2 的内部通信地址</description>
    </property>
    <property>
        <name>yarn.resourcemanager.scheduler.address.rm2</name>
        <value>hadoop2:8030</value>
        <description>指定 AM(Application Master) 向 rm2 申请资源的地址</description>
    </property>
    <property>
        <name>yarn.resourcemanager.resource-tracker.address.rm2</name>
        <value>hadoop2:8031</value>
        <description>指定供 NM 连接的地址</description>
    </property>

    <property>
        <name>yarn.nodemanager.address</name>
        <value>0.0.0.0:45454</value>
    </property>

    <property>
        <name>yarn.nodemanager.aux-services</name>
        <value>mapreduce_shuffle,spark_shuffle</value>
        <description></description>
    </property>
    <property>
        <name>yarn.nodemanager.aux-services.mapreduce_shuffle.class</name>
        <value>org.apache.hadoop.mapred.ShuffleHandler</value>
        <description></description>
    </property>
    <property>
        <name>yarn.nodemanager.aux-services.spark_shuffle.class</name>
        <value>org.apache.spark.network.yarn.YarnShuffleService</value>
    </property>

    <property>
        <name>yarn.log-aggregation-enable</name>
        <value>true</value>
        <description>开启日志聚集功能</description>
    </property>
    <property>
        <name>yarn.log.server.url</name>
        <value>http://bigdata03:19888/jobhistory/logs</value>
        <description>设置日志聚集服务器地址</description>
    </property>
    <property>
        <name>yarn.nodemanager.log.retain-seconds</name>
        <value>604800</value>
    </property>
    <property>
        <name>yarn.log-aggregation.retain-seconds</name>
        <value>604800</value>
        <description>设置日志保留时间为 7 天</description>
    </property>

    <property>
        <description>Where to aggregate logs to.(hdfs)</description>
        <name>yarn.nodemanager.remote-app-log-dir</name>
        <value>/yarn/apps</value>
    </property>
    <property>
        <description>Where to aggregate logs to.</description>
        <name>yarn.nodemanager.remote-app-log-dir-suffix</name>
        <value>logs</value>
    </property>
    <property>
        <name>yarn.nodemanager.local-dirs</name>
        <value>${hadoop.tmp.dir}/nm-local-dir</value>
        <description>设置datanode节点存储数据文件的本地路径</description>
    </property>
    <property>
        <name>yarn.nodemanager.log-dirs</name>
        <value>${yarn.log.dir}/userlogs</value>
        <description>namenode元数据存放位置</description>
    </property>
    <property>
        <name>yarn.application.classpath</name>
        <value>
            /etc/hadoop/conf,/usr/local/hadoop3/share/hadoop/mapreduce/*,/usr/local/hadoop3/share/hadoop/mapreduce/lib/*,/usr/local/hadoop3/share/hadoop/common/*,/usr/local/hadoop3/share/hadoop/common/lib/*,/usr/local/hadoop3/share/hadoop/yarn/*,/usr/local/hadoop3/share/hadoop/yarn/lib/*,/usr/local/hadoop3/share/hadoop/hdfs/*,/usr/local/hadoop3/share/hadoop/hdfs/lib/*,/usr/lib/hadoop/lib/*</value>
    </property>
    <property>
        <name>yarn.resourcemanager.scheduler.class</name>
        <value>org.apache.hadoop.yarn.server.resourcemanager.scheduler.capacity.CapacityScheduler</value>
    </property>
    <property>
        <name>yarn.nodemanager.resource.memory-mb</name>
        <value>4096</value>
        <description>为容器分配的物理内存量（以MB为单位），默认为8192MB。</description>
    </property>
    <property>
        <name>yarn.scheduler.minimum-allocation-mb</name>
        <value>1024</value>
        <description>在RM（资源管理器）中，每个容器请求的最小分配为MB。低于此值的内存请求将被设置为该属性的值。此外，配置为具有低于此值的内存的节点管理器将被资源管理器关闭。</description>
    </property>
    <property>
        <name>yarn.nodemanager.vmem-check-enabled</name>
        <value>false</value>
        <description>是否会对容器强制执行虚拟内存限制。</description>
    </property>
    <property>
        <name>yarn.scheduler.maximum-allocation-mb</name>
        <value>4096</value>
        <description>在RM中，每个容器请求的最大分配为MB。内存请求超过这个值将抛出InvalidResourceRequestException异常。</description>
    </property>
    <property>
        <name>yarn.nodemanager.resource.cpu-vcores</name>
        <value>8</value>
        <description>容器可分配的vcore数量。资源管理器调度器在为容器分配资源时使用此数量。这不会用于限制YARN容器使用的CPU数量。在其他情况下，vcore数量默认为8。</description>
    </property>
    <property>
        <name>yarn.scheduler.minimum-allocation-vcores</name>
        <value>1</value>
        <description>
            在RM中，每个容器请求的最低分配是以虚拟CPU核心为单位的。低于此值的请求将被设置为该属性的值。此外，配置为具有比此值更少虚拟核心的节点管理器将由资源管理器关闭。</description>
    </property>
    <property>
        <name>yarn.scheduler.maximum-allocation-vcores</name>
        <value>8</value>
        <description>在RM（资源管理器）中，每个容器请求的虚拟CPU核心的最大分配。高于此值的请求将抛出InvalidResourceRequestException异常。</description>
    </property>

    <property>
        <name>yarn.acl.enable</name>
        <value>true</value>
    </property>
    <property>
        <name>yarn.nodemanager.webapp.cross-origin.enabled</name>
        <value>true</value>
    </property>
    <property>
        <name>yarn.nodemanager.log-aggregation.compression-type</name>
        <value>gz</value>
    </property>

    <property>
        <name>yarn.nodemanager.env-whitelist</name>
        <value>
            JAVA_HOME,HADOOP_COMMON_HOME,HADOOP_HDFS_HOME,HADOOP_CONF_DIR,CLASSPATH_PREPEND_DISTCACHE,HADOOP_YARN_HOME,HADOOP_HOME,PATH,LANG,TZ,HADOOP_MAPRED_HOME
        </value>
        <description>环境变量的继承</description>
    </property>
</configuration>
```

### 5. 配置mapred-site.xml 

```xml
<configuration>
	<property>
		<name>mapreduce.framework.name</name>
		<value>yarn</value>
        <description>声明MapReduce框架在YARN上运行</description>
	</property>
    
    <property>
      <name>yarn.app.mapreduce.am.env</name>
      <value>HADOOP_MAPRED_HOME=${HADOOP_HOME}</value>
      <description>设置环境变量，多个值用逗号分隔，也可以在mapreduce程序中通过-Dyarn.app.mapreduce.am.env.HADOOP_MAPRED_HOME=XXX来设置</description>
    </property>
    <property>
      <name>mapreduce.map.env</name>
      <value>HADOOP_MAPRED_HOME=${HADOOP_HOME}</value>
    </property>
    <property>
      <name>mapreduce.reduce.env</name>
      <value>HADOOP_MAPRED_HOME=${HADOOP_HOME}</value>
    </property>  

    <property>
        <name>mapreduce.jobhistory.address</name>
        <value>bigdata03:10020</value>
        <description>历史服务器端地址</description>
    </property>

    <property>
        <name>mapreduce.jobhistory.webapp.address</name>
        <value>bigdata03:19888</value>
        <description>历史服务器 web 端地址</description>
    </property>
    <property>
        <name>yarn.app.mapreduce.am.log.level</name>
        <value>INFO</value>
        <description>MR ApplicationMaster 的日志记录级别</description>
    </property>
    <property>
        <name>mapreduce.reduce.log.level</name>
        <value>INFO</value>
        <description>日志级别</description>
    </property>
    <property>
        <name>mapreduce.map.log.level</name>
        <value>INFO</value>
        <description>Map端日志级别 </description>
    </property>
    <property>
        <name>mapreduce.output.fileoutputformat.compress.codec</name>
        <value>org.apache.hadoop.io.compress.SnappyCodec</value>
        <description>设置mapreduce最终数据输出压缩为snappy压缩</description>
    </property>
</configuration>
```

### 6. 配置workers文件

```shell
cat /opt/hadoop-3.3.6/etc/hadoop/workers 
hadoop1
hadoop2
hadoop3
```

## 三. HADOOP高可用集群初始化

### 1. 启动Zookeeper集群

在每个`Zookeeper`节点上启动`Zookeeper`

```bash
bin/zkServer.sh start
bin/zkServer.sh status
```

### 2. 初始化Zookeeper Node

首次启动`DFSZKFailoverController`前需要初始化`Zookeeper Node`

```bash
hdfs zkfc -formatZK
```

在`Zookeeper`客户端可以看到多了`/hadoop-ha/hadoopcluster`节点

```bash
[zk: bigdata02:2181(CONNECTED) 0] ls /
[hadoop-ha, zookeeper]
[zk: bigdata02:2181(CONNECTED) 6] ls /hadoop-ha
[hadoopcluster]
```

### 3. 启动journalnode

```bash
hdfs --daemon start journalnode
```

### 4. 格式化NameNode

首次启动前需要对`NameNode`进行格式化，在任意一个`NameNode`节点上执行即可

```bash
hdfs namenode -format
```

### 5. 初始化NameNode

在第一个`NameNode`节点上启动

```bash
hdfs --daemon start namenode
```

在第二个节点同步数据并启动`NameNode`(只需第一次)

```bash
hdfs namenode -bootstrapStandby
```

### 6. 启动HDFS集群

hadoop3.X新特性，需要在`${HADOOP_HOME}/sbin`目录下，`start-dfs.sh`,`stop-dfs.sh`,`start-yarn.sh`,`stop-yarn.sh`内，分别新增如下配置： 

```properties
HDFS_NAMENODE_USER=hdfs
HDFS_DATANODE_USER=hdfs
HDFS_JOURNALNODE_USER=hdfs
HDFS_ZKFC_USER=hdfs
HDFS_DATANODE_SECURE_USER=hdfs
HDFS_SECONDARYNAMENODE_USER=hdfs
YARN_NODEMANAGER_USER=yarn
YARN_RESOURCEMANAGER_USER=yarn
```

并在`master`节点对集群的其他节点进行免密登录配置，然后执行以下命令：

```bash
# 启动hdfs集群
start-dfs.sh
# 停止hdfs集群
stop-dfs.sh
```

验证集群：

```bash
[root@bigdata01 hadoop3]# hdfs dfsadmin -report
Configured Capacity: 64288194560 (59.87 GB)
Present Capacity: 63771869184 (59.39 GB)
DFS Remaining: 62271758336 (58.00 GB)
DFS Used: 1500110848 (1.40 GB)
DFS Used%: 2.35%
Replicated Blocks:
	Under replicated blocks: 22
	Blocks with corrupt replicas: 0
	Missing blocks: 0
	Missing blocks (with replication factor 1): 0
	Low redundancy blocks with highest priority to recover: 0
	Pending deletion blocks: 0
Erasure Coded Block Groups: 
	Low redundancy block groups: 0
	Block groups with corrupt internal blocks: 0
	Missing block groups: 0
	Low redundancy blocks with highest priority to recover: 0
	Pending deletion blocks: 0

-------------------------------------------------
Live datanodes (2):

Name: 192.168.31.102:9866 (bigdata03)
Hostname: bigdata03
Decommission Status : Normal
Configured Capacity: 32144097280 (29.94 GB)
DFS Used: 750055424 (715.31 MB)
Non DFS Used: 258162688 (246.20 MB)
DFS Remaining: 31135879168 (29.00 GB)
DFS Used%: 2.33%
DFS Remaining%: 96.86%
Configured Cache Capacity: 0 (0 B)
Cache Used: 0 (0 B)
Cache Remaining: 0 (0 B)
Cache Used%: 100.00%
Cache Remaining%: 0.00%
Xceivers: 0
Last contact: Sat Jul 26 09:07:53 CST 2025
Last Block Report: Sat Jul 26 08:57:23 CST 2025
Num of Blocks: 100


Name: 192.168.31.103:9866 (bigdata04)
Hostname: bigdata04
Decommission Status : Normal
Configured Capacity: 32144097280 (29.94 GB)
DFS Used: 750055424 (715.31 MB)
Non DFS Used: 258162688 (246.20 MB)
DFS Remaining: 31135879168 (29.00 GB)
DFS Used%: 2.33%
DFS Remaining%: 96.86%
Configured Cache Capacity: 0 (0 B)
Cache Used: 0 (0 B)
Cache Remaining: 0 (0 B)
Cache Used%: 100.00%
Cache Remaining%: 0.00%
Xceivers: 0
Last contact: Sat Jul 26 09:07:53 CST 2025
Last Block Report: Sat Jul 26 08:57:23 CST 2025
Num of Blocks: 100
```

### 7. 启动YARN集群

由于zookeeper集群做了sasl强校验，所以需要在yarn-env.sh里面做jaas.conf相关的配置，配置如下：

```bash
vim yarn-env.sh

export YARN_RESOURCEMANAGER_OPTS="-Djava.security.auth.login.config=/usr/local/hadoop3/etc/hadoop/zk-jaas.conf -Djava.security.krb5.conf=/etc/krb5.conf"
```

启动和停止yarn集群

```bash
# 启动yarn集群
start-yarn.sh
# 停止yarn集群
stop-yarn.sh
```

验证集群：

```bash
[root@bigdata01 hadoop3]# yarn rmadmin -getAllServiceState
bigdata01:8033                                     active    
bigdata02:8033                                     standby
```

### 8. 启动历史服务器

在`JobHistoryServer`节点启动`historyserver`服务

```bash
mapred --daemon start historyserver
```

验证`mapreduce`：

```bash
hadoop jar /usr/local/hadoop3/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.3.6.jar wordcount /tmp/hadoop-root-namenode-bigdata01.log /root/wordcount/data2
```

在验证`mapreduce`时遇到的问题

```latex
[2025-07-25 14:35:38.800]Container exited with a non-zero exit code 1. Error file: prelaunch.err.
Last 4096 bytes of prelaunch.err :
Last 4096 bytes of stderr :
Error: Could not find or load main class org.apache.hadoop.mapreduce.v2.app.MRAppMaster
Caused by: java.lang.ClassNotFoundException: org.apache.hadoop.mapreduce.v2.app.MRAppMaster

Please check whether your <HADOOP_HOME>/etc/hadoop/mapred-site.xml contains the below configuration:
<property>
  <name>yarn.app.mapreduce.am.env</name>
  <value>HADOOP_MAPRED_HOME=${full path of your hadoop distribution directory}</value>
</property>
<property>
  <name>mapreduce.map.env</name>
  <value>HADOOP_MAPRED_HOME=${full path of your hadoop distribution directory}</value>
</property>
<property>
  <name>mapreduce.reduce.env</name>
  <value>HADOOP_MAPRED_HOME=${full path of your hadoop distribution directory}</value>
</property>
```

因为我在`mapred-site.xml`的`yarn.app.mapreduce.am.env`、`mapreduce.map.env`、`mapreduce.reduce.env`属性里面配置了`HADOOP_MAPRED_HOME=${HADOOP_HOME}`，在Java进程里面无法通过`${HADOOP_HOME}`来获取环境变量值，所以需要将`${HADOOP_HOME}`改成绝对路径`/usr/local/haddop3`即可

## 四.Hadoop整合Kerberos

### 1. 创建Hadoop集群用户

```bash
# 创建hadoop组
groupadd hadoop
# 创建hdfs用户
useradd -g hadoop -m -s /bin/bash hdfs
echo "123456" | sudo passwd --stdin hdfs
# 创建yarn用户
useradd -g hadoop -m -s /bin/bash yarn
echo "123456" | sudo passwd --stdin yarn
# 创建mapred用户
useradd -g hadoop -m -s /bin/bash mapred
echo "123456" | sudo passwd --stdin mapred
```

### 2. Hadoop集群目录权限调整

1. **创建日志目录**

   ```bash
   mkdir -p /var/log/hadoop/hadoop-hdfs /var/log/hadoop/hadoop-yarn /var/log/hadoop/hadoop-mapred
   ```

2. **为日志目录赋权**

   ```bash
   chown -R yarn:hadoop /var/log/hadoop/hadoop-yarn 
   chown -R mapred:hadoop /var/log/hadoop/hadoop-mapred
   chown -R hdfs:hadoop /var/log/hadoop/hadoop-hdfs
   chmod -R 755 /var/log/hadoop/*
   ```

3. **数据目录权限调整**

   ```bash
   # master节点
   chown -R hdfs:hadoop /data/hadoop
   chmod -R 755 /data/hadoop
   chmod 644 /usr/local/zookeeper/conf/keytab/zkcli.keytab
   # slave节点
   chown -R hdfs:hadoop /data01/hdfs
   chmod -R 755 /data01/hdfs
   ```

### 3. 创建Hadoop服务Kerberos主体

1. **创建主体(Principal)**

   ```bash
   kadmin.local:  addprinc -pw 123456 hdfs/bigdata01@HADOOP.COM
   kadmin.local:  addprinc -pw 123456 hdfs/bigdata02@HADOOP.COM
   kadmin.local:  addprinc -pw 123456 hdfs/bigdata03@HADOOP.COM
   
   kadmin.local:  addprinc -pw 123456 yarn/bigdata01@HADOOP.COM
   kadmin.local:  addprinc -pw 123456 yarn/bigdata02@HADOOP.COM
   kadmin.local:  addprinc -pw 123456 yarn/bigdata03@HADOOP.COM
   
   kadmin.local:  addprinc -pw 123456 mapred/bigdata01@HADOOP.COM
   kadmin.local:  addprinc -pw 123456 mapred/bigdata02@HADOOP.COM
   kadmin.local:  addprinc -pw 123456 mapred/bigdata03@HADOOP.COM
   ```

2. **生成keytab文件**

   ```bash
   kadmin.local:  xst -norandkey -k /var/kerberos/krb5kdc/keytab/hdfs.keytab  hdfs/bigdata01@HADOOP.COM
   kadmin.local:  xst -norandkey -k /var/kerberos/krb5kdc/keytab/hdfs.keytab  hdfs/bigdata02@HADOOP.COM
   kadmin.local:  xst -norandkey -k /var/kerberos/krb5kdc/keytab/hdfs.keytab  hdfs/bigdata03@HADOOP.COM
   
   kadmin.local:  xst -norandkey -k /var/kerberos/krb5kdc/keytab/yarn.keytab  yarn/bigdata01@HADOOP.COM
   kadmin.local:  xst -norandkey -k /var/kerberos/krb5kdc/keytab/yarn.keytab  yarn/bigdata02@HADOOP.COM
   kadmin.local:  xst -norandkey -k /var/kerberos/krb5kdc/keytab/yarn.keytab  yarn/bigdata03@HADOOP.COM
   
   kadmin.local:  xst -norandkey -k /var/kerberos/krb5kdc/keytab/mapred.keytab  mapred/bigdata01@HADOOP.COM
   kadmin.local:  xst -norandkey -k /var/kerberos/krb5kdc/keytab/mapred.keytab  mapred/bigdata02@HADOOP.COM
   kadmin.local:  xst -norandkey -k /var/kerberos/krb5kdc/keytab/mapred.keytab  mapred/bigdata03@HADOOP.COM
   ```

3. **分发keytab文件**

   ```bash
   ssh root@bigdata01 "mkdir -p /etc/security/keytab"
   ssh root@bigdata02 "mkdir -p /etc/security/keytab"
   ssh root@bigdata03 "mkdir -p /etc/security/keytab"
   
   chown -R root:root /etc/security/keytab
   chmod -R 644 /etc/security/keytab
   
   scp /var/kerberos/krb5kdc/keytab/hdfs.keytab root@bigdata01:/etc/security/keytab
   scp /var/kerberos/krb5kdc/keytab/yarn.keytab root@bigdata01:/etc/security/keytab
   scp /var/kerberos/krb5kdc/keytab/mapred.keytab root@bigdata01:/etc/security/keytab
   
   scp /var/kerberos/krb5kdc/keytab/hdfs.keytab root@bigdata02:/etc/security/keytab
   scp /var/kerberos/krb5kdc/keytab/yarn.keytab root@bigdata02:/etc/security/keytab
   scp /var/kerberos/krb5kdc/keytab/mapred.keytab root@bigdata02:/etc/security/keytab
   
   scp /var/kerberos/krb5kdc/keytab/hdfs.keytab root@bigdata03:/etc/security/keytab
   scp /var/kerberos/krb5kdc/keytab/yarn.keytab root@bigdata03:/etc/security/keytab
   scp /var/kerberos/krb5kdc/keytab/mapred.keytab root@bigdata03:/etc/security/keytab
   ```

### 4. 配置core-site.xml

```xml
<configuration>
    <property>
        <name>hadoop.security.authentication</name>
        <value>kerberos</value>
        <description>启用Kerberos安全认证</description>
    </property>
    <property>
        <name>hadoop.security.authorization</name>
        <value>true</value>
        <description>是否启用service级别的授权</description>
    </property>
    <property>
        <name>hadoop.security.auth_to_local</name>
        <value>
            RULE:[2:$1/$2@$0]([ndj]n/.*@HADOOP.COM)s/.*/hdfs/
            RULE:[2:$1/$2@$0]([rn]m/.*@HADOOP.COM)s/.*/yarn/
            RULE:[2:$1/$2@$0](jhs/.*@HADOOP.COM)s/.*/mapred/
            DEFAULT
        </value>
        <description>
            Kerberos主体到Hadoop操作系统用户的具体映射规则
            "$0"表示域，"$1"表示服务主体名称中的第一部分,"$2"表示第二部分。
        </description>
    </property>
    <property>
        <name>hadoop.security.auth_to_local.mechanism</name>
        <value>MIT</value>
        <description>外部系统用户身份映射到Hadoop用户的机制</description>
    </property>
    <property>
        <name>hadoop.rpc.protection</name>
        <value>authentication</value>
        <description>
            Hadoop集群间RPC通讯设为仅认证模式
            此参数指定保护级别，有三种可能,分别为
            authentication(默认值，表示仅客户端/服务器相互认值),
            integrity(表示保证数据的完整性并进行身份验证),
            privacy(进行身份验证并保护数据完整性，并且还加密在客户端与服务器之间传输的数据)
        </description>
    </property>
    <property>
        <name>hadoop.kerberos.kinit.command</name>
        <value>/usr/bin/kinit</value>
        <description>用于Kerberos证书的定时更新</description>
    </property>
</configuration>
```

### 5. 配置hdfs-site.xml

```xml
<configuration>
    <property>
        <name>dfs.ha.fencing.ssh.private-key-files</name>
        <value>/home/hdfs/.ssh/id_rsa</value>
        <description>使用隔离机制时需要 ssh 秘钥登录</description>
    </property>

    <property>
        <name>dfs.block.access.token.enable</name>
        <value>true</value>
        <description>开启访问DataNode数据块需要Kerberos认证</description>
    </property>

    <property>
        <name>dfs.namenode.kerberos.principal</name>
        <value>hdfs/_HOST@HADOOP.COM</value>
        <description>NameNode服务的Kerberos主体</description>
    </property>
    <property>
        <name>dfs.namenode.keytab.file</name>
        <value>/etc/security/keytab/hdfs.keytab</value>
        <description>NameNode服务的keytab文件位置</description>
    </property>

    <property>
        <name>dfs.datanode.kerberos.principal</name>
        <value>hdfs/_HOST@HADOOP.COM</value>
        <description>DataNode服务的Kerberos主体</description>
    </property>
    <property>
        <name>dfs.datanode.keytab.file</name>
        <value>/etc/security/keytab/hdfs.keytab</value>
        <description>DataNode服务的keytab文件位置</description>
    </property>

    <property>
        <name>dfs.journalnode.kerberos.principal</name>
        <value>hdfs/_HOST@HADOOP.COM</value>
        <description>JournalNode服务的Kerberos主体</description>
    </property>
    <property>
        <name>dfs.journalnode.keytab.file</name>
        <value>/etc/security/keytab/hdfs.keytab</value>
        <description>JournalNode服务的keytab文件位置</description>
    </property>

    <property>
        <name>dfs.web.authentication.kerberos.principal</name>
        <value>HTTP/_HOST@HADOOP.COM</value>
        <description>HDFS Web UI服务的Kerberos主体</description>
    </property>
    <property>
        <name>dfs.web.authentication.kerberos.keytab</name>
        <value>/etc/security/keytab/hdfs.keytab</value>
        <description>HDFS Web UI服务的keytab文件位置</description>
    </property>

    <property>
        <name>dfs.namenode.kerberos.principal.pattern</name>
        <value>*</value>
        <description></description>
    </property>

    <property>
        <name>dfs.datanode.data.dir.perm</name>
        <value>700</value>
        <description>DFS 数据节点存储其块的本地文件系统上目录的权限</description>
    </property>

    <property>
        <name>dfs.http.policy</name>
        <value>HTTPS_ONLY</value>
        <description>
            配置HDFS支持HTTPS协议
            - HTTP_ONLY : Service is provided only on http
            - HTTPS_ONLY : Service is provided only on https
            - HTTP_AND_HTTPS : Service is provided both on http and https
        </description>
    </property>

    <property>
        <name>dfs.data.transfer.protection</name>
        <value>authentication</value>
        <description> 配置DataNode数据传输保护策略为仅授权模式 </description>
    </property>
</configuration>
```

### 6. 配置yarn-site.xml

```xml
<configuration>
    <property>
        <name>yarn.resourcemanager.principal</name>
        <value>yarn/_HOST@HADOOP.COM</value>
        <description>ResourceManager服务的Kerberos主体</description>
    </property>
    <property>
        <name>yarn.resourcemanager.keytab</name>
        <value>/etc/security/keytab/yarn.keytab</value>
        <description>ResourceManager服务的keytab文件位置</description>
    </property>

    <property>
        <name>yarn.nodemanager.principal</name>
        <value>yarn/_HOST@HADOOP.COM</value>
        <description>NodeManager服务的Kerberos主体</description>
    </property>
    <property>
        <name>yarn.nodemanager.keytab</name>
        <value>/etc/security/keytab/yarn.keytab</value>
        <description>NodeManager服务的keytab文件位置</description>
    </property>
    <property>
        <name>yarn.nodemanager.container-executor.class</name>
        <value>org.apache.hadoop.yarn.server.nodemanager.LinuxContainerExecutor</value>
    </property>
  	<property>
    	<name>yarn.nodemanager.linux-container-executor.group</name>
    	<value>hadoop</value>
  	</property>
    <property>
        <name>yarn.nodemanager.linux-container-executor.nonsecure-mode.local-user</name>
        <value>yarn</value>
    </property>
    <property>
        <name>yarn.nodemanager.linux-container-executor.nonsecure-mode.limit-users</name>
        <value>false</value>
    </property>
</configuration>
```

### 7. 配置mapred-site.xml 

```xml
<configuration>
    <property>
        <name>mapreduce.jobtracker.kerberos.principal</name>
        <value>mapred/_HOST@HADOOP.COM</value>
        <description>集群Kerberos realm配置</description>
    </property>
    <property>
        <name>mapreduce.jobtracker.keytab.file</name>
        <value>/etc/security/keytabs/mapred.keytab</value>
        <description>Jobtracker的kerberos文件的位置</description>
    </property>

    <property>
        <name>mapreduce.tasktracker.kerberos.principal</name>
        <value>mapred/_HOST@HADOOP.COM</value>
    </property>
    <property>
        <name>mapreduce.tasktracker.keytab.file</name>
        <value>/etc/security/keytabs/mapred.keytab</value>
        <description>Tasktracker的kerberos文件的位置</description>
    </property>
    
    <property>
        <name>mapreduce.jobhistory.principal</name>
        <value>mapred/_HOST@HADOOP.COM</value>
    </property>
    <property>
        <name>mapreduce.jobhistory.keytab</name>
        <value>/etc/security/keytabs/mapred.keytab</value>
        <description>JobHistory的kerberos文件的位置</description>
    </property>
</configuration>
```







附上hadoop通用默认端口，当然，如果自己在配置的时候做过更改，还是要按照自己配置的来；

| 端口  | 作用                                                         |
| ----- | ------------------------------------------------------------ |
| 9000  | fs.defaultFS，如：hdfs://172.25.40.171:9000                  |
| 9001  | dfs.namenode.rpc-address，DataNode会连接这个端口             |
| 50070 | dfs.namenode.http-address                                    |
| 50470 | dfs.namenode.https-address                                   |
| 50100 | dfs.namenode.backup.address                                  |
| 50105 | dfs.namenode.backup.http-address                             |
| 50090 | dfs.namenode.secondary.http-address，如：172.25.39.166:50090 |
| 50091 | dfs.namenode.secondary.https-address，如：172.25.39.166:50091 |
| 50020 | dfs.datanode.ipc.address                                     |
| 50075 | dfs.datanode.http.address                                    |
| 50475 | dfs.datanode.https.address                                   |
| 50010 | dfs.datanode.address，DataNode的数据传输端口                 |
| 8480  | dfs.journalnode.rpc-address                                  |
| 8481  | dfs.journalnode.https-address                                |
| 8032  | yarn.resourcemanager.address                                 |
| 8088  | yarn.resourcemanager.webapp.address，YARN的http端口          |
| 8090  | yarn.resourcemanager.webapp.https.address                    |
| 8030  | yarn.resourcemanager.scheduler.address                       |
| 8031  | yarn.resourcemanager.resource-tracker.address                |
| 8033  | yarn.resourcemanager.admin.address                           |
| 8042  | yarn.nodemanager.webapp.address                              |
| 8040  | yarn.nodemanager.localizer.address                           |
| 8188  | yarn.timeline-service.webapp.address                         |
| 10020 | mapreduce.jobhistory.address                                 |
| 19888 | mapreduce.jobhistory.webapp.address                          |
| 2888  | ZooKeeper，如果是Leader，用来监听Follower的连接              |
| 3888  | ZooKeeper，用于Leader选举                                    |
| 2181  | ZooKeeper，用来监听客户端的连接                              |
| 60010 | hbase.master.info.port，HMaster的http端口                    |
| 60000 | hbase.master.port，HMaster的RPC端口                          |
| 60030 | hbase.regionserver.info.port，HRegionServer的http端口        |
| 60020 | hbase.regionserver.port，HRegionServer的RPC端口              |
| 8080  | hbase.rest.port，HBase REST server的端口                     |
| 10000 | hive.server2.thrift.port                                     |
| 9083  | hive.metastore.uris                                          |

