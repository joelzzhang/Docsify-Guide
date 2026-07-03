## 第一部分：Linux权限管理

### 一、Linux系统权限概述

Linux权限分为：

- **基本权限**：r、w、x
- **特殊权限**：SUID、SGID、SBIT
- **ACL权限**：访问控制列表
- **sudo提权**：权限委派
- **umask**：默认权限掩码

------

### 二、RWX基本权限

#### 1. 权限含义

| 权限             | 对文件的意义                   | 对目录的意义                                  |
| ---------------- | ------------------------------ | --------------------------------------------- |
| **r**（read）    | 可读取文件内容（如 cat、less） | 可列出目录内容（需配合 x，如 ls）             |
| **w**（write）   | 可编辑、修改文件内容           | 可在目录下创建、删除文件（即使文件属于 root） |
| **x**（execute） | 可执行文件（命令、脚本）       | 可进入目录（cd）                              |

目录最小有意义权限：`r-x`（可进入并查看内容）

#### 2. 权限匹配优先级

访问文件时，系统按以下顺序匹配：

1. **是否文件的拥有人（user）** → 使用 u 权限
2. **是否在文件的拥有组中（group）** → 使用 g 权限
3. **其他人（other）** → 使用 o 权限

一旦匹配成功，不再继续向下匹配。

#### 3. 常见权限示例与报错分析

| 操作           | 结果              | 原因                              |
| -------------- | ----------------- | --------------------------------- |
| `cd /root/`    | Permission denied | /root 默认 700，普通用户无 x 权限 |
| `touch /opt/a` | Permission denied | /opt 默认 755，普通用户无 w 权限  |
| `ls -l /opt/`  | 显示 ? 号         | 有 r 但无 x，无法读取文件属性     |

#### 4. 文件 vs 目录的 w 权限风险

- 目录有 **w 权限**时，即使文件属于 root，也可以被删除或重命名。
- 建议：共享目录使用 **SBIT** 防止他人删除自己的文件。

------

### 三、chmod – 修改权限

#### 1. 字符方式

| 对象 | 说明   |
| ---- | ------ |
| u    | 拥有人 |
| g    | 拥有组 |
| o    | 其他人 |
| a    | 所有人 |

| 操作符 | 说明     |
| ------ | -------- |
| +      | 增加权限 |
| -      | 删除权限 |
| =      | 覆盖权限 |

```bash
chmod u+x file          # 拥有人加执行
chmod o-w file          # 其他人去掉写
chmod u=rwx,g=rx,o=r file
chmod a+x file          # 所有人加执行
```

#### 2. 数字方式

| 数字 | 权限 |
| ---- | ---- |
| 4    | r--  |
| 2    | -w-  |
| 1    | --x  |

```bash
chmod 640 file   # 拥有人读写(4+2)，组读(4)，其他人无(0)
chmod 755 file   # rwxr-xr-x
chmod 777 file   # 所有人所有权限
```

拥有人即使没有 w 权限，仍可通过 `:wq!` 强制保存（仅限 root 或文件拥有人）。

------

### 四、chown – 修改拥有人/组

```bash
chown zhangsan file              # 改拥有人
chown :zhangsan file             # 改拥有组
chown zhangsan:zhangsan file     # 同时改
chgrp group file                 # 只改组
```
------

### 五、三大特殊权限

#### 1. SUID（Set User ID）

- **作用对象**：二进制可执行文件
- **效果**：任何人执行该文件时，以文件**拥有人**身份运行
- **典型示例**：`/bin/passwd`（普通用户可改密码，写入 `/etc/shadow`）

```bash
chmod u+s /bin/file
chmod 4755 /bin/file
```

❌ 不适合脚本、目录。

#### 2. SGID（Set Group ID）

- **作用于文件**：以文件**拥有组**身份执行
- **作用于目录**：目录下新创建的文件继承目录的组

```bash
chmod g+s dir
chmod 2755 dir
```

#### 3. SBIT（Sticky Bit）

- **作用对象**：目录
- **效果**：用户只能删除/重命名自己的文件
- **典型示例**：`/tmp`

```bash
chmod o+t dir
chmod 1755 dir
```

#### 查看特殊权限

```bash
ls -l /bin/passwd   # rwsr-xr-x
stat /bin/passwd    # Access: (4755)4代表有SUID权限
```

| 标识 | 含义         |
| ---- | ------------ |
| s    | 有 SUID + x  |
| S    | 有 SUID 无 x |
| t    | 有 SBIT + x  |
| T    | 有 SBIT 无 x |

------

### 六、ACL权限（访问控制列表）

#### 1. 为什么需要 ACL？

传统权限只能控制 u/g/o，无法为多个指定用户单独授权。

#### 2. 设置ACL

```bash
# 给用户 mengxin 设置读权限
setfacl -m u:mengxin:r-- /etc/shadow

# 给用户 zhangsan 设置写权限
setfacl -m u:zhangsan:-w- /etc/shadow

# 给用户 wangwu 设置读写权限
setfacl -m u:wangwu:rw- /etc/shadow

# 给组设置权限
setfacl -m g:zhangsan:rw- /etc/shadow
```

#### 3.查看ACL

```bash
ll /etc/shadow            # 权限位后会多一个 '+' 号
# ----------+ 1 root root ...

getfacl /etc/shadow  #获取ACL详细信息

#输出示例
# file: etc/shadow   #文件路径
# owner: root  拥有人
# group: root  拥有组
user::---      拥有人权限，如果冒号之间没有用户就是拥有人权限
user:mengxin:r--   用户ACL权限，有名字是指定用户ACL权限
group::---   拥有组权限
mask::r--     ACL权限掩码决定文件的有效权限
other::---    其他人权限
```

#### 4. 匹配优先级（有 ACL 时）

1. 用户 ACL 权限
2. 文件拥有人权限
3. 用户组 ACL 权限
4. 文件拥有组权限
5. 其他人权限

#### 5. ACL 的 mask 掩码（权限掩码）

- mask 决定 ACL 用户的**有效权限**
- 若 mask 为空，即使配置了 ACL 也无效
- `ls -l` 显示的组权限位置，实际上显示的是 mask 值（当文件有 ACL 时）
- 使用 `chmod g+rwx` 修改的是 **mask**，不是真正的拥有组权限

```bash
# 修改 mask
setfacl -m m::rwx /etc/shadow

# 修改真正的拥有组权限
setfacl -m g::rwx /etc/shadow
#冒号中间写了就是修改组的ACL 权限

setfacl -n -m m::rwx /etc/shadow
#-n不要自动重新计算 mask
```

注意：`chmod g+rwx` 修改的是 **mask**，不是拥有组权限。

`chmod g+rwx /etc/shadow` → 修改的其实是mask值，等价于`setfacl -m m::rwx /etc/shadow`

修改拥有组的权限：`setfacl -m g::rwx /etc/shadow` === 相当于原来的`chmod g=rwx /etc/shadow`

修改其他人的权限：`setfacl -m o::rwx /etc/shadow` 

修改拥有人的权限：`setfacl -m u::rwx /etc/shadow`

#### 6.删除ACL

```bash
setfacl -x u:mengxin /etc/shadow      # 删除指定用户的 ACL
setfacl -b /etc/shadow                # 删除所有 ACL
```

#### 7. 默认 ACL（继承）

需求：让 `/opt` 目录下**新创建**的文件/子目录自动继承 mengxin 的 `rwx` 权限。

```bash
setfacl -m d:u:mengxin:rwx /opt/
```

- 新文件/目录自动继承 ACL
- 对已有文件无影响，对目录本身无效
- 删除默认 ACL：`setfacl -k /opt`

#### 7. ACL 管理命令总结

| 命令                         | 作用         |
| ---------------------------- | ------------ |
| `setfacl -m u:user:rwx file` | 添加用户 ACL |
| `setfacl -x u:user file`     | 删除用户 ACL |
| `setfacl -b file`            | 清空所有 ACL |
| `getfacl file`               | 查看 ACL     |

------

### 七、sudo 提权（权限委派）

#### 1. 配置文件 `/etc/sudoers`

```bash
root ALL=(ALL) ALL 
%wheel ALL=(ALL) ALL   #组
```

格式：

```bash
用户 主机=(提权身份) 命令
```

`/etc/sudoers.d`目录下也能配置，按照个人习惯

```bash
touch /etc/sudoers.d/weihu
vim /etc/sudoers.d/weihu
用户 主机=(提权身份) 命令
```


#### 2. 示例

```bash
zhangsan ALL=(root) /usr/sbin/useradd
%lisi ALL=(ALL) NOPASSWD:ALL
```

#### 3. 别名定义

大写字母

| 别名类型    | 说明         |
| ----------- | ------------ |
| User_Alias  | 用户别名     |
| Host_Alias  | 主机别名     |
| Runas_Alias | 提权身份别名 |
| Cmnd_Alias  | 命令别名     |

示例：

```bash
User_Alias ADMINS = zhangsan, lisi
Host_Alias LABS = lab.example.com
Runas_Alias OP = root, wangwu
Cmnd_Alias TOOLS = /usr/bin/touch, /usr/sbin/useradd
ADMINS LABS=(OP) NOPASSWD:TOOLS
```

#### 4. 常用 sudo 选项

| 选项               | 说明                           |
| ------------------ | ------------------------------ |
| `sudo -u root cmd` | 以 root 执行                   |
| `sudo -k`          | 强制下次提权输入密码           |
| `sudo -l`          | 查看当前用户可执行的 sudo 命令 |

#### 5.sudo的弊端

cd命令不能执行

------

### 八、umask – 默认权限掩码

#### 1. 计算公式

- 文件默认权限 = 666 - umask
- 目录默认权限 = 777 - umask

#### 2. 示例

| umask | 文件权限          | 目录权限 |
| ----- | ----------------- | -------- |
| 022   | 644               | 755      |
| 223   | 444（自动去掉 x） | 554      |

普通文件永远不会有执行权限，若计算结果包含 x 则自动 +1。

#### 3. 查看与设置

```
umask          # 查看当前
umask 022      # 临时设置
```

#### 4. 永久设置

- 所有用户：`/etc/bashrc`、`/etc/profile`
- 指定用户：`~/.bashrc`、`~/.bash_profile`

------

## 第二部分：IO重定向与管道

### 一、标准输入输出

| 类型   | 编号 | 名称         | 默认设备 |
| ------ | ---- | ------------ | -------- |
| stdin  | 0    | 标准输入     | 键盘     |
| stdout | 1    | 标准正确输出 | 屏幕     |
| stderr | 2    | 标准错误输出 | 屏幕     |

### 二、输出重定向

| 符号   | 说明                     |
| ------ | ------------------------ |
| `>`    | 覆盖正确输出             |
| `>>`   | 追加正确输出             |
| `2>`   | 覆盖错误输出             |
| `2>>`  | 追加错误输出             |
| `&>`   | 全部输出                 |
| `2>&1` | 错误输出重定向到正确输出 |

```bash
ls /etc/passwd > ok.log
ls /etc/xxx 2> err.log
find / -name selinux &> all.log
ls /etc/xxx > /dev/null 2>&1
```

### 三、输入重定向

```bash
mail -s "test" user < file.txt
```

### 四、管道符 `|`

- 只能传递正确输出
- 将前一个命令的输出作为后一个命令的输入

```
ls -l | grep .conf
echo 1 | passwd --stdin devops
```

### 五、三通管道 `tee`

- 同时输出到屏幕和文件

```
ls -l | tee list.txt | grep .txt
```

### 六、特殊设备文件

| 设备        | 说明                   |
| ----------- | ---------------------- |
| `/dev/null` | 黑洞文件，丢弃所有输入 |
| `/dev/zero` | 无限输出 0 字符        |

```bash
dd if=/dev/zero of=/opt/swap bs=1M count=1024
```

------

## 第三部分：vim 编辑器高级特性

### 一、三大基本模式

| 模式     | 特征                             | 切换方式                                                     |
| -------- | -------------------------------- | ------------------------------------------------------------ |
| 命令模式 | 默认模式，可移动光标、删除、复制 | 打开文件时                                                   |
| 编辑模式 | 可编辑内容                       | 按 i（光标处）、a（光标下一行）、o（光标后一个字符）、<br>I（光标所在行首）、A（光标行尾）、O（光标上一行） |
| 末行模式 | 保存、退出、替换                 | 按 `:`                                                       |

编辑模式 ↔ 末行模式 必须经过命令模式（按 ESC）

### 二、命令模式常用操作

| 操作                 | 快捷键                                   |
| -------------------- | ---------------------------------------- |
| 光标移动             | h/j/k/l 或方向键                         |
| 翻页                 | ctrl+f（下）、ctrl+b（上）               |
| 跳转行               | 10G(指定行)、G（末尾）、gg（开头）       |
| 行首/行尾            | `^` / `$`                                |
| 复制行               | yy，5yy(复制5行)                         |
| 粘贴                 | p（粘贴到下一行），P（粘贴到上一行）     |
| 删除行               | dd,5dd(删除5行)                          |
| 删除光标所在行到末尾 | dG                                       |
| 撤销                 | u                                        |
| 反撤销               | ctrl+r                                   |
| 查找                 | /关键字（n/N 下上），?关键字（n/N 上下） |
| 加序号               | set nu                                   |

### 三、末行模式常用命令

| 命令            | 说明             |
| --------------- | ---------------- |
| `:wq`           | 保存退出         |
| `:w`            | 保存             |
| `:q!`           | 强制退出         |
| `:w /path`      | 另存为           |
| `:set number`   | 显示行号         |
| `:set paste`    | 粘贴模式         |
| `:s/old/new`    | 替换当前行第一个 |
| `:%s/old/new/g` | 全局替换         |

遇到特殊字符不能替换加反斜杠`\`

### 四、可视化模式（ctrl+v）

删除 X

- 批量注释：

1. `ctrl+v` 选择列
2. 按字母j/k或方向键选中需注释的行
3. `I` 进入编辑
4. 输入 `#`
5. 按 `ESC`

- 批量取消注释

1. 按ctrl + v进入 visual block模式
2. 按小写字母L横向选中列的个数，例如 // 需要选中2列
3. 按字母j/k或方向键选中注释的行
4. 按d键或x键就可全部取消注释

### 五、多窗口模式

| 命令            | 说明     |
| --------------- | -------- |
| `:sp file`      | 水平分屏 |
| `:vsp file`     | 垂直分屏 |
| `ctrl+w + 方向` | 切换窗口 |

### 六、常见问题

| 现象                 | 原因                                   | 解决             |
| -------------------- | -------------------------------------- | ---------------- |
| `.swp` 文件提示      | 文件被占用或异常退出(防止多人同时修改) | 删除 `.swp` 文件 |
| 按 `q:` 进入历史记录 | 错误操作                               | 输入 `:q` 退出   |
