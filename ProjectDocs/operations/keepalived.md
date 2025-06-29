## Keealived

### 离线安装

**安装keepalived的依赖库**

```bash
# 安装编译工具和依赖库
yum install -y gcc openssl-devel libnl3-devel net-snmp-devel
```

**下载安装包**

```bash
wget https://www.keepalived.org/software/keepalived-2.3.4.tar.gz
```

**编译安装**

```bash
# 配置编译选项，添加--prefix后只需删除父目录即可轻松卸载Keepalived的编译版本。
# 此外，这种安装方法允许安装多个版本的Keepalived，而不会互相覆盖。使用符号链接指向所需的版本
./configure --prefix=/usr/local/keepalived-2.3.4

# 编译并安装
make && make install

ln -s /usr/local/keepalived-2.3.4 /usr/local/keepalived
ln -s /usr/local/keepalived/sbin/keepalived /usr/local/bin/keepalived

#如果默认安装则会产生以下文件路径
/etc/keepalived
/usr/local/etc/sysconfig
/usr/local/sbin
/usr/lib/systemd/system
/usr/local/share/man/man8
/usr/local/share/man/man5
/usr/local/share/man/man1
/usr/local/share/snmp/mibs
/usr/local/etc/keepalived/samples
/usr/local/share/doc/keepalived
```

**验证**

```bash
keepalived -v
Keepalived v2.3.4 (06/10,2025)

Copyright(C) 2001-2025 Alexandre Cassen, <acassen@gmail.com>

Built with kernel headers for Linux 5.14.0
Running on Linux 5.14.0-404.el9.x86_64 #1 SMP PREEMPT_DYNAMIC Thu Jan 4 21:14:38 UTC 2024
Distro: CentOS Stream 9

configure options: --prefix=/usr/local/keepalived-2.3.4

Config options:  LVS VRRP VRRP_AUTH VRRP_VMAC OLD_CHKSUM_COMPAT IPROUTE_ETC_DIR=/etc/iproute2 IPROUTE_USR_DIR=/etc/iproute2 INIT=systemd

System options:  VSYSLOG MEMFD_CREATE CLOSE_RANGE IPV6_FREEBIND IPV6_MULTICAST_ALL IPV4_DEVCONF LIBNL3 RTA_ENCAP RTA_EXPIRES RTA_NEWDST RTA_PREF FRA_SUPPRESS_PREFIXLEN FRA_SUPPRESS_IFGROUP FRA_TUN_ID RTAX_CC_ALGO RTAX_QUICKACK RTEXT_FILTER_SKIP_STATS FRA_L3MDEV FRA_UID_RANGE RTAX_FASTOPEN_NO_COOKIE RTA_VIA FRA_PROTOCOL FRA_IP_PROTO FRA_SPORT_RANGE FRA_DPORT_RANGE RTA_TTL_PROPAGATE IFA_FLAGS F_OFD_SETLK LWTUNNEL_ENCAP_MPLS LWTUNNEL_ENCAP_ILA NET_LINUX_IF_H_COLLISION LIBIPTC_LINUX_NET_IF_H_COLLISION LIBIPVS_NETLINK IPVS_DEST_ATTR_ADDR_FAMILY IPVS_SYNCD_ATTRIBUTES IPVS_64BIT_STATS IPVS_TUN_TYPE IPVS_TUN_CSUM IPVS_TUN_GRE VRRP_IPVLAN IFLA_LINK_NETNSID GLOB_BRACE GLOB_ALTDIRFUNC INET6_ADDR_GEN_MODE VRF SO_MARK
```

### 配置keepalived

**keepalived+nginx高可用配置**

```ini
! Configuration File for keepalived

global_defs {
    # 标识本节点的唯一名称（字符串）
    router_id LVS_DEVEL_1
    # 跳过通告地址检查
    vrrp_skip_check_adv_addr
    # 严格遵守VRRP协议（建议启用）
    #vrrp_strict
    # ARP更新间隔（0表示禁用）
    #vrrp_garp_interval 0
    # NDP更新间隔（0表示禁用）
    #vrrp_gna_interval 0
    # 指定日志文件
    #log_file "/var/log/keepalived.log"
    # 日志设备
    #log_facility local0
    # 执行脚本的用户
    script_user root
    enable_script_security 
}

# 健康检查脚本定义（与vrrp_instance里面的track_script配合），健康检查定义要放到vrrp_instance之前
vrrp_script chk_httpd {
    # 脚本路径，不能放在/usr/local目录，权限至少755
    script /etc/keepalived/check_nginx.sh
    # 检查间隔（秒）
    interval 1
    timeout 10
    # 范围[-255..255],负数和fall结合使用，检测失败时优先级降低10；正数和rise结合使用，检测成功时优先级增加10
    weight -10
    # 连续3次失败才判定为故障
    fall 3
    # 连续2次成功才恢复正常
    rise 2
    user root
}

# file文件里面的内容会被vrrp_instance监控读取，只有内容值为0的时候才表示成功
track_file nginx_pid {
    file "/tmp/nginx.txt"
    weight -10

}

# VI_1为实例名称，可自定义
vrrp_instance VI_1 {
    # 初始状态：MASTER或BACKUP
    state MASTER
    # 绑定VIP的网卡名（ifconfig查看）
    interface ens160
    # VRID（0-255），同一组必须相同
    virtual_router_id 51
    # 优先级（0-255），值越高越优先
    priority 100
    # VRRP通告间隔（秒）
    advert_int 1
    # 认证配置（防止非法节点），同一组必须相同
    authentication {
        # 认证类型：PASS或AH
        auth_type PASS
        # 认证密码（最长8字节）
        auth_pass 1111
    }
      
    # VIP配置（可多个）
    virtual_ipaddress {
        # 192.168.200.16/24 VIP及子网掩码,可添加多个VIP
        192.168.31.200
        192.168.31.201
    }
    
    # 使用单播（而非组播）发送心跳，提高可靠性（适用于复杂网络环境）
    # 源IP地址
    unicast_src_ip 192.168.31.100
    # 对端IP地址（Backup节点）
    unicast_peer {
        192.168.31.101
    }

    # Allow packets addressed to the VIPs above to be received
    accept

    # 健康检查脚本（可选）
    track_script {
        # 引用下面定义的脚本
        chk_httpd
    }

    # 监控文件状态
    track_file {
        # 只有文件内容值为0的时候才表示成功，否则均为fault状态
        nginx_pid
    }

    # 高级监控（可选）,监控网卡状态
    track_interface {
        # 网卡故障时触发状态切换
        ens160
    }

    # 心跳间隔（默认 1 秒），根据网络环境适当增大（如 2-5 秒），降低误判概率
    #vrrp_interval 2

    # 抢占模式（默认开启），禁用抢占（MASTER恢复后不夺回VIP），备节点配置此项
    #nopreempt
    # 抢占延迟（秒）
    preempt_delay 30
}
```

**nginx进程检查脚本**

```bash
touch /etc/keepalived/check_nginx.sh

#!/bin/bash
status_file="/tmp/nginx.txt"

if [ $(ps -C nginx --no-header | wc -l) -eq 0 ]; then
    # systemctl restart nginx
    nginx
    sleep 2
    if [ $(ps -C nginx --no-header | wc -l) -gt 0 ]; then
        echo 'nginx restarted'
        echo 0 > $status_file
    fi
    if [ $(ps -C nginx --no-header | wc -l) -eq 0 ]; then
        echo 'nginx restart failed'
        rm -rf $status_file
        exit 1  # 检查失败，触发VIP迁移
    fi
else
   # Nginx 已运行，确保状态文件存在且内容正确
    if [[ ! -f "$status_file" || $(cat "$status_file") != "0" ]]; then
        echo 0 > "$status_file"  # 覆盖写入或创建文件
    fi
fi
exit 0  # 检查成功

chmod +x /etc/keepalived/check_nginx.sh
```

**keealived+lvs高可用配置**

```ini
# VIP和端口
virtual_server 192.168.31.201 80 {
    # 健康检查间隔（秒）
    delay_loop 6
    # 负载均衡算法：rr(轮询)、wrr(加权轮询)、lc(最少连接)、wlc(加权最少连接)、sh(源地址哈希)、dh(目标地址哈希)等
    lb_algo rr
    # 负载均衡模式：NAT、DR、TUN
    lb_kind DR
    # 会话保持时间（秒）
    persistence_timeout 500
    # 协议类型：TCP或UDP
    protocol TCP
    # 健康检查配置,所有real_server不可用时的备用服务器
    sorry_server 192.168.31.102 80
    
    # 真实服务器配置（可多个）
    real_server 192.168.31.102 80 {
        # 权重值（0-255）
        weight 10
        # [HTTP|SSL]健康检查，HTTP监控80端口，SSL监控443端口
        HTTP_GET {
            # 检查URL
            url {
              # 检查路径
              path /index.html
              # 预期哈希值 genhash -s 192.168.31.102 -p 80 -u /index.html
              # ln -s /usr/local/keepalived/sbin/keepalived /usr/bin/genhash
              digest f52043b6e7c8dc6ae0000d580817eb1f
              status_code 200
            }
            # 连接超时（秒）
            connect_timeout 1
            # 重试次数
            retry 2
            # 重试前等待时间（秒）
            delay_before_retry 2
        }
        
        # 其他健康检查方式
        TCP_CHECK {
            # 检查端口
            connect_port 80
            # 连接超时（秒）
            connect_timeout 1
            # 重试次数
            retry 2
            # 重试前等待时间（秒）
            delay_before_retry 2
        }
        
        # 自定义脚本检查
        #SCRIPT_CHECK {
        #    script "/etc/keepalived/check_http.sh"
        #    interval 2
        #    timeout 3
        #    rise 2
        #    fall 3
        #}
    }

    real_server 192.168.31.103 80 {
        # 权重值（0-255）
        weight 10
        # HTTP健康检查
        HTTP_GET {
            # 检查URL
            url {
              # 检查路径
              path /index.html
              # 预期哈希值
              digest 275c049f38d3736adf765e3febe6912e
              status_code 200
            }
            # 连接超时（秒）
            connect_timeout 1
            # 重试次数
            retry 2
            # 重试前等待时间（秒）
            delay_before_retry 2
        }
        
        # 其他健康检查方式
        TCP_CHECK {
            # 检查端口
            connect_port 80
            # 连接超时（秒）
            connect_timeout 1
            # 重试次数
            retry 2
            # 重试前等待时间（秒）
            delay_before_retry 2
        }
        
        # 自定义脚本检查
        #SCRIPT_CHECK {
        #    script "/etc/keepalived/check_http.sh"
        #    interval 2
        #    timeout 3
        #    rise 2
        #    fall 3
        #}
    }
}
```

**给真实服务器lo:0绑定VIP地址、ARP广播**

```bash
#!/bin/bash
VIP=192.168.31.201
case "$1" in
start)
echo "start LVS of REALServer"
/sbin/ifconfig lo:0 $VIP broadcast $VIP netmask 255.255.255.255 up
/sbin/route add -host $VIP dev lo:0
echo "1" >/proc/sys/net/ipv4/conf/lo/arp_ignore
echo "2" >/proc/sys/net/ipv4/conf/lo/arp_announce
echo "1" >/proc/sys/net/ipv4/conf/all/arp_ignore
echo "2" >/proc/sys/net/ipv4/conf/all/arp_announce
sysctl -p >/dev/null 2>&1
;;
stop)
/sbin/ifconfig lo:0 down
/sbin/route del $VIP >/dev/null 2>&1
echo "close LVS Directorserver"
echo "0" >/proc/sys/net/ipv4/conf/lo/arp_ignore
echo "0" >/proc/sys/net/ipv4/conf/lo/arp_announce
echo "0" >/proc/sys/net/ipv4/conf/all/arp_ignore
echo "0" >/proc/sys/net/ipv4/conf/all/arp_announce
;;
*)
echo "Usage: start: $0 start VIP"
echo "       stop:  $0 stop"
exit 1
esac

arp_ignore参数的作用是系统在收到外部的arp请求时，用于控制是否要返回arp响应：
0：响应任意网卡上接收到的对本机IP地址的arp请求（包括环回网卡上的地址），而不管该目的IP是否在接收网卡上。
1：只响应目的IP地址为接收网卡上的本地地址的arp请求。
2：只响应目的IP地址为接收网卡上的本地地址的arp请求，并且arp请求的源IP必须和接收网卡同网段。
3：如果ARP请求数据包所请求的IP地址对应的本地地址其作用域（scope）为主机（host），则不回应ARP响应数据包，如果作用域为全局（global）或链路（link），则回应ARP响应数据包。
4~7：保留未使用
8：不回应所有的arp请求

arp_announce的作用是系统在对外发送arp请求时，用于控制如何选择arp请求数据包的源IP地址。
0：允许使用任意网卡上的IP地址作为arp请求的源IP。
1：尽量避免使用不属于该发送网卡子网的本地地址作为发送arp请求的源IP地址。
2：忽略IP数据包的源IP地址，选择该发送网卡上最合适的本地地址作为arp请求的源IP地址。

arp_ignore和arp_announce参数分别有all,lo,eth1,…等对应不同网卡的具体参数。当all和具体网卡的参数值不一致时，取较大值生效。
```

**启动keepalived**

```bash
systemctl reload keepalived
systemctl status keepalived
systemctl start keepalived
systemctl stop keepalived
ps -ef | grep -v grep | grep nginx | awk '{print $2}' | xargs kill -9
ps -ef | grep -v grep | grep keepalived | awk '{print $2}' | xargs kill -9
```

**参数总结表**

| 参数类别   | 核心参数            | 说明                               |
| ---------- | ------------------- | ---------------------------------- |
| 全局定义   | router_id           | 节点唯一标识                       |
|            | vrrp_strict         | 严格遵守 VRRP 协议（防止异常行为） |
| VRRP 实例  | state               | 初始状态（MASTER/BACKUP）          |
|            | virtual_router_id   | 虚拟路由器 ID（同一组必须相同）    |
|            | priority            | 优先级（值越高越优先）             |
|            | advert_int          | VRRP 通告间隔（秒）                |
|            | authentication      | 认证配置（PASS/AH）                |
|            | virtual_ipaddress   | 虚拟 IP 地址列表                   |
|            | track_script        | 引用健康检查脚本                   |
| 虚拟服务器 | lb_algo             | 负载均衡算法（rr/wrr/lc/wlc 等）   |
|            | lb_kind             | 负载均衡模式（NAT/DR/TUN）         |
|            | persistence_timeout | 会话保持时间（秒）                 |
|            | real_server         | 后端真实服务器配置                 |
| 健康检查   | SSL_GET/TCP_CHECK   | HTTP/TCP 检查方式                  |
|            | script_check        | 自定义脚本检查                     |

**问题总结**

1. 为什么LVS设置了轮询，浏览器测试还是不能轮询，使用curl测试负载均衡时，能够正常的轮询调度到不同的后端主机。
   原因是：curl命令请求时，每次请求都从不同的端口发请求，所以每次lvs都当做一个新的客户端来处理，并且curl请求完之后就关闭了tcp连接；而浏览器则每次刷新tcp连接会保持，会以同一个端口发出请求，所以lvs就会认为是同一个客户端，每次刷新就会指向同一RealServer。如果要想浏览器测试也能达到轮询效果，则需要将lvs的连接处于空闲状态的超时时间设置的很短。

```bash
#查看ipvsadm默认超时时间
ipvsadm -L --timeout
Timeout (tcp tcpfin udp): 900 120 300
   
#900 120 300这三个数值分别是TCP TCPFIN UDP的时间，也就是说一条tcp的连接经过lvs后，lvs会把这台记录保存15分钟，就是因为这个时间过长，所以很多人都会发现做好LVS DR之后轮询现象并没有发生，实践中将此数值调整很小小，使用以下命令调整：
ipvsadm --set 1 1 1
```



  