## Java环境配置

### 安装包获取

下载链接：https://download.oracle.com/otn/java/jdk/8u441-b07/7ed26d28139143f38c58992680c214a5/jdk-8u441-linux-x64.tar.gz

### 解压安装包

```shell
tar -zxvf jdk-8u441-linux-x64.tar.gz -C /usr/local/java
```

### 配置环境变量

编辑`/etc/profile`文件

```shell
vi /etc/profile
```

添加如下内容：

```ini
JAVA_HOME=/usr/local/java/jdk1.8.0_441
CLASSPATH=.;%JAVA_HOME%/lib;%JAVA_HOME%/lib/tools.jar  
PATH=$PATH:$JAVA_HOME/bin:$%JAVA_HOME%/jre/bin
export PATH JAVA_HOME CLASSPATH
```

### 刷新环境变量

```shell
source /etc/profile
```

### 验证

```shell
java -version
```

## Maven环境配置

