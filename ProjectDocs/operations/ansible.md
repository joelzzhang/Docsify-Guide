安装ansible

```bash
yum -y install ansible
```

查看ansible版本

```
ansible --version
ansible 2.5.5
  config file = /etc/ansible/ansible.cfg
  configured module search path = ['/root/.ansible/plugins/modules', '/usr/share/ansible/plugins/modules']
  ansible python module location = /usr/lib/python3.7/site-packages/ansible
  executable location = /usr/bin/ansible
  python version = 3.7.9 (default, Jun 21 2021, 10:23:25) [GCC 7.3.0]
```

## ansible.cfg文件加载顺序

ansible.cfg文件作为配置文件，ansible会在多个路径下进行读取，读取的顺序如下：

- ANSIBLE_CONFIG：环境变量
- ansible.cfg：当前执行目录下
- .ansible.cfg：~/.ansible.cfg
- /etc/ansible/ansible.cfg

## 配置Ansible主机清单

