

## 一. 集群部署

### 1. 安装包获取

- 在线获取

  ```bash
  wget https://www.apache.org/dyn/closer.lua/zookeeper/zookeeper-3.8.4/apache-zookeeper-3.8.4-bin.tar.gz
  ```

- 离线获取访问[zookeeper官方网站](https://zookeeper.apache.org/releases.html)下载

> [!TIP|lable:zookeeper官方文档]
>
> https://cwiki.apache.org/confluence/display/ZOOKEEPER/Index

### 2. 分布式部署

1. 解压安装

   ```bash
   tar -zxvf zookeeper-3.8.4.tar.gz -C /usr/local/
   mv zookeeper-3.8.4 zookeeper
   ```

2. 创建数据和事务日志目录

   - 创建数据目录

     ```bash
     mkdir -p /data/zookeeper/data
     ```

   - 创建事务日志目录

     ```bash
     mkdir -p /var/log/zookeeper
     ```

3. 配置zoo.cfg文件

   - 复制conf目录下的zoo_sample.cfg

     ```bash
     cp  /usr/local/zookeeper/conf/zoo_sample.cfg /usr/local/zookeeper/conf/zoo.cfg
     ```

   - 修改dataDir

     ```bash
     dataDir=/data/zookeeper/data
     ```

   - 新增如下配置

     ```bash
     dataLogDir=/var/log/zookeeper
     # 集群配置
     server.1=bigdata01:2888:3888
     server.2=bigdata02:2888:3888
     server.3=bigdata03:2888:3888
     ```

     > [!NOTE|style:flat|label:集群配置参数解读]
     >
     > Server.X=HOST:PORT1:PORT2
     >
     >  X是一个数字，表示这个是第几号服务器；
     >
     >  HOST是这个服务器的 host或IP地址； 
     >
     > PORT1 是这个服务器与集群中的 Leader 服务器交换信息的端口； 
     >
     > PORT2是万一集群中的 Leader 服务器挂了，需要一个端口来重新进行选举，选出一个新的 Leader，而这个端口就是用来执行选举时服务器相互通信的端口。 
     >
     > 集群模式下配置一个文件myid，这个文件在dataDir 目录下，这个文件里面有一个数据 就是 X的值，Zookeeper 启动时读取此文件，拿到里面的数据与 zoo.cfg 里面的配置信息比较从而判断到底是哪个 server。

4. 集群部署

   - 创建myid并写入值

     ```bash
     # bigdata01
     echo 1 >> /data/zookeeper/data/myid
     # bigdata02
     echo 2 >> /data/zookeeper/data/myid
     # bigdata03
     echo 3 >> /data/zookeeper/data/myid
     ```

   - 分发安装包

     ```bash
     scp -r /usr/local/zookeeper root@bigdata02:/usr/local/
     scp -r /usr/local/zookeeper root@bigdata03:/usr/local/
     ```

     并分别bigdata02、bigdata03节点创建myid并写入对应的值

   - 分别启动 zookeeper

     ```bash
     cd /usr/local/zookeeper
     bin/zkServer.sh start
     ```

   - 查看状态

     ```bash
     bin/zkServer.sh status
     ZooKeeper JMX enabled by default
     Using config: /usr/local/zookeeper/bin/../conf/zoo.cfg
     Client port found: 2181. Client address: localhost. Client SSL: false.
     Mode: leader
     ```

## 二. 客户端操作命令

- 启动客户端

  ```bash
  bin/zkCli.sh -server 127.0.0.1:2181
  ```

- 显示所有操作命令

  ```bash
  [zk: localhost:2181(CONNECTED) 0] help
  ZooKeeper -server host:port -client-configuration properties-file cmd args
  	addWatch [-m mode] path # optional mode is one of [PERSISTENT, PERSISTENT_RECURSIVE] - default is PERSISTENT_RECURSIVE
  	addauth scheme auth
  	close 
  	config [-c] [-w] [-s]
  	connect host:port
  	create [-s] [-e] [-c] [-t ttl] path [data] [acl]
  	delete [-v version] path
  	deleteall path [-b batch size]
  	delquota [-n|-b|-N|-B] path
  	get [-s] [-w] path
  	getAcl [-s] path
  	getAllChildrenNumber path
  	getEphemerals path
  	history 
  	listquota path
  	ls [-s] [-w] [-R] path
  	printwatches on|off
  	quit 
  	reconfig [-s] [-v version] [[-file path] | [-members serverID=host:port1:port2;port3[,...]*]] | [-add serverId=host:port1:port2;port3[,...]]* [-remove serverId[,...]*]
  	redo cmdno
  	removewatches path [-c|-d|-a] [-l]
  	set [-s] [-v version] path data
  	setAcl [-s] [-v version] [-R] path acl
  	setquota -n|-b|-N|-B val path
  	stat [-w] path
  	sync path
  	version 
  	whoami 
  ```

- 查看当前节点数据

  ```bash
  [zk: localhost:2181(CONNECTED) 1] ls /
  [app1, zookeeper]
  #查看当前节点数据并返回stat信息
  [zk: localhost:2181(CONNECTED) 9] ls -s /
  [app1, zookeeper]
  cZxid = 0x0
  ctime = Thu Jan 01 08:00:00 CST 1970
  mZxid = 0x0
  mtime = Thu Jan 01 08:00:00 CST 1970
  pZxid = 0x200000004
  cversion = 0
  dataVersion = 0
  aclVersion = 0
  ephemeralOwner = 0x0
  dataLength = 0
  numChildren = 2
  ```

- 创建普通节点

  ```bash
  create /app1 "hello app1"
  create /app1/server101 "192.168.1.101"
  ```

- 查看节点的值

  ```bash
  [zk: localhost:2181(CONNECTED) 17] get /app1
  hello app1
  # 查看指定节点数据并返回stat信息
  [zk: localhost:2181(CONNECTED) 18] get -s /app1
  hello app1
  cZxid = 0x200000004
  ctime = Tue Jul 08 23:42:55 CST 2025
  mZxid = 0x200000004
  mtime = Tue Jul 08 23:42:55 CST 2025
  pZxid = 0x300000004
  cversion = 1
  dataVersion = 0
  aclVersion = 0
  ephemeralOwner = 0x0
  dataLength = 10
  numChildren = 1
  ```

- 创建临时节点

  ```bash
  create -e /app-emphemeral 8888
  # 在当前客户端是能查看到的
  [zk: localhost:2181(CONNECTED) 22] ls /
  [app-emphemeral, app1, zookeeper]
  # 退出当前客户端然后再重启客户端
  quit
  bin/zkCli.sh -server 127.0.0.1:2181
  # 再次查看根目录下临时节点已经删除
  [zk: 127.0.0.1:2181(CONNECTED) 0] ls /
  [app1, zookeeper]
  ```

- 创建带序号的节点

  ```bash
  # 先创建一个普通的根节点 app2
  [zk: localhost:2181(CONNECTED) 11] create /app2 "app2"
  # 创建带序号的节点
  [zk: localhost:2181(CONNECTED) 13] create -s /app2/aa 888
  Created /app2/aa0000000000
  [zk: localhost:2181(CONNECTED) 14] create -s /app2/bb 888
  Created /app2/bb0000000001
  [zk: localhost:2181(CONNECTED) 15] create -s /app2/cc 888
  Created /app2/cc0000000002
  # 如果原节点下有 1 个节点，则再排序时从 1 开始，以此类推。
  [zk: localhost:2181(CONNECTED) 16] create -s /app1/aa 888
  Created /app1/aa0000000001
  ```

- 修改节点数据值

  ```bash
  [zk: localhost:2181(CONNECTED) 9] get /app1
  hello app1
  [zk: localhost:2181(CONNECTED) 10] set /app1 999
  [zk: localhost:2181(CONNECTED) 11] get /app1
  999
  ```

- 节点的值变化监听

  ```bash
  # 在bigdata01主机上注册监听/app1 节点数据变化
  [zk: localhost:2181(CONNECTED) 26] get -s -w /app1
  # 在bigdata02主机上修改/app1 节点的数据
  [zk: localhost:2181(CONNECTED) 5] set /app1 777
  # 观察bigdata01主机收到数据变化的监听
  WATCHER::
  WatchedEvent state:SyncConnected type:NodeDataChanged path:/app1
  ```

- 节点的子节点变化监听

  ```bash
  # 在bigdata01主机上注册监听/app1 节点的子节点变化
  [zk: localhost:2181(CONNECTED) 1] ls -w /app1
  [aa0000000001, server101]
  # 在bigdata02主机/app1 节点上创建子节点
  [zk: localhost:2181(CONNECTED) 6] create /app1/bb 666
  Created /app1/bb
  # 观察bigdata01主机收到子节点变化的监听
  WATCHER::
  WatchedEvent state:SyncConnected type:NodeChildrenChanged path:/app1
  ```

- 删除节点

  ```bash
  delete /app1/bb
  ```

- 递归删除节点

  ```bash
  [zk: localhost:2181(CONNECTED) 0] ls -s /app2
  [aa0000000000, bb0000000001, cc0000000002, dd]
  cZxid = 0x800000002
  ctime = Thu Jul 10 18:42:38 CST 2025
  mZxid = 0x800000002
  mtime = Thu Jul 10 18:42:38 CST 2025
  pZxid = 0x800000006
  cversion = 4
  dataVersion = 0
  aclVersion = 0
  ephemeralOwner = 0x0
  dataLength = 4
  numChildren = 4
  [zk: localhost:2181(CONNECTED) 1] 
  [zk: localhost:2181(CONNECTED) 1] 
  [zk: localhost:2181(CONNECTED) 1] delete
  delete      deleteall   
  [zk: localhost:2181(CONNECTED) 1] deleteall /app2
  [zk: localhost:2181(CONNECTED) 2] ls -s /app2
  Node does not exist: /app2
  ```

- 查看节点状态

  ```bash
  [zk: localhost:2181(CONNECTED) 22] stat /app1
  cZxid = 0x200000004
  ctime = Tue Jul 08 23:42:55 CST 2025
  mZxid = 0x800000009
  mtime = Thu Jul 10 18:49:03 CST 2025
  pZxid = 0x80000000b
  cversion = 3
  dataVersion = 2
  aclVersion = 0
  ephemeralOwner = 0x0
  dataLength = 3
  numChildren = 1
  ```

## 三. API应用

## 四. Zookeeper内部原理

### 1. 选举机制

### 2. 节点类型

### 3. stat结构体

### 4. 写数据流程

## 五. Zookeeper SASL

### 1. Client-Server相互身份验证

#### 1.1 keytab文件准备

- 创建keytab文件

  ```shell
  # 在kdc master执行以下命令
  kadmin.local -q "addprinc -pw 2wsx@WSX zkcli"
  kadmin.local -q "xst -norandkey -k /var/kerberos/krb5kdc/keytab/zkcli.keytab zkcli"
  ```

- 分发keytab文件

  ```shell
  # 开始分发
  scp /var/kerberos/krb5kdc/keytab/zkcli.keytab bigdata01:/usr/local/zookeeper/conf/keytab
  scp /var/kerberos/krb5kdc/keytab/zkcli.keytab bigdata02:/usr/local/zookeeper/conf/keytab
  scp /var/kerberos/krb5kdc/keytab/zkcli.keytab bigdata03:/usr/local/zookeeper/conf/keytab
  ```

#### 1.2 配置文件zoo.cfg

```properties
# 在conf/zoo.cfg配置文件中添加如下内容：
sessionRequireClientSASLAuth=true
authProvider.1=org.apache.zookeeper.server.auth.SASLAuthenticationProvider
jaasLoginRenew=3600000
#将principal对应的主机名去掉，防止hbase等服务访问zookeeper时报错，如GSS initiate failed时就有可能是该项没配置
kerberos.removeHostFromPrincipal=true
kerberos.removeRealmFromPrincipal=true
```

#### 1.3 配置文件java.env

```properties

# REQUIRED SASL RELATED CONFIGS:
# ==== java.security.auth.login.config:
# Defining your client side JAAS config file path:
CLIENT_JVMFLAGS="${CLIENT_JVMFLAGS} -Djava.security.auth.login.config=/usr/local/zookeeper/conf/jaas/jaas.conf -Djava.security.krb5.conf=/etc/krb5.conf"
 
# OPTIONAL SASL RELATED CONFIGS:
 
# ==== zookeeper.sasl.client:
# You can disable SASL authentication on the client side (it is true by default):
# CLIENT_JVMFLAGS="${CLIENT_JVMFLAGS} -Dzookeeper.sasl.client=false"
 
 
# ==== zookeeper.server.principal:
# Setting the server principal of the ZooKeeper service. If this configuration is provided, then
# the ZooKeeper client will NOT USE any of the following parameters to determine the server principal:
# zookeeper.sasl.client.username, zookeeper.sasl.client.canonicalize.hostname, zookeeper.server.realm
# Note: this config parameter is working only for ZooKeeper 3.5.7+, 3.6.0+
# CLIENT_JVMFLAGS="${CLIENT_JVMFLAGS} -Dzookeeper.server.principal=zookeeper@EXAMPLE.COM"
 
 
# ==== zookeeper.sasl.client.username:
# Setting the 'user' part of the server principal of the ZooKeeper service, assuming the
# zookeeper.server.principal parameter is not provided. When you have zookeeper/myhost@EXAMPLE.COM
# defined in your server side SASL config, then use:
# CLIENT_JVMFLAGS="${CLIENT_JVMFLAGS} -Dzookeeper.sasl.client.username=zookeeper"
 
 
# ==== zookeeper.sasl.client.canonicalize.hostname:
# Assuming the zookeeper.server.principal parameter is not provided, the ZooKeeper client will try to
# determine the 'instance' (host) part of the ZooKeeper server principal. First it takes the hostname provided
# as the ZooKeeper server connection string. Then it tries to 'canonicalize' the address by getting
# the fully qualified domain name belonging to the address. You can disable this 'canonicalization'
# using the following config:
# CLIENT_JVMFLAGS="${CLIENT_JVMFLAGS} -Dzookeeper.sasl.client.canonicalize.hostname=false"
 
 
# ==== zookeeper.server.realm:
# Setting the 'realm' part of the server principal of the ZooKeeper service, assuming the
# zookeeper.server.principal parameter is not provided. By default, in this case the ZooKeeper Client
# will use its own realm. You can override this, e.g. when you have zookeeper/myhost@EXAMPLE.COM
# defined in your server side SASL config, then use:
# CLIENT_JVMFLAGS="${CLIENT_JVMFLAGS} -Dzookeeper.server.realm=EXAMPLE.COM"
 
 
# ==== zookeeper.sasl.clientconfig:
# you can have multiple contexts defined in a JAAS.conf file. ZooKeeper client is using the section
# named as 'Client' by default. You can override it if you wish, by using:
# CLIENT_JVMFLAGS="${CLIENT_JVMFLAGS} -Dzookeeper.sasl.clientconfig=Client"
```

#### 1.4 配置文件jaas.conf

```shell
Server {
       com.sun.security.auth.module.Krb5LoginModule required
       useKeyTab=true
       keyTab="/usr/local/zookeeper/conf/keytab/zookeeper.keytab"
       storeKey=true
       useTicketCache=false
       debug=true
       principal="zookeeper/${hostname}@HADOOP.COM";
};

Client {
       com.sun.security.auth.module.Krb5LoginModule required
       useKeyTab=true
       keyTab="/usr/local/zookeeper/conf/keytab/zkcli.keytab"
       storeKey=true
       useTicketCache=false
       debug=true
       principal="zkcli@HADOOP.COM";
};
```

### 2. Server-Server相互身份验证

#### 2.1 keytab文件准备

- 创建keytab文件

  ```shell
  # 在kdc master执行以下命令
  kadmin.local -q "addprinc -pw 2wsx@WSX zookeeper/bigdata01"
  kadmin.local -q "addprinc -pw 2wsx@WSX zookeeper/bigdata02"
  kadmin.local -q "addprinc -pw 2wsx@WSX zookeeper/bigdata03"
  kadmin.local -q "xst -norandkey -k /var/kerberos/krb5kdc/keytab/zookeeper.keytab zookeeper/bigdata01"
  kadmin.local -q "xst -norandkey -k /var/kerberos/krb5kdc/keytab/zookeeper.keytab zookeeper/bigdata02"
  kadmin.local -q "xst -norandkey -k /var/kerberos/krb5kdc/keytab/zookeeper.keytab zookeeper/bigdata03"
  ```

- 分发keytab文件

  ```shell
  # 在kdc master执行以下命令
  ssh bigdata01 "mkdir -p /usr/local/zookeeper/conf/keytab"
  ssh bigdata02 "mkdir -p /usr/local/zookeeper/conf/keytab"
  ssh bigdata03 "mkdir -p /usr/local/zookeeper/conf/keytab"
  # 开始分发
  scp /var/kerberos/krb5kdc/keytab/zookeeper.keytab bigdata01:/usr/local/zookeeper/conf/keytab
  scp /var/kerberos/krb5kdc/keytab/zookeeper.keytab bigdata02:/usr/local/zookeeper/conf/keytab
  scp /var/kerberos/krb5kdc/keytab/zookeeper.keytab bigdata03:/usr/local/zookeeper/conf/keytab
  scp /var/kerberos/krb5kdc/keytab/zkcli.keytab  bigdata01:/usr/local/zookeeper/conf/keytab
  scp /var/kerberos/krb5kdc/keytab/zkcli.keytab  bigdata02:/usr/local/zookeeper/conf/keytab
  scp /var/kerberos/krb5kdc/keytab/zkcli.keytab  bigdata03:/usr/local/zookeeper/conf/keytab
  ```

- 分发krb5.conf

  ```shell
  scp /etc/krb5.conf bigdata01:/etc
  scp /etc/krb5.conf bigdata02:/etc
  scp /etc/krb5.conf bigdata03:/etc
  ```

#### 2.2 配置文件zoo.cfg

添加以下配置

```properties
quorum.auth.enableSasl=true
quorum.auth.learnerRequireSasl=true
quorum.auth.serverRequireSasl=true
quorum.auth.learner.saslLoginContext=QuorumLearner
quorum.auth.server.saslLoginContext=QuorumServer
quorum.auth.kerberos.servicePrincipal=zookeeper/_HOST
quorum.cnxn.threads.size=6
```

#### 2.3 配置文件java.env

```shell
touch /usr/local/zookeeper/conf/java.env

vim /usr/local/zookeeper/conf/java.env
SERVER_JVMFLAGS="-Djava.security.auth.login.config=/usr/local/zookeeper/conf/jaas/jaas.conf -Djava.security.krb5.conf=/etc/krb5.conf"
```

#### 2.4 配置文件jaas.conf

```shell
ssh bigdata01 "mkdir -p /usr/local/zookeeper/conf/jaas"
ssh bigdata02 "mkdir -p /usr/local/zookeeper/conf/jaas"
ssh bigdata03 "mkdir -p /usr/local/zookeeper/conf/jaas"

touch /usr/local/zookeeper/conf/jaas/jaas.conf
vim /usr/local/zookeeper/conf/jaas/jaas.conf
QuorumServer {
       com.sun.security.auth.module.Krb5LoginModule required
       useKeyTab=true
       keyTab="/usr/local/zookeeper/conf/keytab/zookeeper.keytab"
       storeKey=true
       useTicketCache=false
       debug=true
       principal="zookeeper/${hostname}@HADOOP.COM";
};
 
QuorumLearner {
       com.sun.security.auth.module.Krb5LoginModule required
       useKeyTab=true
       keyTab="/usr/local/zookeeper/conf/keytab/zookeeper.keytab"
       storeKey=true
       useTicketCache=false
       debug=true
       principal="zookeeper/${hostname}@HADOOP.COM";
};
```

> [!TIP]
>
> `${hostname}`一般为主机名

#### 2.5 问题总结

- No password provided问题

  ```
  javax.security.sasl.SaslException: Failed to initialize authentication mechanism using SASL
  	at org.apache.zookeeper.server.quorum.auth.SaslQuorumAuthServer.<init>(SaslQuorumAuthServer.java:63)
  	at org.apache.zookeeper.server.quorum.QuorumPeer.initialize(QuorumPeer.java:1115)
  	at org.apache.zookeeper.server.quorum.QuorumPeerMain.runFromConfig(QuorumPeerMain.java:223)
  	at org.apache.zookeeper.server.quorum.QuorumPeerMain.initializeAndRun(QuorumPeerMain.java:137)
  	at org.apache.zookeeper.server.quorum.QuorumPeerMain.main(QuorumPeerMain.java:91)
  Caused by: javax.security.auth.login.LoginException: No password provided
  ```

  需要检查jaas.conf配置文件里面的keyTab和principal配置是否正确

- Encryption type Unknown (20) is not supported/enabled问题

  ```
  Caused by: sun.security.krb5.KrbException: Encryption type Unknown (20) is not supported/enabled
  ```

  这个是因为jce的问题，Java 加密扩展（JCE）原生的 API 存在一定的限制，比如说加密的长度等，Oracle 官方提供的解决办法是，下载新的加密 jar 包替换本地 jdk 或者 jre 目录下原生的 jar 包。下载地址： [Java Cryptography Extension (JCE) Unlimited Strength Jurisdiction Policy Files for JDK/JRE Download](https://www.oracle.com/java/technologies/javase-jce-all-downloads.html)。

  JDK9 及更高版本附带了无限制策略文件，并在默认情况下使用，所以不需要再额外处理，对于低版本则需要更新
