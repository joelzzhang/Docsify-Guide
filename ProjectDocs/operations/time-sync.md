## NTP介绍

## NTP安装

### 在线安装

```shell
[root@hadoop3 ~]# yum -y install ntp
```

### 离线安装

## NTP配置

```shell
[root@hadoop3 ~]# vim /etc/ntp.conf
#系统时间和BIOS时间的偏差记录
driftfile /var/lib/ntp/drift

#restrict 控制相关权限。
#语法为： restrict IP地址 mask 子网掩码 参数
#其中IP地址也可以是default ，default 就是指所有的IP
#参数有以下几个：
#ignore  ：关闭所有的 NTP 联机服务
#nomodify：客户端不能更改服务端的时间参数，但是客户端可以通过服务端进行网络校时。
#notrust ：客户端除非通过认证，否则该客户端来源将被视为不信任子网
#noquery ：不提供客户端的时间查询：用户端不能使用ntpq，ntpc等命令来查询ntp服务器
#notrap ：不提供trap远端登陆：拒绝为匹配的主机提供模式 6 控制消息陷阱服务。陷阱服务是 ntpdq #控制消息协议的子系统，用于远程事件日志记录程序。
#nopeer ：用于阻止主机尝试与服务器对等连接，并允许欺诈性服务器控制时钟
#kod ： 访问违规时发送KoD包(请求过于频繁)。
#restrict -6 表示IPV6地址的权限设置。

#允许时钟源同步，客户端不能更改服务端的时间参数，但是客户端可以通过服务端进行网络校时，不提供trap远端登陆，阻止主机尝试与服务器对等，并允许欺诈性服务器控制时钟，不提供客户端的时间查询
restrict default nomodify notrap nopeer noquery

#允许本机查询
restrict 127.0.0.1
restrict ::1

#允许内网所有机器（10.0.0.0/8）同步时间，如果不添加该约束默认允许所有IP访问本机同步服务
restrict 10.0.0.0 mask 255.0.0.0 nomodify

#外部时间服务器不可用时，以本地时间作为时间服务
#在NTP协议中，IP地址127.127.1.0是特殊的，它表示本地时钟(Local Clock)
server 127.127.1.0
#stratum 10:设置本地时钟的层级，层级数值越高，优先级越低。
#fudge: 用于配置本地时钟（本地时钟作为备份）
fudge 127.127.1.0 stratum 10

#指定阿里时钟服务器地址作为上层的时钟源
#iburst表示加速同步,在第一次联系时发送一串包，以便快速建立联系
server ntp1.aliyun.com iburst

includefile /etc/ntp/crypto/pw

keys /etc/ntp/keys

disable monitor
logfile /var/log/ntp/ntp.log
```

启动ntp，并设置开机启动

```shell
#启动
[root@hadoop3 ~]# systemctl start ntpd
#查看状态
[root@hadoop3 ~]# systemctl status ntpd
#开机启动
[root@hadoop3 ~]# systemctl enable ntpd
```

## NTP常用命令

```shell
[root@hadoop3 ~]# ntpdate ntp1.aliyun.com
[root@hadoop3 ~]# ntpq -p
     remote           refid      st t when poll reach   delay   offset  jitter
==============================================================================
+120.25.115.20   10.137.53.7      2 u  946 1024  135   29.754   -5.681   2.907
*203.107.6.88    100.107.25.114   2 u  493 1024  347   40.292   -2.793   3.989
[root@hadoop3 ~]# ntpstat 
synchronised to NTP server (203.107.6.88) at stratum 3
   time correct to within 92 ms
   polling server every 1024 s
[root@hadoop3 ~]# ntpdate -u 192.168.31.100
```

ntp常用命令：

| 命令          | 参数选项                                                     | 描述                                                         |
| ------------- | ------------------------------------------------------------ | ------------------------------------------------------------ |
| `ntpdate`     | `-q`：静默模式，不输出任何信息。</br> `-u`：更新所有已配置的服务器。</br> `-s`：指定服务器的IP地址或主机名。</br> `-b`：指定要使用的回显端口。 | 从NTP服务器获取时间并设置本地系统时间。语法：`ntpdate [选项] 服务器地址` |
| `ntpq`        | `-c peers`：显示与所有对等体（peer）的连接状态。</br>  `-p`：显示当前选定的对等体的详细信息。</br>  `-n`：以数字形式显示时间戳。</br>  `-t`：显示所有跟踪日志文件的内容。 | 查询NTP服务器的状态和统计信息。语法：`ntpq [选项]`           |
| `timedatectl` | `--no-ask-password`：在需要输入密码的情况下自动回答“yes”。 </br> `--list-timezones`：列出所有可用的时区。 </br> `--set-timezone`：设置系统的时区。 </br> `--show-timezone`：显示当前系统的时区。 | 查询和设置系统时间和时区。语法：`timedatectl [选项] [动作]`  |



`ntpq -p`的输出说明了当前计算机与ntp server间的信息，具体说明如下：

| 参数   | 描述                         |
| ------ | ---------------------------- |
| remote | 远程服务器的IP地址或名称     |
| refid  | 引用源标识符                 |
| st     | 层级编号                     |
| t      | 类型（例如u表示unspecified） |
| when   | 最后一次更新时间             |
| poll   | 当前轮询周期                 |
| reach  | 可达性标志                   |
| delay  | 延迟时间（毫秒）             |
| offset | 偏移量（毫秒）               |
| jitter | 抖动（毫秒）                 |

> 例如以下样例输出告诉我们该机器已经与`ntp1.aliyun.com`（120.25.115.20）建立了联系，最近一次与时间同步服务同步为946毫秒前。延迟时间约为29.754毫秒，偏移量约-5.681毫秒，抖动值为2.907毫秒。
>
> ```bash
> [root@hadoop3 ~]# ntpq -p
>   remote           refid      st t when poll reach   delay   offset  jitter
> ==============================================================================
> +120.25.115.20   10.137.53.7      2 u  946 1024  135   29.754   -5.681   2.907
> *203.107.6.88    100.107.25.114   2 u  493 1024  347   40.292   -2.793   3.989
> ```

> ![TIP]
> 此外，ntp服务还有其他有用的信息，例如通过运行ntpstat命令查看ntp服务器是否处于活动状态以及最近的一次同步结果。

## chrony简介

- `Chrony`是一个开源的自由软件，它能保持系统时钟与时钟服务器（NTP）同步，让时间保持精确。

- 它由两个程序组成：`chronyd`和`chronyc`。`chronyd`是一个后台运行的守护进程，用于调整内核中运行的系统时钟和时钟服务器同步。它确定计算机增减时间的比率，并对此进行补偿。

## chrony安装

1. 系统版本检查，使用`cat /etc/system-release`
2. 使用`rpm -qa |grep chrony`查看系统是否已安装 chrony，可看到默认已安装 chrony 的包。
3. 如果没有安装环境可使用`dnf -y install chrony`命令安装或者离线下载 rpm 包安装，[下载地址](http://rpm.pbone.net/index.php3?stat=3&limit=2&srodzaj=3&dl=40&search=chrony)，找到对应版本下载即可。
4. 下载完后使用`rpm -ivh chrony-2.1.1-4.el7.centos.x86_64.rpm`安装即可

## 启用chrony的服务

- 服务状态

  ```shell
  rpm -qa chrony
  #启动chrony服务
  systemctl start chronyd.service
  #设置开机同步时间
  systemctl enable chronyd.service
  #查看服务状态
  systemctl status chronyd.service
  ```

-  直接关闭防火墙

  ```shell
  #停止firewalld
  systemctl stop firewalld.service     
  #禁止firewalld开机启动
  systemctl disable firewalld.service  
  ```

-  不关闭防火墙、但允许NTP服务

  ```shell
  firewall-cmd --add-service=ntp --permanent
  firewall-cmd --reload
  ### 因NTP使用123/UDP端口协议，所以允许NTP服务即可
  ```

## 服务端和客户端chrony配置

### 服务端配置

1. 配置文件修改

   `vi /etc/chrony.conf`

   ```shell
   #将所有server都注释掉
   #iburst表示的是首次同步的时候快速同步
   # server 3.centos.pool.ntp.org iburst
   
   #根据实际时间计算出服务器增减时间的比率，然后记录到一个文件中，在系统重启后为系统做出最佳时间 补偿调整。
   driftfile /var/lib/chrony/drift
   
   # 启用实时时钟（RTC）的内核同步。
   # Enable kernel synchronization of the real-time clock (RTC).
   rtcsync
   
   #打开allow或配置允许访问的客户端列表，支持CIDR
   # Allow NTP client access from local network.
   allow 192.168.0.0/16
   allow
   
   #打开local stratum 10注释 即使server端无法从互联网同步时间，也同步本机时间至client
   # Serve time even if not synchronized to a time source.
   local stratum 10
   ```

   服务端只修改以上配置即可，其他的保持不变。

2. 重启下服务端chrony服务，使用`systemctl restart chronyd.service`重启即可。

### 客户端配置

1. 配置文件修改

   `vim /etc/chrony.conf`

   修改 server 即可，删掉其他的，添加要同步时间的源服务器ip，格式如下:

   ```shell
   server 10.10.10.3 iburst
   ```

2. 重启下客户端 chrony 服务，使用`systemctl restart chronyd.service`重启即可。

3. 客户端时间同步

   ```shell
   chronyc sources -v
   chronyc sourcestats
   ```

### chrony配置参数说明

| 参数             | 参数说明                                                     |
| ---------------- | ------------------------------------------------------------ |
| server           | 该参数可以多次用于添加时钟服务器，必须以"server "格式使用。一般而言，你想添加多少服务器，就可以添加多少服务器 |
| stratumweight    | stratumweight指令设置当chronyd从可用源中选择同步源时，每个层应该添加多少距离到同步距离。默认情况下，CentOS中设置为0，让chronyd在选择源时忽略源的层级 |
| driftfile        | chronyd程序的主要行为之一，就是根据实际时间计算出计算机增减时间的比率，将它记录到一个文件中是最合理的，它会在重启后为系统时钟作出补偿，甚至可能的话，会从时钟服务器获得较好的估值 |
| rtcsync          | rtcsync指令将启用一个内核模式，在该模式中，系统时间每11分钟会拷贝到实时时钟（RTC） |
| allow/deny       | 这里你可以指定一台主机、子网，或者网络以允许或拒绝NTP连接到扮演时钟服务器的机器 |
| cmdallow/cmddeny | 跟上面相类似，只是你可以指定哪个IP地址或哪台主机可以通过chronyd使用控制命令 |
| bindcmdaddress   | 该指令允许你限制chronyd监听哪个网络接口的命令包（由chronyc执行）。该指令通过cmddeny机制提供了一个除上述限制以外可用的额外的访问控制等级 |
| makestep         | 通常，chronyd将根据需求通过减慢或加速时钟，使得系统逐步纠正所有时间偏差。在某些特定情况下，系统时钟可能会漂移过快，导致该调整过程消耗很长的时间来纠正系统时钟。该指令强制chronyd在调整期大于某个阀值时步进调整系统时钟，但只有在因为chronyd启动时间超过指定限制（可使用负值来禁用限制），没有更多时钟更新时才生效 |

### chronyc命令参数说明

| 参数       | 参数说明                         |
| :--------- | :------------------------------- |
| accheck    | 检查NTP访问是否对特定主机可用    |
| activity   | 该命令会显示有多少NTP源在线/离线 |
| add server | 手动添加一台新的NTP服务器。      |
| clients    | 在客户端报告已访问到服务器       |
| delete     | 手动移除NTP服务器或对等服务器    |
| settime    | 手动设置守护进程时间             |
| tracking   | 显示系统时间信息                 |

## 常用命令

```shell
#查看时间同步源
chronyc sources -v
#立即手工同步
chronyc -a makestep
#查看时间同步源状态
chronyc sourcestats -v
#设置硬件时间,硬件时间默认为UTC：
timedatectl set-local-rtc 1
#启用NTP时间同步
timedatectl set-ntp yes
#校准时间服务器
chronyc tracking
#最后需要注意的是，配置完/etc/chrony.conf后，需重启chrony服务，否则可能会不生效。
```

