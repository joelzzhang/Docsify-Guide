## 磁盘管理

### lsblk命令

通过lsblk命令查看当前挂载的磁盘情况

```shell
[root@localhost /]# lsblk 
NAME            MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda               8:0    0   30G  0 disk 
├─sda1            8:1    0  300M  0 part /boot
├─sda2            8:2    0   17G  0 part 
│ ├─centos-root 253:0    0   15G  0 lvm  /
│ └─centos-swap 253:1    0    2G  0 lvm  [SWAP]
└─sda3            8:3    0 12.7G  0 part /data
sr0              11:0    1 1024M  0 rom  
```

### findmnt命令

通过findmnt查看文件系统详细信息

```shell
[root@localhost data]# findmnt
TARGET                                SOURCE                  FSTYPE      OPTIONS
/                                     /dev/mapper/centos-root xfs         rw,relatime,seclabel,attr2,inode64,noquota
├─/sys                                sysfs                   sysfs       rw,nosuid,nodev,noexec,relatime,seclabel
│ ├─/sys/kernel/security              securityfs              securityfs  rw,nosuid,nodev,noexec,relatime
│ ├─/sys/fs/cgroup                    tmpfs                   tmpfs       ro,nosuid,nodev,noexec,seclabel,mode=755
│ │ ├─/sys/fs/cgroup/systemd          cgroup                  cgroup      rw,nosuid,nodev,noexec,relatime,seclabel,xattr,release_agent=/usr/lib/systemd/systemd-cgroups-agent,name=systemd
│ │ ├─/sys/fs/cgroup/cpu,cpuacct      cgroup                  cgroup      rw,nosuid,nodev,noexec,relatime,seclabel,cpuacct,cpu
│ │ ├─/sys/fs/cgroup/net_cls,net_prio cgroup                  cgroup      rw,nosuid,nodev,noexec,relatime,seclabel,net_prio,net_cls
│ │ ├─/sys/fs/cgroup/devices          cgroup                  cgroup      rw,nosuid,nodev,noexec,relatime,seclabel,devices
│ │ ├─/sys/fs/cgroup/cpuset           cgroup                  cgroup      rw,nosuid,nodev,noexec,relatime,seclabel,cpuset
│ │ ├─/sys/fs/cgroup/memory           cgroup                  cgroup      rw,nosuid,nodev,noexec,relatime,seclabel,memory
│ │ ├─/sys/fs/cgroup/freezer          cgroup                  cgroup      rw,nosuid,nodev,noexec,relatime,seclabel,freezer
│ │ ├─/sys/fs/cgroup/hugetlb          cgroup                  cgroup      rw,nosuid,nodev,noexec,relatime,seclabel,hugetlb
│ │ ├─/sys/fs/cgroup/blkio            cgroup                  cgroup      rw,nosuid,nodev,noexec,relatime,seclabel,blkio
│ │ ├─/sys/fs/cgroup/pids             cgroup                  cgroup      rw,nosuid,nodev,noexec,relatime,seclabel,pids
│ │ └─/sys/fs/cgroup/perf_event       cgroup                  cgroup      rw,nosuid,nodev,noexec,relatime,seclabel,perf_event
│ ├─/sys/fs/pstore                    pstore                  pstore      rw,nosuid,nodev,noexec,relatime
│ ├─/sys/kernel/config                configfs                configfs    rw,relatime
│ ├─/sys/fs/selinux                   selinuxfs               selinuxfs   rw,relatime
│ └─/sys/kernel/debug                 debugfs                 debugfs     rw,relatime
├─/proc                               proc                    proc        rw,nosuid,nodev,noexec,relatime
│ └─/proc/sys/fs/binfmt_misc          systemd-1               autofs      rw,relatime,fd=32,pgrp=1,timeout=0,minproto=5,maxproto=5,direct,pipe_ino=25195
│   └─/proc/sys/fs/binfmt_misc        binfmt_misc             binfmt_misc rw,relatime
├─/dev                                devtmpfs                devtmpfs    rw,nosuid,seclabel,size=2001072k,nr_inodes=500268,mode=755
│ ├─/dev/shm                          tmpfs                   tmpfs       rw,nosuid,nodev,seclabel
│ ├─/dev/pts                          devpts                  devpts      rw,nosuid,noexec,relatime,seclabel,gid=5,mode=620,ptmxmode=000
│ ├─/dev/hugepages                    hugetlbfs               hugetlbfs   rw,relatime,seclabel
│ └─/dev/mqueue                       mqueue                  mqueue      rw,relatime,seclabel
├─/run                                tmpfs                   tmpfs       rw,nosuid,nodev,seclabel,mode=755
│ └─/run/user/0                       tmpfs                   tmpfs       rw,nosuid,nodev,relatime,seclabel,size=402640k,mode=700
├─/boot                               /dev/sda1               xfs         rw,relatime,seclabel,attr2,inode64,noquota
└─/data                               /dev/sda3               xfs         rw,relatime,seclabel,attr2,inode64,noquota
```

### fdisk命令

通过fdisk命令来管理分区

fdisk 磁盘名称，如：fdisk /dev/sda

```shell
[root@localhost /]# fdisk /dev/sda
欢迎使用 fdisk (util-linux 2.23.2)。

更改将停留在内存中，直到您决定将更改写入磁盘。
使用写入命令前请三思。

命令(输入 m 获取帮助)：m
命令操作
   a   toggle a bootable flag
   b   edit bsd disklabel
   c   toggle the dos compatibility flag
   d   delete a partition 删除分区
   g   create a new empty GPT partition table
   G   create an IRIX (SGI) partition table
   l   list known partition types 列出已知分区
   m   print this menu
   n   add a new partition 新建分区
   o   create a new empty DOS partition table
   p   print the partition table
   q   quit without saving changes
   s   create a new empty Sun disklabel
   t   change a partition's system id
   u   change display/entry units
   v   verify the partition table
   w   write table to disk and exit 保存并推出
   x   extra functionality (experts only)

命令(输入 m 获取帮助)：n
Partition type:
   p   primary (2 primary, 0 extended, 2 free) 主分区
   e   extended 扩展分区
Select (default p): p
分区号 (3,4，默认 3)：3
起始 扇区 (36284416-62914559，默认为 36284416)：
将使用默认值 36284416
Last 扇区, +扇区 or +size{K,M,G} (36284416-62914559，默认为 62914559)：
将使用默认值 62914559
分区 3 已设置为 Linux 类型，大小设为 12.7 GiB

命令(输入 m 获取帮助)：w
The partition table has been altered!

Calling ioctl() to re-read partition table.

WARNING: Re-reading the partition table failed with error 16: 设备或资源忙.
The kernel still uses the old table. The new table will be used at
the next reboot or after you run partprobe(8) or kpartx(8)
正在同步磁盘。
```

### parted命令

```shell
[root@emrmaster01 ~]# parted /dev/vdd
GNU Parted 3.3
Using /dev/vdd
Welcome to GNU Parted! Type 'help' to view a list of commands.
(parted) help                                                             
  align-check TYPE N                       check partition N for TYPE(min|opt) alignment
  help [COMMAND]                           print general help, or help on COMMAND
  mklabel,mktable LABEL-TYPE               create a new disklabel (partition table)
  mkpart PART-TYPE [FS-TYPE] START END     make a partition
  name NUMBER NAME                         name partition NUMBER as NAME
  print [devices|free|list,all|NUMBER]     display the partition table, available devices, free space, all found partitions, or a particular partition
  quit                                     exit program
  rescue START END                         rescue a lost partition near START and END
  resizepart NUMBER END                    resize partition NUMBER
  rm NUMBER                                delete partition NUMBER
  select DEVICE                            choose the device to edit
  disk_set FLAG STATE                      change the FLAG on selected device
  disk_toggle [FLAG]                       toggle the state of FLAG on selected device
  set NUMBER FLAG STATE                    change the FLAG on partition NUMBER
  toggle [NUMBER [FLAG]]                   toggle the state of FLAG on partition NUMBER
  unit UNIT                                set the default unit to UNIT
  version                                  display the version number and copyright information of GNU Parted
(parted) mklabel                                                      
New disk label type? msdos/gpt                        
(parted) mkpart                                                           
Partition type?  primary/extended? primary                                
File system type?  [ext2]? xfs                                            
Start? 0%
End? 100%                                                                 
(parted) print                                                            
Model: Virtio Block Device (virtblk)
Disk /dev/vdd: 537GB
Sector size (logical/physical): 512B/512B
Partition Table: msdos
Disk Flags: 

Number  Start   End    Size   Type     File system  Flags
 1      1049kB  537GB  537GB  primary  xfs          lba

(parted) quit 

```

### partprobe命令

新增分区后如果看不到最新的分区则使用partprobe命令来刷新

```shell
partprobe [OPTION] [DEVICE]
  -d, --dry-run    do not actually inform the operating system
  -s, --summary    print a summary of contents
  -h, --help       display this help and exit
  -v, --version    output version information and exit
```

### mount命令

通过mount来挂载分区，需要先新建待挂载的目录，如：/data

```shell
mount /dev/sda3 /data
```

如果出现如下提示

```shell
[root@localhost /]# mount /dev/sda3 /data
mount: /dev/sda3 写保护，将以只读方式挂载
mount: 未知的文件系统类型“(null)”
```

### mkfs命令

新增分区后需要先格式化分区后才能正常挂载，在linux中默认使用xfs类型的文件，mkfs.xfs就是初始化文件系统得命令，该命令会格式化分区

```shell
[root@localhost /]# mkfs.xfs /dev/sda3
meta-data=/dev/sda3              isize=512    agcount=4, agsize=832192 blks
         =                       sectsz=512   attr=2, projid32bit=1
         =                       crc=1        finobt=0, sparse=0
data     =                       bsize=4096   blocks=3328768, imaxpct=25
         =                       sunit=0      swidth=0 blks
naming   =version 2              bsize=4096   ascii-ci=0 ftype=1
log      =internal log           bsize=4096   blocks=2560, version=2
         =                       sectsz=512   sunit=0 blks, lazy-count=1
realtime =none                   extsz=4096   blocks=0, rtextents=0
[root@localhost /]# mkfs -t ext4 /dev/sdb1
```

格式化后再通过mount命令重新挂载就可以了。

### 开机挂载

通过blkid计算出待挂载分区的UUID

```shell
[root@localhost ~]# blkid /dev/sda3
/dev/sda3: UUID="23943d2f-d3a4-4bf6-ad41-e9bef0cb15a3" TYPE="xfs"
```

然后编辑/etc/fstab文件，将以下内容添加到末尾

```tex
UUID=23943d2f-d3a4-4bf6-ad41-e9bef0cb15a3 /data                   xfs     defaults        0 0
```

然后在编辑完文件之后，我们可以使用mount -a来挂载分区，没有任务输出则表示挂载成功。

### umount命令

通过umount来卸载分区

```shell
[root@localhost ~]# umount /mnt/ 
```

但是有些时候会发生下面的情况

```shell
 [root@localhost mnt]# umount /mnt/ 
 umount: /mnt: device is busy. 
 	(In some cases useful info about processes that use 
 		the device is found by lsof(8) or fuser(1)) 
```

解决方法： 

1.fuser 

	-v 那些进程在占用挂载点

```shell
[root@localhost ~]# fuser -v /data
                     用户     进程号 权限   命令
/data:               root     kernel mount /data
[root@localhost opt]# fuser -v /opt
                     用户     进程号 权限   命令
/opt:                root       9570 ..c.. bash
```

	-km 结束占用挂载点的进程 

```shell
[root@localhost ～]# fuser -km /data
```

2.umount -l 

	-l Lazy unmount.(Requires kernel 2.4.11 or later.) 

```shell
[root@localhost ～]# umount -l /data
```

### 查询指定目录的磁盘占用情况:

```shell
du /目录
  -h  带计量单位
  -s  指令目录占用磁盘大小
  -a  含文件
  -c  列出明细,并显示汇总值
  --max-depth=1 子目录深度
```

### 调整分区大小

```shell
[root@VM-0-10-centos ~]# parted /dev/vda
GNU Parted 3.2
Using /dev/vda
Welcome to GNU Parted! Type 'help' to view a list of commands.
(parted) resizepart                                                     
Partition number? 1                                                       
Warning: Partition /dev/vda1 is being used. Are you sure you want to continue?
Yes/No? yes                                                               
End?  [32.2GB]? 30.2G                                                     
Warning: Shrinking a partition can cause data loss, are you sure you want to continue?
Yes/No? yes                                                               
(parted) q                                                                
Information: You may need to update /etc/fstab.
```



## swap交换分区管理:

### 创建swap分区

> swap分区创建参考普通分区创建即可

```shell
fdisk /dev/vdb
  n
  p
  2048
  +32G
  w
```

> 默认Linux分区的ID是83,我们要更改为82,专门用于swap:

```shell
fdisk /dev/vdb
  t
  1
  l
  82
```

### 使用mkswap写入特殊签名，卷标设置为swap:

```shell
mkswap /dev/vdb1 -L swap
```

### 查看是否创建成功:

```shell
blkid
/dev/sr0: UUID="2023-04-19-10-25-35-00" LABEL="config-2" TYPE="iso9660"
/dev/vda1: UUID="0fb6f32a-9a3c-4a88-b00e-d6a0cd7611c4" TYPE="ext4"
/dev/vdb1: LABEL="swap" UUID="e8914216-592d-4805-8458-8924042f544a" TYPE="swap"
/dev/vdb2: UUID="9a9fd10c-8372-43b4-94a0-b146d07ad655" TYPE="ext4"
```

### 永久挂载:

```shell
vim /etc/fatab
或者
echo "UUID=e8914216-592d-4805-8458-8924042f544a swap swap defaults 0 0" >>/etc/fstab
```

### 挂载swap:

```shell
mount -a
```

### 查看swap的分区挂载:

```shell
swapon -s
```

### 激活交换空间:

```shell
swapon -a
```

### 关闭交换空间:

```shell
swapoff /dev/vdb1
```
