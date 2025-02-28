## chrony简介

- `Chrony`是一个开源的自由软件，它能保持系统时钟与时钟[服务器](https://cloud.tencent.com/act/pro/promotion-cvm?from_column=20065&from=20065)（NTP）同步，让时间保持精确。

- 它由两个程序组成：`chronyd`和`chronyc`。`chronyd`是一个后台运行的守护进程，用于调整内核中运行的系统时钟和时钟服务器同步。它确定计算机增减时间的比率，并对此进行补偿。

## chrony安装

1. 系统版本检查，使用`cat /etc/system-release`
2. 使用`rpm -qa |grep chrony`查看系统是否已安装 chrony，可看到默认已安装 chrony 的包。
3. 如果没有安装环境可使用`dnf install chrony`命令安装或者离线下载 rpm 包安装，[下载地址](http://rpm.pbone.net/index.php3?stat=3&limit=2&srodzaj=3&dl=40&search=chrony)，找到对应版本下载即可。
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

