# Doris

## 部署前准备

### 集群规划

#### Doris集群端口规划

| 实例名称 | 端口名称               | 默认端口 | 通信方向                       | 说明                                                   |
| -------- | ---------------------- | -------- | ------------------------------ | ------------------------------------------------------ |
| BE       | be_port                | 9060     | FE –> BE                       | BE 上 thrift server 的端口，用于接收来自 FE 的请求     |
| BE       | webserver_port         | 8040     | BE <–> BE                      | BE 上的 http server 的端口                             |
| BE       | heartbeat_service_port | 9050     | FE –> BE                       | BE 上心跳服务端口（thrift），用于接收来自 FE 的心跳    |
| BE       | brpc_port              | 8060     | FE <–> BE，<br/>BE <–> BE      | BE 上的 brpc 端口，用于 BE 之间通讯                    |
| FE       | http_port              | 8030     | FE <–> FE，<br/>Client <–>FE   | FE 上的 http server 端口                               |
| FE       | rpc_port               | 9020     | BE –> FE，<br/>FE <–> FE       | FE 上的 thrift server 端口，每个 fe 的配置需要保持一致 |
| FE       | query_port             | 9030     | Client <–> FE                  | FE 上的 MySQL server 端口                              |
| FE       | edit_log_port          | 9010     | FE <–> FE                      | FE 上的 bdbje 之间通信用的端口                         |
| Broker   | broker_ipc_port        | 8000     | FE –> Broker，<br/>BE –>Broker | Broker 上的 thrift server，用于接收请求                |

#### 节点规划

| Host       | IP           | Role       |
| ---------- | ------------ | ---------- |
| fe-test-01 | 192.168.0.31 | FE         |
| be-test-01 | 192.168.0.32 | BE、Broker |
| be-test-02 | 192.168.0.33 | BE、Broker |
| be-test-03 | 192.168.0.34 | BE、Broker |

#### Java环境安装

```shell
tar -zxvf /home/weihu/jdk-8u431-linux-aarch64.tar.gz && mv jdk1.8.0_431/ /usr/share/
ll /usr/share/jdk1.8.0_431
# 配置全局环境变量
vim /etc/profile
export JAVA_HOME=/usr/share/jdk1.8.0_431
export PATH=$JAVA_HOME/bin:$PATH
export CLASSPATH=.:$JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar
source /etc/profile

java -version
```

#### 数据盘格式化挂载

```shell
# 1、创建数据目录
mkdir -p /data01 /data02 /data03 /data04 /data05 /data06 /data07 /data08 /data09 /data10 /data11 /data12
# 2、格式化磁盘和挂载
mkfs.xfs -f /dev/sda && mount /dev/sda /data01
mkfs.xfs -f /dev/sdb && mount /dev/sdb /data02
mkfs.xfs -f /dev/sdc && mount /dev/sdc /data03
mkfs.xfs -f /dev/sdd && mount /dev/sdd /data04
mkfs.xfs -f /dev/sde && mount /dev/sde /data05
mkfs.xfs -f /dev/sdf && mount /dev/sdf /data06
mkfs.xfs -f /dev/sdg && mount /dev/sdg /data07
mkfs.xfs -f /dev/sdh && mount /dev/sdh /data08
mkfs.xfs -f /dev/sdk && mount /dev/sdk /data09
mkfs.xfs -f /dev/sdl && mount /dev/sdl /data10
mkfs.xfs -f /dev/sdm && mount /dev/sdm /data11
mkfs.xfs -f /dev/sdn && mount /dev/sdn /data12
# 3、永久挂载
vim /etc/fstab
UUID=f4744bfa-c7d0-46ac-aa37-75a50c60d65a /data01 xfs defaults 0 0
UUID=be179993-7fc9-4412-b6fe-28c4701c1a9b /data02 xfs defaults 0 0
UUID=890302dc-4546-4303-8e73-511488f59192 /data03 xfs defaults 0 0
UUID=8b022fea-203e-45c3-ac49-87b52c14dd4b /data04 xfs defaults 0 0
UUID=ddc79685-f4c0-410a-aeda-60237100a5dd /data05 xfs defaults 0 0
UUID=74e70ee6-804a-4984-ae08-c144e422d5dd /data06 xfs defaults 0 0
UUID=439157f4-e286-4046-9f47-66099178cfd2 /data07 xfs defaults 0 0
UUID=614af872-0956-4090-a73f-1e3dbfeff519 /data08 xfs defaults 0 0
UUID=75751e31-bc62-4f14-a8e8-45fbb361c878 /data09 xfs defaults 0 0
UUID=dd08a106-c1fe-48e0-8acc-99c48ff039f4 /data10 xfs defaults 0 0
UUID=eba33118-120c-4567-99b1-f5067a7621df /data11 xfs defaults 0 0
UUID=85c959b1-aa81-4ac4-a331-f1337cfaed01 /data12 xfs defaults 0 0

#磁盘挂载优化
UUID=85c959b1-aa81-4ac4-a331-f1337cfaed01 /dfs2 xfs defaults,noatime,nodiratime,inode64 0 0
```

### 操作系统检查

在部署 Doris 时，需要对以下操作系统项进行检查：

- 确保关闭 swap 分区
- 确保系统关闭透明大页
- 确保系统有足够大的虚拟内存区域
- 确保 CPU 不使用省电模式
- 确保网络连接溢出时自动重置新连接
- 确保 Doris 相关端口畅通或关闭系统防火墙
- 确保系统有足够大的打开文件句柄数
- 确定部署集群机器安装 NTP 服务

#### 关闭 swap 分区

在部署 Doris 时，建议关闭 swap 分区。swap 分区是内核发现内存紧张时，会按照自己的策略将部分内存数据移动到配置的 swap 分区，由于内核策略不能充分了解应用的行为，会对 Doris 性能造成较大影响。所以建议关闭。

临时关闭，下次机器启动时，swap 还会被打开。

```shell
swapoff -a
```

永久关闭，使用 Linux root 账户，注释掉 /etc/fstab 中的 swap 分区，重启即可彻底关闭 swap 分区。

```shell
# /etc/fstab
# <file system>        <dir>         <type>    <options>             <dump> <pass>
tmpfs                  /tmp          tmpfs     nodev,nosuid          0      0
/dev/sda1              /             ext4      defaults,noatime      0      1
# /dev/sda2              none          swap      defaults              0      0
/dev/sda3              /home         ext4      defaults,noatime      0      2
```

#### 关闭系统透明大页

在高负载低延迟的场景中，建议关闭操作系统透明大页（Transparent Huge Pages, THP），避免其带来的性能波动和内存碎片问题，确保 Doris 能够稳定高效地使用内存。

使用以下命令临时关闭透明大页：

```shell
echo madvise > /sys/kernel/mm/transparent_hugepage/enabled
echo madvise > /sys/kernel/mm/transparent_hugepage/defrag
```

如果需要永久关闭透明大页，可以使用以下命令，在下一次宿主机重启后生效：

```shell
cat >> /etc/rc.d/rc.local << EOF
   echo madvise > /sys/kernel/mm/transparent_hugepage/enabled
   echo madvise > /sys/kernel/mm/transparent_hugepage/defrag
EOF
chmod +x /etc/rc.d/rc.local
```

#### 增加虚拟内存区域

为了保证 Doris 有足够的内存映射区域来处理大量数据，需要修改 VMA（虚拟内存区域）。如果没有足够的内存映射区域，Doris 在启动或运行时可能会遇到 `Too many open files` 或类似的错误。

通过以下命令可以永久修改虚拟内存区域至少为 2000000，并立即生效：

```shell
cat >> /etc/sysctl.conf << EOF
vm.max_map_count = 2000000
EOF

# Take effect immediately

sysctl -p
```

#### 禁用 CPU 省电模式

在部署 Doris 时检修关闭 CPU 的省电模式，以确保 Doris 在高负载时提供稳定的高性能，避免由于 CPU 频率降低导致的性能波动、响应延迟和系统瓶颈，提高 Doris 的可靠性和吞吐量。如果您的 CPU 不支持 Scaling Governor，可以跳过此项配置。

通过以下命令可以关闭 CPU 省电模式：

```shell
echo 'performance' | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
```

#### 网络连接溢出时自动重置新连接

在部署 Doris 时，需要确保在 TCP 连接的发送缓冲区溢出时，连接会被立即中断，以防止 Doris 在高负载或高并发情况下出现缓冲区阻塞，避免连接被长时间挂起，从而提高系统的响应性和稳定性。

通过以下命令可以永久设置系统自动重置新链接，并立即生效：

```shell
cat >> /etc/sysctl.conf << EOF
net.ipv4.tcp_abort_on_overflow=1
EOF

# Take effect immediately

sysctl -p
```

#### 相关端口畅通

如果发现端口不通，可以试着关闭防火墙，确认是否是本机防火墙造成。如果是防火墙造成，可以根据配置的 Doris 各组件端口打开相应的端口通信。

```shell
# 关闭防火墙
sudo systemctl stop firewalld.service
sudo systemctl disable firewalld.service
# 关闭SELinux
# 查看当前SELinux状态
getenforce  # 可能返回Enforcing、Permissive或Disabled
# 临时将SELinux设置为Permissive模式
setenforce 0
# 永久禁用 SELinux
sed -i 's/^SELINUX=.*/SELINUX=disabled/' /etc/selinux/config
# 重启生效
shutdown -r now
```

#### 增加系统的最大文件句柄数

Doris 由于依赖大量文件来管理表数据，所以需要将系统对程序打开文件数的限制调高。

通过以下命令可以调整最大文件句柄数。在调整后，需要重启会话以生效配置：

```shell
vi /etc/security/limits.conf
* soft nofile 1000000
* hard nofile 1000000
```

#### 安装并配置 NTP 服务

Doris 的元数据要求时间精度要小于 5000ms，所以所有集群所有机器要进行时钟同步，避免因为时钟问题引发的元数据不一致导致服务出现异常。

通常情况下，可以通过配置 NTP 服务保证各节点时钟同步。

```shell
sudo systemctl start_ntpd.service
sudo systemctl enable_ntpd.service
```

## 开始部署

存算一体集群架构如下，部署存算一体集群分为四步：

![存算一体架构](https://doris.apache.org/zh-CN/assets/images/apache-doris-technical-overview-b8c5cb11b57d2f6559fa397d9fd0a8a0.png)

1. **部署 FE Master 节点**：部署第一个 FE 节点作为 Master 节点；
2. **部署 FE 集群**：部署 FE 集群，添加 Follower 或 Observer FE 节点；
3. **部署 BE 节点**：向 FE 集群中注册 BE 节点；
4. **验证集群正确性**：部署完成后连接并验证集群正确性。

### Doris部署步骤

#### 第 1 步：部署 FE Master 节点

1. **创建元数据路径**

   在部署 FE 时，建议与 BE 节点数据存储在不同的硬盘上。

   在解压安装包时，会默认附带 `doris-meta` 目录，建议为元数据创建独立目录，并将其软连接到默认的 `doris-meta` 目录。生产环境应使用单独的 SSD 硬盘，不建议将其放在 Doris 安装目录下；开发和测试环境可以使用默认配置。

   ```ini
   ## Use a separate disk for FE metadata
   mkdir -p /data/doris-meta
      
   ## Create FE metadata directory symlink
   ln -s /data/doris-meta /opt/apache-doris-2.1.7/fe/doris-meta
   ```

2. **修改 FE 配置文件**

   FE 的配置文件在 FE 部署路径下的 `conf` 目录中，启动 FE 节点前需要修改 `conf/fe.conf`。

   在部署 FE 节点之前，建议调整以下配置：

   ```ini
   ## modify Java Heap
   JAVA_OPTS="-Xmx16384m -XX:+UseMembar -XX:SurvivorRatio=8 -XX:MaxTenuringThreshold=7 -XX:+PrintGCDateStamps -XX:+PrintGCDetails -XX:+UseConcMarkSweepGC -XX:+UseParNewGC -XX:+CMSClassUnloadingEnabled -XX:-CMSParallelRemarkEnabled -XX:CMSInitiatingOccupancyFraction=80 -XX:SoftRefLRUPolicyMSPerMB=0 -Xloggc:$DORIS_HOME/log/fe.gc.log.$DATE"
      
   ## modify case sensitivity
   lower_case_table_names = 1
     
   ## modify network CIDR 
   priority_networks = 10.1.3.0/24
      
   ## modify Java Home
   JAVA_HOME = <your-java-home-path>
   ```

   参数解释如下，更多详细配置项请参考 [FE 配置项](https://doris.apache.org/zh-CN/docs/admin-manual/config/fe-config)：

   | 参数                   | 修改建议                                                  |
   | ---------------------- | --------------------------------------------------------- |
   | JAVA_OPTS              | 指定参数 `-Xmx` 调整 Java Heap，生产环境建议 16G 以上。   |
   | lower_case_table_names | 设置大小写敏感，建议调整为 1，即大小写不敏感。            |
   | priority_networks      | 网络 CIDR，更具网络 IP 地址指定。在 FQDN 环境中可以忽略。 |
   | JAVA_HOME              | 建议 Doris 使用独立于操作系统的 JDK 环境。                |

3. **启动 FE 进程**

   通过以下命令可以启动 FE 进程

   ```shell
   bin/start_fe.sh --daemon
   ```

   FE 进程将在后台启动，日志默认保存在 `log/` 目录。如果启动失败，可通过查看 `log/fe.log` 或 `log/fe.out` 文件获取错误信息。建议创建`/var/log/doris/fe`日志目录并链接到`$DORIS_HOME/fe/log`目录

4. **检查 FE 启动状态**

   通过 MySQL 客户端连接 Doris 集群，初始化用户为 `root`，默认密码为空。

   ```sql
   mysql -uroot -P<fe_query_port> -h<fe_ip_address>
   ```

   连接到 Doris 集群后，可以通过 `show frontends` 命令查看 FE 的状态，通常要确认以下几项

   - Alive 为 `true` 表示节点存活；
   - Join 为 `true` 表示节点加入到集群中，但不代表当前还在集群内（可能已失联）；
   - IsMaster 为 `true` 表示当前节点为 Master 节点。

#### 第 2 步：部署 FE 集群（可选）

生产环境建议至少部署 3 个节点。在部署过 FE Master 节点后，需要再部署两个 FE Follower 节点。

1. **创建元数据目录**

   参考部署 FE Master 节点，创建 `doris-meta` 目录

2. **修改 FE Follower 节点配置文件**

   参考部署 FE Master 节点，修改 FE Follower 节点配置文件。通常情况下，可以直接复制 FE Master 节点的配置文件。

3. **在 Doris 集群中注册新的 FE Follower 节点**

   在启动新的 FE 节点前，需要先在 FE 集群中注册新的 FE 节点。

   ```mysql
   ## connect a alive FE node
   mysql -uroot -P<fe_query_port> -h<fe_ip_address>
   
   ## registe a new FE follower node
   ALTER SYSTEM ADD FOLLOWER "<fe_ip_address>:<fe_edit_log_port>"
   ALTER SYSTEM ADD FOLLOWER "192.168.0.33:9010"
   ```

   如果要添加 Observer 节点，可以使用 `ADD OBSERVER` 命令

   ```mysql
   ## register a new FE observer node
   ALTER SYSTEM ADD OBSERVER "<fe_ip_address>:<fe_edit_log_port>"
   ```

   注意

   - FE Follower（包括 Master）节点的数量建议为奇数，建议部署 3 个组成高可用模式。
   - 当 FE 处于高可用部署时（1 个 Master，2 个 Follower），我们建议通过增加 Observer FE 来扩展 FE 的读服务能力

4. **启动 FE Follower 节点**

   通过以下命令，可以启动 FE Follower 节点，并自动同步元数据。

   ```shell
   bin/start_fe.sh --helper <helper_fe_ip>:<fe_edit_log_port> --daemon
   ```

   其中，`helper_fe_ip` 是 FE 集群中任何存活节点的 IP 地址。`--helper` 参数仅在第一次启动 FE 时需要，之后重启无需指定。

5. **判断 Follower 节点状态**

   与 FE Master 节点状态判断相同，添加 Follower 节点后，可通过 `show frontends` 命令查看节点状态，IsMaster 应为 `false`。

#### 第 3 步：部署 BE 节点

1. **创建数据目录**

   BE 进程应用于数据的计算与存储。数据目录默认放在 `be/storage` 下。生产环境通常将 BE 数据与 BE 部署文件分别存储在不同的硬盘上。BE 支持数据分布在多盘上以更好的利用多块硬盘的 I/O 能力。

   ```bash
   ## Create a BE data storage directory on each data disk
   mkdir -p <be_storage_root_path>
   ```

2. **修改 BE 配置文件**

   BE 的配置文件在 BE 部署路径下的 conf 目录中，启动 BE 节点前需要修改 `conf/be.conf`。

   ```bash
   ## modify storage path for BE node
   
   storage_root_path=/home/disk1/doris,medium:HDD;/home/disk2/doris,medium:SSD
   
   ## modify network CIDR 
   
   priority_networks = 10.1.3.0/24
   
   ## modify Java Home in be/conf/be.conf
   
   JAVA_HOME = <your-java-home-path>
   ```

   参数解释如下，更多详细配置项请参考 [BE 配置项](https://doris.apache.org/zh-CN/docs/admin-manual/config/be-config)：

   | 参数              | 修改建议                                                  |
   | ----------------- | --------------------------------------------------------- |
   | priority_networks | 网络 CIDR，更具网络 IP 地址指定。在 FQDN 环境中可以忽略。 |
   | JAVA_OPTS         | 指定参数 `-Xmx` 调整 Java Heap，生产环境建议 2G 以上。    |
   | JAVA_HOME         | 建议 Doris 使用独立于操作系统的 JDK 环境。                |

3. **在 Doris 中注册 BE 节点**

   在启动 BE 节点前，需要先在 FE 集群中注册该节点：

   ```bash
   ## connect a alive FE node
   mysql -uroot -P<fe_query_port> -h<fe_ip_address>
      
   ## registe BE node
   ALTER SYSTEM ADD BACKEND "<be_ip_address>:<be_heartbeat_service_port>"
   ```

4. **启动 BE 进程**

   通过以下命令可以启动 BE 进程：

   ```bash
   bin/start_be.sh --daemon
   ```

   BE 进程在后台启动，日志默认保存在 `log/` 目录。如果启动失败，请检查 `log/be.log` 或 `log/be.out` 文件以获取错误信息。建议创建`/var/log/doris/be`日志目录并链接到`$DORIS_HOME/be/log`目录

5. **查看 BE 启动状态**

   连接 Doris 集群后，可通过 `show backends` 命令查看 BE 节点的状态。

   ```bash
   ## connect a alive FE node
   mysql -uroot -P<fe_query_port> -h<fe_ip_address>
      
   ## check BE node status
   show backends;
   ```

   通常情况下需要注意以下几项状态：

   - Alive 为 true 表示节点存活
   - TabletNum 表示该节点上的分片数量，新加入的节点会进行数据均衡，TabletNum 逐渐趋于平均。

### FE高可用部署

用户通过 FE 的查询端口（`query_port`，默认 9030）使用 MySQL 协议连接 Doris。当部署多个 FE 节点时，用户可以在多个 FE 之上部署负载均衡层来实现 Doris 查询的高可用。本案例采用keepalive+lvs的方案来实现Doris FE的高可用，[参考Keepalived安装部署](/ProjectDocs/operations/keepalived.md)

### 集群升级扩容

### 集群优化

#### fe.conf

<table>
<tr>
    <th>参数</th>
    <th>值</th>
    <th>说明</th>
</tr>
<tr>
    <td>max_running_txn_num_per_db</td>
    <td>10000</td>
    <td>高并发导入运行事务数较多，需调高参数。</td>
</tr>
<tr>
    <td>streaming_label_keep_max_second</td>
    <td>300</td>
    <td rowspan="3">由于业务一直在进行高并发的 Stream Load 数据导入操作，而导入过程中 FE 会记录相关的 Load 信息，每次导入产生的内存信息约为 200K。这些内存信息的清理时间由streaming_label_keep_max_second参数控制，默认值为 12 小时，将它调小到 5 分钟后 FE 内存不会耗尽，但是运行一段时间后，发现内存按照 1 小时为周期进行抖动，高峰内存使用率达到 80%。分析代码发现清理 label 的线程每隔label_clean_interval_second运行一次，默认为 1 小时，把它也调小到 5 分钟后，FE 内存很平稳。label_keep_max_second后将删除已完成或取消的加载作业的标签</td>
</tr>
<tr>
    <td>label_keep_max_second</td>
    <td>7200</td>    
</tr>
<tr>
    <td>label_clean_interval_second</td>
    <td>300</td>    
</tr>
<tr>
    <td>enable_round_robin_create_tablet</td>
    <td>true</td>
    <td>创建 Tablet 时，采用 Round Robin 策略，尽量均匀。</td>
</tr>
<tr>
    <td>tablet_rebalancer_type</td>
    <td>partition</td>
    <td>均衡 Tablet 时，采用每个分区内尽量均匀的策略。</td>
</tr>
<tr>
    <td>autobucket_min_buckets</td>
    <td>10</td>
    <td>将自动分桶的最小分桶数从 1 调大到 10，避免日志量增加时分桶不够。</td>
</tr>
<tr>
    <td>max_backend_heartbeat_failure_tolerance_count</td>
    <td>10</td>
    <td>日志场景下 BE 服务器压力较大，可能短时间心跳超时，因此将容忍次数从 1 调大到 10。</td>
</tr>
</table>

#### be.conf



## SQL手册



## 问题记录
