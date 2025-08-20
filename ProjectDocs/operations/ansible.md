安装ansible

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

```
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

## ansible.cfg文件加载顺序

ansible.cfg文件作为配置文件，ansible会在多个路径下进行读取，读取的顺序如下：

- ANSIBLE_CONFIG：环境变量
- ansible.cfg：当前执行目录下
- .ansible.cfg：~/.ansible.cfg
- /etc/ansible/ansible.cfg

## 配置Ansible主机清单

| 参数名称                   | 描述                                                   |
| -------------------------- | ------------------------------------------------------ |
| ansible_host               | SSH访问的主机名或IP地址                                |
| ansible_port               | SSH访问的目标端口，默认值22                            |
| ansible_user               | SSH登陆使用的用户名，默认值root                        |
| ansible_password           | SSH登陆使用的密码                                      |
| ansible_connection         | ansible使用何种连接模式连接到被管理的节点，默认值smart |
| ansible_private_key_file   | SSH使用的私钥                                          |
| ansible_shell_type         | 命令所使用的shell，默认值sh                            |
| ansible_python_interpreter | 被管理节点上python解释器路径，默认值/usr/bin/python    |
| ansible_*_interpreter      | 非python实现的自定义模块使用的语言解释器路径           |

