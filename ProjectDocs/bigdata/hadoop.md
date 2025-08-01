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
    <!-- namenode的hdfs协议文件系统的通信地址，客户端连接HDFS时，为Hadoop客户端配置默认的高可用路径前缀 -->
    <property>
        <name>fs.defaultFS</name>
        <value>hdfs://hadoopcluster</value>
    </property>

    <!-- 
		指定 hadoop 运行时产生文件的存储目录
		Hadoop数据存放的路径，namenode,datanode数据存放路径都依赖本路径。
		不要使用"file:///"开头，使用绝对路径即可。
		namenode默认存储路径:
			file://${hadoop.tmp.dir}/dfs/name			
		datanode默认存储路径
			file://${hadoop.tmp.dir}/dfs/data
	-->
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

### 3. 配置hdfs-site.xml

```xml
<configuration>
    <!-- NameNode 数据存储目录 -->
    <property>
        <name>dfs.namenode.name.dir</name>
        <value>file://${hadoop.tmp.dir}/name</value>
    </property>
    <!-- DataNode 数据存储目录，多个目录则用,分割 -->
    <property>
        <name>dfs.datanode.data.dir</name>
        <value>/data01/hdfs</value>
    </property>
    <!-- JournalNode 数据存储目录 -->
    <property>
        <name>dfs.journalnode.edits.dir</name>
        <value>${hadoop.tmp.dir}/journalnode</value>
    </property>
    
    <!-- blocksize 数据块大小128M -->
    <property>
    	<name>dfs.blocksize</name>
        <value>134217728</value>
    </property>
    <!-- datanode进行传输数据的最大线程数 -->
    <property>
        <name>dfs.datanode.max.transfer.threads</name>
        <value>4096</value>
    </property>
    <!-- 数据副本数量 -->
    <property>
        <name>dfs.replication</name>
        <value>2</value>
    </property>
    
    <!-- 集群内部通信名称 -->
    <property>
        <name>dfs.internal.nameservices</name>
        <value>hadoopcluster</value>
    </property>
    <!-- 完全分布式集群名称 -->
    <property>
        <name>dfs.nameservices</name>
        <value>hadoopcluster</value>
    </property>
    <!-- 集群中 NameNode 节点都有哪些 -->
    <property>
        <name>dfs.ha.namenodes.hadoopcluster</name>
        <value>nn1,nn2</value>
    </property>
    
    <!-- NameNode 的 RPC 通信地址 -->
    <property>
        <name>dfs.namenode.rpc-address.hadoopcluster.nn1</name>
        <value>hadoop1:53310</value>
    </property>
    <property>
        <name>dfs.namenode.rpc-address.hadoopcluster.nn2</name>
        <value>hadoop3:53310</value>
    </property>
    
    <!-- 	
		语法格式: "dfs.namenode.rpc-address.[nameservice ID].[namenode ID]"
		NameNode 的 http 通信地址 
	-->
    <property>
        <name>dfs.namenode.http-address.hadoopcluster.nn1</name>
        <value>hadoop1:50070</value>
    </property>
    <property>
        <name>dfs.namenode.http-address.hadoopcluster.nn2</name>
        <value>hadoop3:50070</value>
    </property>
    
    <!-- 指定 NameNode 元数据在 JournalNode 上的存放位置 -->
    <property>
        <name>dfs.namenode.shared.edits.dir</name>
        <value>qjournal://hadoop1:8485;hadoop2:8485;hadoop3:8485/hadoopcluster</value>
    </property>
    <property>
    	<name>dfs.journalnode.rpc-address</name>
    	<value>0.0.0.0:8485</value>
  	</property>
 	<property>
    	<name>dfs.journalnode.http-address</name>
    	<value>0.0.0.0:8480</value>
  	</property>
    
    <!-- 访问代理类：client 用于确定哪个 NameNode 为 Active -->
    <property>
        <name>dfs.client.failover.proxy.provider.hadoopcluster</name>
        <value>org.apache.hadoop.hdfs.server.namenode.ha.ConfiguredFailoverProxyProvider</value>
    </property>
    <!-- 配置隔离机制，即同一时刻只能有一台服务器对外响应 -->
    <property>
        <name>dfs.ha.fencing.methods</name>
        <value>sshfence(hdfs:22)
           shell(/bin/true)</value>
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
    <property>
     	<name>dfs.permissions.enabled</name>
     	<value>false</value>
  	</property>
</configuration>
```
### 4. 配置yarn-site.xml

```xml
<configuration>
    <property>
        <name>yarn.nodemanager.aux-services</name>
        <value>mapreduce_shuffle</value>
    </property>
    <property>
      	<name>yarn.nodemanager.aux-services.mapreduce_shuffle.class</name>
      	<value>org.apache.hadoop.mapred.ShuffleHandler</value>
    </property>
    
    <!-- 启用 resourcemanager ha -->
    <property>
        <name>yarn.resourcemanager.ha.enabled</name>
        <value>true</value>
    </property>
    <!-- 声明两台 resourcemanager 的地址 -->
    <property>
        <name>yarn.resourcemanager.cluster-id</name>
        <value>rm</value>
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
    <!-- 开启日志聚集功能 -->
    <property>
        <name>yarn.log-aggregation-enable</name>
        <value>true</value>
    </property>
    <!-- 设置日志聚集服务器地址 -->
    <property>
        <name>yarn.log.server.url</name>
        <value>http://bigdata03:19888/jobhistory/logs</value>
    </property>
    <!-- 设置日志保留时间为 7 天 -->
    <property>
        <name>yarn.log-aggregation.retain-seconds</name>
        <value>604800</value>
    </property>
    <!-- 环境变量的继承 -->
    <property>
        <name>yarn.nodemanager.env-whitelist</name>
        <value>
            JAVA_HOME,HADOOP_COMMON_HOME,HADOOP_HDFS_HOME,HADOOP_CONF_DIR,CLASSPATH_PREPEND_DISTCACHE,HADOOP_YARN_HOME,HADOOP_HOME,PATH,LANG,TZ,HADOOP_MAPRED_HOME
        </value>
    </property>
</configuration>
```

### 5. 配置mapred-site.xml 

```xml
<configuration>
	<property>
		<!-- 声明MapReduce框架在YARN上运行 -->
		<name>mapreduce.framework.name</name>
		<value>yarn</value>
	</property>
	<!-- 设置环境变量，多个值用逗号分隔，也可以在mapreduce程序中通过-Dyarn.app.mapreduce.am.env.HADOOP_MAPRED_HOME=XXX来设置 -->
    <property>
      <name>yarn.app.mapreduce.am.env</name>
      <value>HADOOP_MAPRED_HOME=${HADOOP_HOME}</value>
    </property>
    <property>
      <name>mapreduce.map.env</name>
      <value>HADOOP_MAPRED_HOME=${HADOOP_HOME}</value>
    </property>
    <property>
      <name>mapreduce.reduce.env</name>
      <value>HADOOP_MAPRED_HOME=${HADOOP_HOME}</value>
    </property>  
    <!-- 历史服务器端地址 -->
    <property>
        <name>mapreduce.jobhistory.address</name>
        <value>bigdata03:10020</value>
    </property>
    <!-- 历史服务器 web 端地址 -->
    <property>
        <name>mapreduce.jobhistory.webapp.address</name>
        <value>bigdata03:19888</value>
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

1. 创建日志目录

   ```bash
   mkdir -p /var/log/hadoop/hadoop-hdfs /var/log/hadoop/hadoop-yarn /var/log/hadoop/hadoop-mapred
   ```

2. 为日志目录赋权

   ```bash
   chown -R yarn:hadoop /var/log/hadoop/hadoop-yarn 
   chown -R mapred:hadoop /var/log/hadoop/hadoop-mapred
   chown -R hdfs:hadoop /var/log/hadoop/hadoop-hdfs
   chmod -R 755 /var/log/hadoop/*
   ```

3. 数据目录权限调整

   ```bash
   # master节点
   chown -R hdfs:hadoop /data/hadoop
   chmod -R 755 /data/hadoop
   chmod 644 /usr/local/zookeeper/conf/keytab/zkcli.keytab
   # slave节点
   chown -R hdfs:hadoop /data01/hdfs
   chmod -R 755 /data01/hdfs
   ```

### 3. 配置core-site.xml

```xml
<!--启用Kerberos安全认证-->
<property>
  <name>hadoop.security.authentication</name>
  <value>kerberos</value>
  <description>Possible values are simple (no authentication), and kerberos</description>
</property>
<!--启用Hadoop集群授权管理-->
<property>
  <name>hadoop.security.authorization</name>
  <value>true</value>
  <description>Is service-level authorization enabled?</description>
</property>
<!--Kerberos主体到Hadoop用户的具体映射规则-->
<property>
  <name>hadoop.security.auth_to_local</name>
  <value></value>
  <description>Maps kerberos principals to local user names</description>
</property>
<!--外部系统用户身份映射到Hadoop用户的机制-->
<property>
  <name>hadoop.security.auth_to_local.mechanism</name>
  <value>hadoop</value>
  <description>The mechanism by which auth_to_local rules are evaluated.
    If set to 'hadoop' it will not allow resulting local user names to have
    either '@' or '/'. If set to 'MIT' it will follow MIT evaluation rules
    and the restrictions of 'hadoop' do not apply.</description>
</property>
```

### 4. 配置hdfs-site.xml

```xml
<!-- 使用隔离机制时需要 ssh 秘钥登录-->
<property>
  <name>dfs.ha.fencing.ssh.private-key-files</name>
  <value>/home/hdfs/.ssh/id_rsa</value>
</property>
<!--开启访问DataNode数据库需要Kerberos认证-->
<property>
  <name>dfs.block.access.token.enable</name>
  <value>true</value>
</property>
<!--NameNode服务的Kerberos主体-->
<property>
  <name>dfs.namenode.kerberos.principal</name>
  <value>hdfs/_HOST@HADOOP.COM</value>
</property>
<!--NameNode服务的keytab文件位置-->
<property>
  <name>dfs.namenode.keytab.file</name>
  <value>/etc/security/keytab/hdfs.keytab</value>
</property>
<!--DataNode服务的Kerberos主体-->
<property>
  <name>dfs.datanode.kerberos.principal</name>
  <value>hdfs/_HOST@HADOOP.COM</value>
</property>
<!--DataNode服务的keytab文件位置-->
<property>
  <name>dfs.datanode.keytab.file</name>
  <value>/etc/security/keytab/hdfs.keytab</value>
</property>
<!--JournalNode服务的Kerberos主体-->
<property>
  <name>dfs.journalnode.kerberos.principal</name>
  <value>hdfs/_HOST@HADOOP.COM</value>
</property>
<!--JournalNode服务的keytab文件位置-->
<property>
  <name>dfs.journalnode.keytab.file</name>
  <value>/etc/security/keytab/hdfs.keytab</value>
</property>

<!--JournalNode Web UI服务的Kerberos主体-->
<property>
  <name>dfs.journalnode.kerberos.internal.spnego.principal</name>
  <value>HTTP/_HOST@HADOOP.COM</value>
</property>
<!--NameNode Web UI服务的Kerberos主体-->
<property>
  <name>dfs.namenode.kerberos.internal.spnego.principal</name>
  <value>HTTP/_HOST@HADOOP.COM</value>
</property>
<!--HDFS Web UI服务的Kerberos主体-->
<property>
  <name>dfs.web.authentication.kerberos.principal</name>
  <value>HTTP/_HOST@HADOOP.COM</value>
</property>
<!--HDFS Web UI服务的keytab文件位置-->
<property>
  <name>dfs.web.authentication.kerberos.keytab</name>
  <value>/etc/security/keytab/hdfs.keytab</value>
</property>

<property>
  <name>dfs.namenode.kerberos.principal.pattern</name>
  <value>*</value>
</property>
<property>
  <name>dfs.datanode.address</name>
  <value>0.0.0.0:1004</value>
</property>
<property>
  <name>dfs.datanode.http.address</name>
  <value>0.0.0.0:1006</value>
</property>
<property>
  <name>dfs.datanode.data.dir.perm</name>
  <value>700</value>
</property>

<!--配置HDFS支持HTTPS协议-->
<property>
  <name>dfs.http.policy</name>
  <value>HTTPS_ONLY</value>
  <description>Decide if HTTPS(SSL) is supported on HDFS
    This configures the HTTP endpoint for HDFS daemons:
    The following values are supported:
    - HTTP_ONLY : Service is provided only on http
    - HTTPS_ONLY : Service is provided only on https
    - HTTP_AND_HTTPS : Service is provided both on http and https
  </description>
</property>

<!--配置DataNode数据传输保护策略为仅授权模式-->
<property>
  <name>dfs.data.transfer.protection</name>
  <value>authentication</value>
  <description>
    A comma-separated list of SASL protection values used for secured
    connections to the DataNode when reading or writing block data. Possible
    values are authentication, integrity and privacy. authentication means
    authentication only and no integrity or privacy; integrity implies
    authentication and integrity are enabled; and privacy implies all of
    authentication, integrity and privacy are enabled. If
    dfs.encrypt.data.transfer is set to true, then it supersedes the setting for
    dfs.data.transfer.protection and enforces that all connections must use a
    specialized encrypted SASL handshake. This property is ignored for
    connections to a DataNode listening on a privileged port. In this case, it
    is assumed that the use of a privileged port establishes sufficient trust.
  </description>
</property>
```

### 5. 配置yarn-site.xml

```xml
 <!--ResourceManager服务的Kerberos主体-->
<property>
  <name>yarn.resourcemanager.principal</name>
  <value>yarn/_HOST@HADOOP.COM</value>
</property>
<!--ResourceManager服务的keytab文件位置-->
<property>
  <name>yarn.resourcemanager.keytab</name>
  <value>/etc/security/keytab/yarn.keytab</value>
</property>
<!--NodeManager服务的Kerberos主体-->
<property>
  <name>yarn.nodemanager.principal</name>
  <value>yarn/_HOST@HADOOP.COM</value>
</property>
<!--NodeManager服务的keytab文件位置-->
<property>
  <name>yarn.nodemanager.keytab</name>
  <value>/etc/security/keytab/yarn.keytab</value>
</property>
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

