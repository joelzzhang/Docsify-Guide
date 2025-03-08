## 原理介绍

## 高可用集群搭建

### 1.环境规划

| IP         | hostname | 角色           | 组件                                   |
| ---------- | -------- | -------------- | -------------------------------------- |
| 10.10.10.3 | hadoop1  | Master，Client | krb5-server krb5-workstation krb5-libs |
| 10.10.10.4 | hadoop2  | Slaver，Client | krb5-server krb5-workstation krb5-libs |
| 10.10.10.5 | hadoop3  | Client         | krb5-workstation krb5-libs             |

### 2.准备工作

#### 2.1 修改hostname

```bash
[root@hadoop3 ~]# vim /etc/hostname 
hadoop1
#或者是通过以下命令也可以修改hostname
[root@hadoop3 ~]# hostnamectl hadoop1
```

#### 2.2 修改hosts配置

```bash
[root@hadoop3 ~]# vim /etc/hosts
10.10.10.3 hadoop1
10.10.10.4 hadoop2
10.10.10.5 hadoop3
```

#### 2.3 ssh免密登录

```bash
# 在本机生成非对称密钥
[root@hadoop3 ~]# ssh-keygen
Enter passphrase (empty for no passphrase): 
Enter same passphrase again: 
Your identification has been saved in /root/.ssh/id_rsa.
Your public key has been saved in /root/.ssh/id_rsa.pub.
The key fingerprint is:
SHA256:DuGJdvNDDXvXVehdVnCZ3zSGMKIXxnuCz1sQUi00FBo root@hadoop1
The key's randomart image is:
+---[RSA 2048]----+
|       E=Xoo. ooB|
|       .=++....*=|
|      .o+.+  ..+*|
|     o +.B . ...+|
|    o * S * . .  |
|   . . * + o     |
|        + o      |
|         o       |
|                 |
+----[SHA256]-----+
# 查看生成的密钥
[root@hadoop3 ~]# ll
总用量 16
-rw-------. 1 root root  987 10月 31 16:32 authorized_keys
-rw-------. 1 root root 1679 11月  9 16:05 id_rsa
-rw-r--r--. 1 root root  394 11月  9 16:05 id_rsa.pub
-rw-r--r--. 1 root root  532 11月  2 09:49 known_hosts
# 复制公钥到其他机器
[root@hadoop3 ~]# ssh-copy-id -i ~/.ssh/id_rsa.pub  root@hadoop2
/usr/bin/ssh-copy-id: INFO: Source of key(s) to be installed: "id_rsa.pub"
/usr/bin/ssh-copy-id: INFO: attempting to log in with the new key(s), to filter out any that are already installed
/usr/bin/ssh-copy-id: INFO: 1 key(s) remain to be installed -- if you are prompted now it is to install the new keys
root@hadoop2's password:
```

#### 2.4 安装ntp服务

参考[Linux时钟同步章节](./time-sync.md)


### 3.安装Kerberos

#### 3.1 安装Kerberos主节点

- hadoop1节点为主节点，需安装服务端和客户端

  ```bash
  [root@hadoop3 ~]# yum -y install krb5-server krb5-workstation krb5-libs
  ```

- hadoop2节点为从节点，需安装服务端和客户端

  ```bash
  [root@hadoop3 ~]# yum -y install krb5-server krb5-workstation krb5-libs
  ```

- hadoop3安装客户端，只需安装客户端即可

  ```bash
  [root@hadoop3 ~]# yum -y install krb5-workstation krb5-libs
  ```

#### 3.2 配置Kerberos服务相关文件

- 修改`krb5.conf`

  ```bash
  [root@hadoop3 ~]# vim etc/krb5.conf
  # Configuration snippets may be placed in this directory as well
  includedir /etc/krb5.conf.d/
  
  # 块配置日志相关
  [logging]
   default = FILE:/var/log/krb5libs.log
   kdc = FILE:/var/log/krb5kdc.log
   admin_server = FILE:/var/log/kadmind.log
  
  # 配置默认的设置，包括ticket的生存周期等
  [libdefaults]
   dns_lookup_realm = false
   ticket_lifetime = 24h
   renew_lifetime = 7d
   forwardable = true
  #  rdns = false
   pkinit_anchors = FILE:/etc/pki/tls/certs/ca-bundle.crt
  # 默认的realm。如 HADOOP.COM，当客户端在连接或者获取主体的时候，当没有输入领域的时候，该值为默认值(列如：使用kinit admin/admin 获取主体的凭证时，没有输入领域，而传到kdc服务器的时候，会变成 admin/admin@HADOOP.COM )
   default_realm = HADOOP.COM
  #  default_ccache_name = KEYRING:persistent:%{uid}
  
  # 表示一个公司或者一个组织。逻辑上的授权认证范围，可以配置多个realm
  [realms]
  HADOOP.COM = {
  # 代表要kdc的位置。格式是机器名
   kdc = hadoop1
   kdc = hadoop2 #添加从节点host
  # 代表admin的位置。格式是机器名
   admin_server = hadoop1
  }
  
  # Kerberos内的域和主机名的域的一个对应关系
  [domain_realm]
  .hadoop1.com = HADOOP.COM
  hadoop1.com = HADOOP.COM
  ```

- 修改`kdc.conf`

  ```bash
  [root@hadoop3 ~]# vi /var/kerberos/krb5kdc/kdc.conf
  [kdcdefaults]
   kdc_ports = 88
   kdc_tcp_ports = 88
  
  [realms]
   HADOOP.COM = {
    #master_key_type = aes256-cts
    acl_file = /var/kerberos/krb5kdc/kadm5.acl
    dict_file = /usr/share/dict/words
    admin_keytab = /var/kerberos/krb5kdc/kadm5.keytab
    supported_enctypes = aes256-cts:normal aes128-cts:normal des3-hmac-sha1:normal arcfour-hmac:normal camellia256-cts:normal camellia128-cts:normal des-hmac-sha1:normal des-cbc-md5:normal des-cbc-crc:normal
   }
  ```

- 修改`kadm5.acl`

  ```bash
  [root@hadoop3 ~]# vi /var/kerberos/krb5kdc/kadm5.acl
  */admin@HADOOP.COM	*
  ```

  第一列： `*/admin@HADOOP.COM`  对应  `Kerberos_principal`  表示主体(`principal`)名称

  第二列：`*` 对应 `permissions`  表示权限

  > 该配置文件主要是用于管理员登陆的acl配置格式，上述的配置表示以`/admin@HADOOP.COM`结尾的用户拥有`*`(`all` 也就是所有)权限，具体配置可根据项目来是否缩小权限。

#### 3.3 创建Kerberos数据库

- 初始化数据库

  ```bash
  # 该命令会在 /var/kerberos/krb5kdc/ 目录下创建 principal 数据库
  [root@hadoop3 ~]# kdb5_util create -s -r HADOOP.COM
  [root@hadoop3 ~]# ll
  总用量 32
  -rw-------. 1 root root 16384 11月  8 15:13 principal
  -rw-------. 1 root root  8192 11月  3 15:48 principal.kadm5
  -rw-------. 1 root root     0 11月  3 15:48 principal.kadm5.lock
  -rw-------. 1 root root     0 11月  8 15:13 principal.ok
  ```

  >  -r 指定域名(也就是在krb5.conf文件[realms]组里面定义的域名) 
  >
  >  -s 选项指定将数据库的主节点密钥存储在文件中，从而可以在每次启动KDC时自动重新生成主节点密钥

- 创建好数据库后重启kdc，并设置开机启动

  ```bash
  [root@hadoop3 ~]# systemctl start krb5kdc
  [root@hadoop3 ~]# systemctl status krb5kdc
  [root@hadoop3 ~]# systemctl enable krb5kdc #开启自启
  #修改配置文件后重启krb5kdc时需要刷新配置
  [root@hadoop3 ~]# systemctl daemon-reload
  
  [root@hadoop3 ~]# systemctl start kadmin
  [root@hadoop3 ~]# systemctl status kadmin
  [root@hadoop3 ~]# systemctl enable kadmin #开启自启
  
  #记得关闭防火墙
  [root@hadoop3 ~]# systemctl status firewalld
  [root@hadoop3 ~]# systemctl stop firewalld
  [root@hadoop3 ~]# systemctl status firewalld
  ```


#### 3.4 创建 kerberos的管理员

```bash
[root@hadoop3 ~]# kadmin.local 
Authenticating as principal admin/admin@HADOOP.COM with password.
kadmin.local:  addprinc admin/admin@HADOOP.COM
```

#### 3.5 生成kerberos管理员密钥文件

```bash
[root@hadoop3 ~]# kadmin.local 
Authenticating as principal admin/admin@HADOOP.COM with password.
kadmin.local:  xst -norandkey -k /var/kerberos/krb5kdc/keytab/admin.keytab  admin/admin@HADOOP.COM
```

> -k 指定keytab文件的位置
>
> -norandkey 表示生成keytab文件时不更新密码，还是用原来的密码

#### 3.6 安装Kerberos从节点

1. 安装Kerberos服务端和客户端

   ```bash
   [root@hadoop3 ~]# yum -y install krb5-server krb5-workstation krb5-libs
   ```

2. 将master上的几个文件拷贝到slave服务器

   ```bash
   #  krb5.conf、kdc.conf、kadmin5.acl、master key stash file
   [root@hadoop3 ~]# rsync /etc/krb5.conf hadoop2:/etc/
   [root@hadoop3 ~]# rsync /var/kerberos/krb5kdc/kadm5.acl hadoop2:/var/kerberos/krb5kdc/
   [root@hadoop3 ~]# rsync /var/kerberos/krb5kdc/kdc.conf hadoop2:/var/kerberos/krb5kdc/
   [root@hadoop3 ~]# scp /var/kerberos/krb5kdc/.k5.HADOOP.COM hadoop2:/var/kerberos/krb5kdc/
   ```

3. 在master节点上生成master、slave节点的凭证，并复制host.keytab到slave节点

   ```bash
   [root@hadoop3 ~]# kadmin.local 
   Authenticating as principal admin/admin@HADOOP.COM with password.
   kadmin.local:  addprinc host/hadoop1 #生成master节点的host凭证，hadoop1是master的hostname
   kadmin.local:  xst -norandkey -k /var/kerberos/krb5kdc/keytab/host.keytab host/hadoop1
   kadmin.local:  addprinc host/hadoop2 #生成master节点的host凭证，hadoop2是slave的hostname
   kadmin.local:  xst -norandkey -k /var/kerberos/krb5kdc/keytab/host.keytab host/hadoop2
   # 凭证和keytab文件生成完成后通过kadmin.local: q退出kadmin命令
   # 复制host.keytab文件到slave节点
   [root@hadoop3 ~]# scp /var/kerberos/krb5kdc/keytab/host.keytab hadoop2:/var/kerberos/krb5kdc/keytab/
   ```

4. 在slave上创建数据库

   ```bash
   [root@hadoop3 ~]# kdb5_util create -s -r HADOOP.COM
   Loading random data
   Initializing database '/var/kerberos/krb5kdc/principal' for realm 'HADOOP.COM',
   master key name 'K/M@HADOOP.COM'
   You will be prompted for the database Master Password.
   It is important that you NOT FORGET this password.
   Enter KDC database master key: 
   Re-enter KDC database master key to verify:
   ```

5. 在slave服务器上创建kpropd.acl文件，并配置上host的主体

   ```bash
   [root@hadoop3 ~]# vim /var/kerberos/krb5kdc/kpropd.acl
   host/hadoop1@HADOOP.COM
   host/hadoop2@HADOOP.COM
   ```

6. 在slave上启动kpropd服务

   ```bash
   # 修改KPROPD_ARGS参数，设置自定义的host.keytab文件，默认为/etc/krb5.keytab
   [root@hadoop3 ~]# vim /etc/sysconfig/kprop
   KPROPD_ARGS=-s /var/kerberos/krb5kdc/keytab/host.keytab
   
   #启动kprop并设置开机启动
   [root@hadoop3 ~]# systemctl daemon-reload
   [root@hadoop3 ~]# systemctl start kprop
   [root@hadoop3 ~]# systemctl status kprop
   [root@hadoop3 ~]# systemctl enable kprop
   ```

7. 在master上将相关数据同步到slave上

   ```bash
   #备份数据库
   [root@hadoop3 ~]# kdb5_util dump /var/kerberos/krb5kdc/dump/kdc.dump
   #同步到slave节点
   [root@hadoop1 keytab]# kprop -f /var/kerberos/krb5kdc/dump/kdc.dump -s /var/kerberos/krb5kdc/keytab/host.keytab  hadoop2
   Database propagation to hadoop2: SUCCEEDED
   ```

8. slave上/var/kerberos/krb5kdc/会多出一些文件

   ```bash
   [root@hadoop2 krb5kdc]# ls -la
   总用量 60
   drwxr-xr-x. 3 root root   200 11月  9 15:45 .
   drwxr-xr-x. 4 root root    33 11月  9 10:27 ..
   -rw-------. 1 root root 15341 11月  9 15:45 from_master
   -rw-------. 1 root root    75 11月  9 14:52 .k5.HADOOP.COM
   -rw-------. 1 root root    21 11月  9 10:40 kadm5.acl
   -rw-------. 1 root root   450 11月  9 10:41 kdc.conf
   drwxr-xr-x. 2 root root    25 11月  9 15:11 keytab
   -rw-r--r--. 1 root root    48 11月  9 11:13 kpropd.acl
   -rw-------. 1 root root 20480 11月  9 15:45 principal
   -rw-------. 1 root root  8192 11月  9 15:45 principal.kadm5
   -rw-------. 1 root root     0 11月  9 14:42 principal.kadm5.lock
   -rw-------. 1 root root     0 11月  9 15:45 principal.ok
   
   ```

9. 至此，可以启动slave上的kdc服务

   ```bash
   #修改配置文件后重启krb5kdc时需要刷新配置
   [root@hadoop3 ~]# systemctl daemon-reload
   [root@hadoop3 ~]# systemctl start krb5kdc
   [root@hadoop3 ~]# systemctl status krb5kdc
   [root@hadoop3 ~]# systemctl enable krb5kdc #开启自启
   ```

10. 测试主从是否生效(成功)

    a. 将master节点的keytab文件都拷贝到客户端

    b. 通过kinit命令来查验keytab是否可以正常验证

    ```bash
    [root@hadoop3 ~]# kinit -kt /var/kerberos/krb5kdc/keytab/hdfs.keytab hdfs/hadoop3
    ```

    轮流停掉master、slave节点的kdc服务，然后在客户端通过kinit命令来验证是否生效

11. 常见问题

    - kprop: 没有那个文件或目录

      ```bash
      [root@hadoop3 ~]# kprop -f /var/kerberos/krb5kdc/dump/kdc.dump hadoop2
      kprop: 没有那个文件或目录 while getting initial credentials
      # 因为在/etc/目录下，找不到host/hadoop1和host/hadoop2的keytab文件（krb5.keytab），所以会报这个错，通过-s指定keytab文件
      [root@hadoop3 ~]# kprop -f /var/kerberos/krb5kdc/dump/kdc.dump -s /var/kerberos/krb5kdc/keytab/host.keytab  hadoop2
      Database propagation to hadoop2: SUCCEEDED
      ```

    - Server rejected authentication

      ```bash
      kprop: Server rejected authentication (during sendauth exchange) while authenticating to server
      kprop: Service key not available signalled from server
      Error text from server: Service key not available
      # 该问题是因为slave节点的/etc目录下没有krb5.keytab文件，以下命令可解决
      [root@hadoop3 ~]# scp /var/kerberos/krb5kdc/keytab/host.keytab hadoop2:/etc/krb5.keytab
      # 或者用以下方法来解决，从kprop.service得知kprop启动是由/usr/sbin/kpropd命令启动的，查看命令
      # /usr/sbin/kpropd -h
      # Usage: /usr/sbin/kpropd [-r realm] [-s srvtab] [-dS] [-f slave_file]
      # 	[-F kerberos_db_file ] [-p kdb5_util_pathname]
      # 	[-x db_args]* [-P port] [-a acl_file]
      # 	[-A admin_server]
      # kprop.service启动的时候会给定一个KPROPD_ARGS参数
      # 通过kpropd -h得知kprop是通过-s来指定自定义的keytab文件，因此可以修改/etc/sysconfig/kprop下的KPROPD_ARGS参数，加上-s /var/kerberos/krb5kdc/keytab/host.keytab即可
      [root@hadoop3 ~]# vim /etc/sysconfig/kprop
      KPROPD_ARGS=-s /var/kerberos/krb5kdc/keytab/host.keytab
      ```

    - slave节点的kdc服务启动报错

      ```bash
      krb5kdc: Unable to decrypt latest master key with the provided master key
       - while fetching master keys list for realm HADOOP.COM
      #该问题是由备节点使用的不是主节点拷贝过来的.k5.CC.LOCAL，以下命令可解决
      [root@hadoop3 ~]# rsync .k5.HADOOP.COM hadoop2:/var/kerberos/krb5kdc/
      ```


#### 3.7 kerberos常用命令

- **添加主体(principal)**

  以下这几个命令都可以创建主体(相当于用户)

  ```bash
  add_principal, addprinc, ank 
  # 服务器操作测试：
  kadmin.local 进入到控制台控制台是以kadmin.local开头的，如下：
  kadmin.local: addprinc hdfs/hadoop1    #创建主体(用户)yjt/yjt 需要输入密码
  kadmin.local: addprinc -pw 123456 hdfs/hadoop1 # 创建yjt/yjt主体，密码使用-pw指定
  kadmin.local: addprinc -randkey hdfs/hadoop1 #生成随机密码
  ```

- **删除主体**

  删除主体，删除的时候会询问是否删除

  ```bash
  delete_principal, delprinc
  # 服务器操作测试：
  kadmin.local: delprinc hdfs/hadoop1
  ```

- **修改凭证**

  修改用户，比如修改延迟到期时间

  ```bash
  modify_principal, modprinc
  # 服务器操作测试：
  kadmin.local: modprinc hdfs/hadoop1
  ```


- **列出当前凭证**

  列出当前凭证

  ```bash
  list_principals, listprincs, get_principals, getprincs
  # 服务器操作测试：
  kadmin.local: listprincs
  ```


- **获取凭据信息**

  获取凭据信息的两个命令

  ```bash
  get_principal, getprinc
  # 服务器操作测试：
  kadmin.local: getprinc hdfs/hadoop1
  ```


- **生成dump文件**

  生成当前Kerberos数据库的备份文件，如主从同步时可以使用该命令来备份数据库，再通过kprop来恢复

  ```bash
  [root@hadoop3 ~]# kdb5_util dump /var/kerberos/krb5kdc/kdc.dump
  [root@hadoop3 ~]# ll
  总用量 20
  -rw-------. 1 root root 13204 11月  9 10:18 kdc.dump
  -rw-------. 1 root root     1 11月  9 10:18 kdc.dump.dump_ok
  ```


- **修改认证主体的密码**

  ```bash
  [root@hadoop3 ~]# kpasswd hdfs/hadoop1
  ```


- **获取凭证**

  ```bash
  [root@hadoop3 ~]# kinit  hdfs/hadoop1    #基于密码，需要输入密码
  [root@hadoop3 ~]# kinit -kt hdfs.keytab hdfs/hadoop1    #基于keytab文件
  ```


- **查看当前的凭证**

  ```bash
  [root@hadoop3 ~]# klist 
  Ticket cache: FILE:/tmp/krb5cc_0
  Default principal: nm/yjt@HADOOP.COM
  ```

- **删除当前认证的缓存**

  ```bash
  [root@hadoop3 ~]# kdestroy 
  ```


- **查看密钥文件的认证主体列表**

  ```bash
  [root@hadoop3 ~]# klist -ket hdfs.keytab 
  Keytab name: FILE:hdfs.keytab
  ```

#### 3.8 主体票据有效期修改

- 修改client端的`/etc/krb5.conf`

  ```ini
  ticket_lifetime = 24h
  renew_lifetime = 180d
  ```

- 修改server端的`/var/kerberos/krb5kdc/kdc.conf`

  ```ini
  max_life = 1d 0h 0m 0s
  max_renewable_life = 180d 0h 0m 0s
  ```

- 然后修改krbtgt账号和业务账号的`maxlife`和`maxrenewlife`的值

  ```shell
  modprinc -maxlife 1d -maxrenewlife 180d +allow_renewable krbtgt/CQ.CTC.COM@CQ.CTC.COM
  modprinc -maxlife 1d -maxrenewlife 180d +allow_renewable flink/emrint01@CQ.CTC.COM
  modprinc -maxlife 1d -maxrenewlife 180d +allow_renewable flink/emrint02@CQ.CTC.COM
  ```

- 手动刷新设置`renewable_lifetime` 

  ```shell
  kinit -r 80days
  ```

  

