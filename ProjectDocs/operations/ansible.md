## 一. Ansible安装

### 1. 在线安装
```bash
yum -y install ansible
```

如果提示找不到ansible

```bash
dnf config-manager --set-enabled crb && dnf install https://dl.fedoraproject.org/pub/epel/epel{,-next}-release-latest-9.noarch.rpm
```

然后再执行

```bash
dnf -y install ansible
```

查看ansible版本

```ini
ansible --version
ansible [core 2.14.18]
  config file = /etc/ansible/ansible.cfg
  configured module search path = ['/root/.ansible/plugins/modules', '/usr/share/ansible/plugins/modules']
  ansible python module location = /usr/lib/python3.9/site-packages/ansible
  ansible collection location = /root/.ansible/collections:/usr/share/ansible/collections
  executable location = /usr/bin/ansible
  python version = 3.9.18 (main, Sep  7 2023, 00:00:00) [GCC 11.4.1 20230605 (Red Hat 11.4.1-2)] (/usr/bin/python3)
  jinja version = 3.1.2
  libyaml = True
```

### 2. 离线安装

```bash
# 在可联网的服务器下载ansible安装包及其依赖包
yum install -y --downloadonly --downloaddir=/opt/ansible ansible

# 打包
tar -zcvf ansible.tar.gz /opt/ansible

# 解压和安装
tar -zxvf ansible.tar.gz -C /opt/ansible
cd /opt/ansible && rpm -ivh *.rpm

ansible --version
ansible [core 2.14.18]
  config file = /etc/ansible/ansible.cfg
  configured module search path = ['/root/.ansible/plugins/modules', '/usr/share/ansible/plugins/modules']
  ansible python module location = /usr/lib/python3.9/site-packages/ansible
  ansible collection location = /root/.ansible/collections:/usr/share/ansible/collections
  executable location = /usr/bin/ansible
  python version = 3.9.18 (main, Sep  7 2023, 00:00:00) [GCC 11.4.1 20230605 (Red Hat 11.4.1-2)] (/usr/bin/python3)
  jinja version = 3.1.2
  libyaml = True
```


### 3. Ansible配置文件加载顺序

ansible.cfg文件作为配置文件，ansible会在多个路径下进行读取，读取的顺序如下：

- ANSIBLE_CONFIG：环境变量
- ansible.cfg：当前执行目录下
- .ansible.cfg：~/.ansible.cfg
- /etc/ansible/ansible.cfg

## 二. 配置Ansible主机清单

Ansible的主机清单分为静态清单和动态清单，主机清单格式包括INI样式或YAML。默认位置是 `/etc/ansible/hosts`。您可以使用 `-i <path>` 选项在命令行上或使用 `inventory` 在配置中指定不同的清单文件。

在最简单的形式中。INI样式的静态清单文件是受管主机的主机名或IP地址的列表，每行一个：

```ini
alpha.example.org
beta.example.org
192.168.1.100
```

但通常而言，可以将受管主机组织为主机组

```ini
[webservers]
alpha.example.org
beta.example.org
192.168.1.100

www[001:006].example.com

[dbservers]
db01.intranet.mydomain.net
db02.intranet.mydomain.net
10.25.1.56

db-[99:101]-node.example.com

[tests:children]   //定义子项
test1
test2
test3
[test1]
192.168.7.42
[test2]
192.168.7.99
[test3]
192.168.7.217
```



验证清单
若有疑问，可使用 ansible 命令验证计算机是否存在于清单中：

```bash
ansible -i inventory.ini  db-99-node.example.com --list-hosts
  hosts (1):
    db-99-node.example.com
    
ansible -i inventory.ini  db-999-node.example.com --list-hosts
[WARNING]: Could not match supplied host pattern, ignoring: db-999-node.example.com
[WARNING]: No hosts matched, nothing to do
  hosts (0):
```

运行以下命令来列出指定组中的所有主机：

```bash
ansible -i inventory.ini  webservers --list-hosts
  hosts (9):
    alpha.example.org
    beta.example.org
    192.168.1.100
    www001.example.com
    www002.example.com
    www003.example.com
    www004.example.com
    www005.example.com
    www006.example.com

```

如果清单中含有名称相同的主机和主机组，ansible 命令将显示警告并以主机作为其目标。主机组则被忽略。



构建清单的技巧

- 确保组名有意义且唯一。组名也区分大小写。

- 避免在组名中使用空格、连字符和前导数字（使用 `floor_19`，而不是 `19th_floor`）。

- 根据主机的**什么**、**哪里**、**何时**逻辑地将主机分组到您的清单中。



向清单添加变量

首先，你可以直接将变量添加到你的主清单文件中的 host 和组中

```ini
[atlanta]
host1 http_port=80 maxRequestsPerChild=808
host2 http_port=303 maxRequestsPerChild=909
```

非标准的 SSH 端口等唯一值可以很好地用作 host 变量。你可以通过在主机名后添加端口号和冒号将它们添加到你的 Ansible 清单中

```
badwolf.example.com:5309
```

连接变量也可以很好地用作 host 变量

```ini
[targets]
localhost              ansible_connection=local
other1.example.com     ansible_connection=ssh        ansible_user=myuser
other2.example.com     ansible_connection=ssh        ansible_user=myotheruser
```

组变量

在 INI 中

```
[atlanta]
host1 ansible_user=myuser
host2 ansible_user=myuser

[atlanta:vars]
ntp_server=ntp.atlanta.example.com
proxy=proxy.atlanta.example.com
```

- 当与 host 内联声明时，INI 值被解释为 Python 字面结构（字符串、数字、元组、列表、字典、布尔值、None）。Host 行每行接受多个 `key=value` 参数。因此，它们需要一种方法来指示空格是值的一部分，而不是分隔符。包含空格的值可以用引号（单引号或双引号）引起来。有关详细信息，请参阅 [Python shlex 解析规则](https://docs.pythonlang.cn/3/library/shlex.html#parsing-rules)。
- 当在 `:vars` 部分中声明时，INI 值被解释为字符串。例如，`var=FALSE` 将创建一个等于 ‘FALSE’ 的字符串。与 host 行不同，`:vars` 部分每行只接受一个条目，因此 `=` 之后的所有内容必须是该条目的值。

在 YAML 中

```
atlanta:
  hosts:
    host1:
    host2:
  vars:
    ntp_server: ntp.atlanta.example.com
    proxy: proxy.atlanta.example.com
```



组变量是一种一次将变量应用于多个 host 的便捷方法。但是，在执行之前，Ansible 总是将变量（包括清单变量）展平到 host 级别。如果一个 host 是多个组的成员，则 Ansible 会从所有这些组中读取变量值。如果在不同的组中为同一变量分配了不同的值，则 Ansible 会根据内部的 [合并规则](https://docs.ansible.org.cn/ansible/latest/inventory_guide/intro_inventory.html#how-we-merge)选择要使用的值。

主机行为参数

| 参数名称                   | 描述                                                         |
| -------------------------- | ------------------------------------------------------------ |
| ansible_host               | SSH访问的主机名或IP地址                                      |
| ansible_port               | SSH访问的目标端口，默认值22                                  |
| ansible_user               | SSH登陆使用的用户名，默认值root                              |
| ansible_password           | SSH登陆使用的密码                                            |
| ansible_connection         | ansible使用何种连接模式连接到被管理的节点，默认值smart       |
| ansible_private_key_file   | SSH使用的私钥                                                |
| ansible_shell_type         | 命令所使用的shell，默认值sh                                  |
| ansible_python_interpreter | 被管理节点上python解释器路径，默认值/usr/bin/python          |
| ansible\_\*_interpreter    | 非python实现的自定义模块使用的语言解释器路径                 |
| ansible_become             | 等同于 `ansible_sudo` 或 `ansible_su`，允许强制执行权限提升  |
| ansible_become_method      | 允许设置权限提升方法                                         |
| ansible_become_user        | 等同于 `ansible_sudo_user` 或 `ansible_su_user`，允许您设置通过权限提升成为的用户 |
| ansible_become_password    | 等同于 `ansible_sudo_password` 或 `ansible_su_password`，允许您设置权限提升密码 |
| ansible_become_exe         | 等同于 `ansible_sudo_exe` 或 `ansible_su_exe`，允许您为所选的提升方法设置可执行文件 |
| ansible_become_flags       | 等同于 `ansible_sudo_flags` 或 `ansible_su_flags`，允许您设置传递给所选提升方法的标志 |

## 三. Ansible模块

## 四. 使用ansible-playbook

剧本目录结构

```ini
ansible
├── add_hosts.yml			#具体任务
├── group_vars				#变量
└── roles					#角色
    └── add_hosts			#具体角色
        ├── files
        ├── handlers
        ├── tasks
        │   └── main.yml 	#任务
        ├── templates
        └── vars
```

