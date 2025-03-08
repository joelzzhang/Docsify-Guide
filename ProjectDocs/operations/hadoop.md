# Hadoop HA 高可用搭建

## 1 环境准备



## 2 环境规划

| IP         | hostname | 角色                                                         | 组件                  |
| ---------- | -------- | ------------------------------------------------------------ | --------------------- |
| 10.10.10.3 | hadoop1  | NameNode、JournalNode、DataNode 、Zookeeper、ResourceManager、NodeManager、ZKFC | HDFS、YARN、Zookeeper |
| 10.10.10.4 | hadoop2  | JournalNode、DataNode  、Zookeeper、ResourceManager、NodeManager、HistoryServer、ZKFC | HDFS、YARN、Zookeeper |
| 10.10.10.5 | hadoop3  | NameNode、JournalNode、DataNode  、Zookeeper、NodeManager、ZKFC | HDFS、YARN、Zookeeper |

## 3 HDFS配置高可用集群

### 3.1 配置hadoop-env.sh

```shell
export JAVA_HOME=/opt/jdk1.8.0_381
```

### 3.2 配置core-site.xml

```xml
<configuration>
    <!-- 把多个 NameNode 的地址组装成一个集群 mycluster -->
    <property>
        <name>fs.defaultFS</name>
        <value>hdfs://mycluster</value>
    </property>
    <!-- 指定 hadoop 运行时产生文件的存储目录 -->
    <property>
        <name>hadoop.tmp.dir</name>
        <value>/data/hadoop</value>
    </property>
    <!-- 指定 zkfc 要连接的 zkServer 地址 -->
    <property>
        <name>ha.zookeeper.quorum</name>
        <value>hadoop1:2181,hadoop2:2181,hadoop3:2181</value>
    </property>
    <!-- NN 连接 JN 重试次数，默认是 10 次 -->
    <property>
        <name>ipc.client.connect.max.retries</name>
        <value>20</value>
    </property>
    <!-- 重试时间间隔，默认 1s -->
    <property>
        <name>ipc.client.connect.retry.interval</name>
        <value>5000</value>
    </property>
</configuration>
```

### 3.3 配置hdfs-site.xml

```xml
<configuration>
    <!-- NameNode 数据存储目录 -->
    <property>
        <name>dfs.namenode.name.dir</name>
        <value>file://${hadoop.tmp.dir}/name</value>
    </property>
    <!-- DataNode 数据存储目录 -->
    <property>
        <name>dfs.datanode.data.dir</name>
        <value>file://${hadoop.tmp.dir}/data</value>
    </property>
    <!-- JournalNode 数据存储目录 -->
    <property>
        <name>dfs.journalnode.edits.dir</name>
        <value>${hadoop.tmp.dir}/jn</value>
    </property>
    <property>
    <name>dfs.blocksize</name>
        <value>134217728</value>
    </property>
    <property>
        <name>dfs.datanode.max.transfer.threads</name>
        <value>40960</value>
    </property>
    <property>
        <name>dfs.replication</name>
        <value>3</value>
    </property>
    <property>
        <name>dfs.internal.nameservices</name>
        <value>mycluster</value>
    </property>
    <!-- 完全分布式集群名称 -->
    <property>
        <name>dfs.nameservices</name>
        <value>mycluster</value>
    </property>
    <!-- 集群中 NameNode 节点都有哪些 -->
    <property>
        <name>dfs.ha.namenodes.mycluster</name>
        <value>nn1,nn2</value>
    </property>
    <!-- NameNode 的 RPC 通信地址 -->
    <property>
        <name>dfs.namenode.rpc-address.mycluster.nn1</name>
        <value>hadoop1:8020</value>
    </property>
    <property>
        <name>dfs.namenode.rpc-address.mycluster.nn2</name>
        <value>hadoop3:8020</value>
    </property>
    <!-- NameNode 的 http 通信地址 -->
    <property>
        <name>dfs.namenode.http-address.mycluster.nn1</name>
        <value>hadoop1:9870</value>
    </property>
    <property>
        <name>dfs.namenode.http-address.mycluster.nn2</name>
        <value>hadoop3:9870</value>
    </property>
    <!-- 指定 NameNode 元数据在 JournalNode 上的存放位置 -->
    <property>
        <name>dfs.namenode.shared.edits.dir</name>
        <value>qjournal://hadoop1:8485;hadoop2:8485;hadoop3:8485/mycluster</value>
    </property>
    <!-- 访问代理类：client 用于确定哪个 NameNode 为 Active -->
    <property>
        <name>dfs.client.failover.proxy.provider.mycluster</name>
        <value>org.apache.hadoop.hdfs.server.namenode.ha.ConfiguredFailoverProxyProvider</value>
    </property>
    <!-- 配置隔离机制，即同一时刻只能有一台服务器对外响应 -->
    <property>
        <name>dfs.ha.fencing.methods</name>
        <value>sshfence</value>
    </property>
    <!-- 使用隔离机制时需要 ssh 秘钥登录-->
    <property>
        <name>dfs.ha.fencing.ssh.private-key-files</name>
        <value>/root/.ssh/id_rsa</value>
    </property>
    <!-- 启用 nn 故障自动转移 -->
    <property>
        <name>dfs.ha.automatic-failover.enabled</name>
        <value>true</value>
    </property>
</configuration>
```

## 4 YARN配置高可用集群

### 4.1 配置yarn-site.xml

```xml
<configuration>
    <property>
        <name>yarn.nodemanager.aux-services</name>
        <value>mapreduce_shuffle</value>
    </property>
    <!-- 启用 resourcemanager ha -->
    <property>
        <name>yarn.resourcemanager.ha.enabled</name>
        <value>true</value>
    </property>
    <!-- 声明两台 resourcemanager 的地址 -->
    <property>
        <name>yarn.resourcemanager.cluster-id</name>
        <value>cluster-yarn1</value>
    </property>
    <!--指定 resourcemanager 的逻辑列表-->
    <property>
        <name>yarn.resourcemanager.ha.rm-ids</name>
        <value>rm1,rm2</value>
    </property>
    <!-- ========== rm1 的配置 ========== -->
    <!-- 指定 rm1 的主机名 -->
    <property>
        <name>yarn.resourcemanager.hostname.rm1</name>
        <value>hadoop1</value>
    </property>
    <!-- 指定 rm1 的 web 端地址 -->
    <property>
        <name>yarn.resourcemanager.webapp.address.rm1</name>
        <value>hadoop1:8088</value>
    </property>
    <!-- 指定 rm1 的内部通信地址 -->
    <property>
        <name>yarn.resourcemanager.address.rm1</name>
        <value>hadoop1:8032</value>
    </property>
    <!-- 指定 AM(Application Master) 向 rm1 申请资源的地址 -->
    <property>
        <name>yarn.resourcemanager.scheduler.address.rm1</name>
        <value>hadoop1:8030</value>
    </property>
    <!-- 指定供 NM 连接的地址 -->
    <property>
        <name>yarn.resourcemanager.resource-tracker.address.rm1</name>
        <value>hadoop1:8031</value>
    </property>
    <!-- ========== rm2 的配置 ========== -->
    <property>
        <name>yarn.resourcemanager.hostname.rm2</name>
        <value>hadoop2</value>
    </property>
    <property>
        <name>yarn.resourcemanager.webapp.address.rm2</name>
        <value>hadoop2:8088</value>
    </property>
    <property>
        <name>yarn.resourcemanager.address.rm2</name>
        <value>hadoop2:8032</value>
    </property>
    <property>
        <name>yarn.resourcemanager.scheduler.address.rm2</name>
        <value>hadoop2:8030</value>
    </property>
    <property>
        <name>yarn.resourcemanager.resource-tracker.address.rm2</name>
        <value>hadoop2:8031</value>
    </property>
    <!-- 指定 zookeeper 集群的地址 -->
    <property>
        <name>yarn.resourcemanager.zk-address</name>
        <value>hadoop1:2181,hadoop2:2181,hadoop3:2181</value>
    </property>
    <!-- 启用自动恢复 -->
    <property>
        <name>yarn.resourcemanager.recovery.enabled</name>
        <value>true</value>
    </property>
    <!-- 指定 resourcemanager 的状态信息存储在 zookeeper 集群 -->
    <property>
        <name>yarn.resourcemanager.store.class</name>
        <value>org.apache.hadoop.yarn.server.resourcemanager.recovery.ZKRMStateStore</value>
    </property>
    <!-- 环境变量的继承 -->
    <property>
        <name>yarn.nodemanager.env-whitelist</name>
        <value>
            JAVA_HOME,HADOOP_COMMON_HOME,HADOOP_HDFS_HOME,HADOOP_CONF_DIR,CLASSPATH_PREPEND_DISTCACHE,HADOOP_YARN_HOME,HADOOP_MAPRED_HOME</value>
    </property>
</configuration>
```

## 5 分发Hadoop包

```shell
[root@hadoop1@10.10.10.3 module]# scp -r hadoop-3.3.6 root@hadoop2:/opt/module/
[root@hadoop1@10.10.10.3 module]# scp -r hadoop-3.3.6 root@hadoop3:/opt/module/
```

