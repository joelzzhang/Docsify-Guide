## MySQL安装部署

## mysqldump使用指南

通过mysqldump命令备份数据前置条件需要一台能连接到mysql的Linux服务器，并确保该服务器已安装了mysql客户端，具体步骤如下：

1、登陆到Linux服务器，命令：

```shell
ssh -p22 root@192.168.0.10
```

2、使用以下命令来dump指定库的所有表结构和表数据，命令：

```shell
mysqldump --compact --single-transaction --set-gtid-purged=off --add-drop-table -c ${database_name}  -h ${host} -u ${username} -p ${password} -P ${port} > file_name.sql
```

如果只需要dump指定库的指定表则使用如下命令：

```shell
mysqldump --compact --single-transaction --set-gtid-purged=off --add-drop-table -c ${database_name} ${table_name} -h ${host} -u ${username} -p ${password} -P ${port} > file_name.sql
```

3、dump命令需修改的参数：

|     参数      |      参数说明      |
| :-----------: | :----------------: |
| database_name |        库名        |
|  table_name   |        表名        |
|      ip       |    数据库实例IP    |
|     port      |   数据库实例端口   |
|   username    | 数据库实例登陆用户 |
|   password    | 数据库实例登陆密码 |
|   file_name   |    dump的文件名    |

4、如果需要将备份的dump文件恢复到其他数据库实例则需要执行以下步骤：

4.1 登陆到一台能连接到mysql的Linux服务器，并确保该服务器已安装了mysql客户端，登陆命令见第1步

4.2 将第2步dump下来的文件上传到当前服务器，命令：

```shell
scp dump.sql root@192.168.0.11:~/
```

如果备份和恢复备份的服务器是同一个Linux服务器，则省略此步骤

4.3 登录到数据库，进入指定库，执行如下命令：

```shell
source 绝对路径/dump.sql
```
