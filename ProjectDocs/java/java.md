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
#windows环境变量
CLASSPATH=.;%JAVA_HOME%/lib;%JAVA_HOME%/lib/tools.jar
#Linux环境变量
CLASSPATH=.:$JAVA_HOME/lib:$JAVA_HOME/lib/tools.jar
PATH=$PATH:$JAVA_HOME/bin:$JAVA_HOME/jre/bin
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

## Java生成 SSL 证书

keytool为java原生自带，安装java后不需要再进行安装，作为密钥和证书管理工具，方便用户能够管理自己的公钥/私钥及证书，用于认证服务。

- -certreq：生成证书请求
- -changealias：更改条目的别名
- -delete：删除条目
- -exportcert：导出证书
- -genkeypair：生成密钥对
- -genseckey：生成密钥
- -gencert：根据证书请求生成证书
- -importcert：导入证书或证书链
- -importpass：导入口令
- -importkeystore：从其他密钥库导入一个或所有条目
- -keypasswd：更改条目的密钥口令
- -list：列出密钥库中的条目
- -printcert：打印证书内容
- -printcertreq：打印证书请求的内容
- -printcrl：打印 CRL 文件的内容
- -storepasswd：更改密钥库的存储口令

### -genkeypair

生成密钥对/创建数字证书，可用选项：

```ini
-alias <alias>                  要处理的条目的别名
-keyalg <keyalg>                密钥算法名称
-keysize <keysize>              密钥位大小
-sigalg <sigalg>                签名算法名称
-destalias <destalias>          目标别名
-dname <dname>                  唯一判别名
-startdate <startdate>          证书有效期开始日期/时间
-ext <value>                    X.509 扩展
-validity <valDays>             有效天数
-keypass <arg>                  密钥口令
-keystore <keystore>            密钥库名称
-storepass <arg>                密钥库口令
-storetype <storetype>          密钥库类型
-providername <providername>    提供方名称
-providerclass <providerclass>  提供方类名
-providerarg <arg>              提供方参数
-providerpath <pathlist>        提供方类路径
-v                              详细输出
-protected                      通过受保护的机制的口令
KeyTool工具支持RSA和DSA两种算法，且DSA算法为默认算法。
```

示例：

```shell
keytool -genkeypair -keyalg RSA -keysize 2048 -sigalg SHA256withRSA -validity 36000 -alias acton -keystore acton.keystore -dname "CN=acton, OU=acton, O=acton, L=BJ, ST=BJ, C=CN" -storepass 123456 -keypass 123456
```

- keyalg：密钥算法为RSA
- keysize：密钥长度为2048，默认为1024
- sigalg：数字签名算法为SHA256withRSA
- validity：证书有效期为36000天
- -alias：别名为acton
- keystore：密钥库存储位置acton.keystore
- dname：指定用户信息
  - CN：姓名
  - OU：组织单位名
  - O：组织名
  - L：城市或区域名
  - ST：州或省份名
  - C：国家代码

- storepass：密钥库密码123456
- 如果创建默认类型(JKS)的密钥库，则可使用"-keypass"参数指定条目的密钥口令，如果没有指定则会在最后一步提示"输入该条目的密钥口令，(如果与密钥库口令相同按回车)"，一般设为与密钥库口令相同。如果创建 PKCS12 类型的密钥库，则会忽略条目的密钥口令参数，因为 PKCS12 不支持设置密钥库条目密钥口令，默认它与密钥库密码一致。

此时已经生成了一个没有经过认证的数字证书，和一个JKS格式的密钥库。

JKS为Java专用格式，可以使用如下命令转换为标准格式PKCS12

```shell
keytool -importkeystore -srckeystore acton.keystore -destkeystore acton.keystore -deststoretype pkcs12 -destkeypass 111111 -deststorepass 111111
```

> [!TIP|style:flat|label:keypass 与 storepass的区别]
>
> 在 Java 中，keypass 和 storepass 是用于保护密钥库（keystore）的两个密码：
>
> - **keypass (密钥密码)** ：用于保护密钥库中存储的 **单个密钥** 的密码。它用来加密和解密每个密钥。
> - **storepass (存储库密码)** ：用于保护整个 **密钥库文件** 的密码。它用来加密和解密整个密钥库文件，并保护其内容不被未授权访问。

### -list

列出密钥库中的条目，可用选项：

```ini
 -rfc                            以 RFC 样式输出
 -alias <alias>                  要处理的条目的别名
 -keystore <keystore>            密钥库名称
 -storepass <arg>                密钥库口令
 -storetype <storetype>          密钥库类型
 -providername <providername>    提供方名称
 -providerclass <providerclass>  提供方类名
 -providerarg <arg>              提供方参数
 -providerpath <pathlist>        提供方类路径
 -v                              详细输出
 -protected                      通过受保护的机制的口令
```

示例：查看所有条目

```shell
keytool -list -keystore acton.keystore -storepass 123456
```

- 密钥库类型: jks

- 密钥库提供方: SUN

- 您的密钥库包含 1 个条目

  > acton, 2023-11-27, PrivateKeyEntry,
  > 证书指纹 (SHA1): 03:CD:A0:1C:1F:E2:50:04:1B:C8:D4:9F:35:97:0D:20:D6:E3:21:90

示例：查看指定别名

```shell
keytool -list -keystore acton.keystore -storepass 123456 -alias acton
```

> acton, 2023-11-27, PrivateKeyEntry,
> 证书指纹 (SHA1): 03:CD:A0:1C:1F:E2:50:04:1B:C8:D4:9F:35:97:0D:20:D6:E3:21:90


示例：以RFC样式输出

```shell
keytool -list -keystore acton.keystore -storepass 123456 -alias acton -rfc
```

> 别名: acton
> 创建日期: 2023-11-27
> 条目类型: PrivateKeyEntry
> 证书链长度: 1
> 证书[1]:
> -----BEGIN CERTIFICATE-----
> MIIDTzCCAjegAwIBAgIEOLT4rDANBgkqhkiG9w0BAQUFADBXMQswCQYDVQQGEwJD
> TjELMAkGA1UECBMCQkoxCzAJBgNVBAcTAkJKMQ4wDAYDVQQKEwVhY3RvbjEOMAwG
> A1UECxMFYWN0b24xDjAMBgNVBAMTBWFjdG9uMCAXDTIzMTEyNzA4NTMzN1oYDzIx
> MjIwNjIxMDg1MzM3WjBXMQswCQYDVQQGEwJDTjELMAkGA1UECBMCQkoxCzAJBgNV
> BAcTAkJKMQ4wDAYDVQQKEwVhY3RvbjEOMAwGA1UECxMFYWN0b24xDjAMBgNVBAMT
> BWFjdG9uMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAk4AyvuJa5Kjn
> FMnnOX1Um3m5V9N1kCorETOMEigsym2wamyqrw5cLeaT5al8IS18Qyczu69r0W/e
> pW+e5Fsg7T8UsjfQwxt1b+A+E78bHQuPXhC6AznkS/MT5zT50twMseSf+RwuhrlH
> 0YjKZxsERuIa09h2IoacnNkrAJf/Uh6PKl1otIoMKpE1uq9czo/q+UgJr0ruvajV
> 9Z4pdvMH04rMcYtEnhHgOj5q9F4XWKHPltx5DRcEdv2dNVmBNDaMOtkRrkj2L0IM
> IwyiknqhNoz2JWUVrmButg3xesvK+U1jAoYA1I5p57OJuCkvGsrPLJs5sJO55F6z
> M4R8nn1j4wIDAQABoyEwHzAdBgNVHQ4EFgQUdbb+w+9kBVu9Wz6RZghPJL6LN80w
> DQYJKoZIhvcNAQEFBQADggEBAIqbMLrOgWOOmPpLEE2jDjcBCLc1LTkCCEdmarUo
> 2Y+Fk7B3zseN1YRsWxpHx5V5UVmcdncfDQY0WRz+S7dBkIH9TyDTNVCkqKppZsLl
> ZuIavsbZXHWr6GZb3FB8fhj7GhaqZ/HSh0qNL1RUInsk7CIzpGBXzT0MkSr0u1sF
> SYeygMwESho8TZM62Q4JOwy3dAKYvEWJWIfjnf1TTnQoIF+W70P2zKwcqPSR2V8T
> XCDmF8iOgc7gzOBPmZqTxNg6MBoZ2TZYBpXyf4hF9IYDQTIbqKS3APdiaHgDYw6o
> hts2aYmDbLtwdqm2nCg69OASbJBVxUM10ZuhC5NkRwPU1w0=
> -----END CERTIFICATE-----

### -storepasswd

更改密钥库的存储口令，可用选项：

```ini
-new <arg>                      新口令
-keystore <keystore>            密钥库名称
-storepass <arg>                密钥库口令
-storetype <storetype>          密钥库类型
-providername <providername>    提供方名称
-providerclass <providerclass>  提供方类名
-providerarg <arg>              提供方参数
-providerpath <pathlist>        提供方类路径
-v                              详细输出
```

示例：修改密钥库密码

```shell
keytool -storepasswd -new 111111 -keystore acton.keystore -storepass 123456
```

> 注意：密钥至少为6位

### -changealias

更改条目的别名，可用项目：

```ini
-alias <alias>                  要处理的条目的别名
-destalias <destalias>          目标别名
-keypass <arg>                  密钥口令
-keystore <keystore>            密钥库名称
-storepass <arg>                密钥库口令
-storetype <storetype>          密钥库类型
-providername <providername>    提供方名称
-providerclass <providerclass>  提供方类名
-providerarg <arg>              提供方参数
-providerpath <pathlist>        提供方类路径
-v                              详细输出
-protected                      通过受保护的机制的口令
```

示例：修改acton为newacton

```shell
keytool -changealias -alias acton -destalias newacton -keystore acton.keystore -storepass 123456
```

### -delete

删除条目，可用选项：

```ini
-alias <alias>                  要处理的条目的别名
-keystore <keystore>            密钥库名称
-storepass <arg>                密钥库口令
-storetype <storetype>          密钥库类型
-providername <providername>    提供方名称
-providerclass <providerclass>  提供方类名
-providerarg <arg>              提供方参数
-providerpath <pathlist>        提供方类路径
-v                              详细输出
-protected                      通过受保护的机制的口令
```

示例：删除acton条目

```shell
keytool -delete -alias acton -keystore acton.keystore -storepass 123456
```

### -exportcert

导出证书，可用选项：

```ini
-rfc                            以 RFC 样式输出
-alias <alias>                  要处理的条目的别名
-file <filename>                输出文件名
-keystore <keystore>            密钥库名称
-storepass <arg>                密钥库口令
-storetype <storetype>          密钥库类型
-providername <providername>    提供方名称
-providerclass <providerclass>  提供方类名
-providerarg <arg>              提供方参数
-providerpath <pathlist>        提供方类路径
-v                              详细输出
-protected                      通过受保护的机制的口令
```

示例：

```shell
keytool -exportcert -alias acton -keystore acton.keystore -storepass 123456 -file acton.cer -rfc
```

- alias：指定别名acton
- keystore：指定密钥库acton.keystore
- storepass：指定密钥库密码
- file：指定输出的证书文件acton.cer
- rfc：指定以Base64编码格式输出

### -printcert

打印证书内容，可用选项：

```ini
-rfc                        以 RFC 样式输出
-file <filename>            输入文件名
-sslserver <server[:port]>  SSL 服务器主机和端口
-jarfile <filename>         已签名的 jar 文件
-v                          详细输出
```

示例：

```shell
keytool -printcert -file acton.cer
```

> 所有者: CN=acton, OU=acton, O=acton, L=BJ, ST=BJ, C=CN
> 发布者: CN=acton, OU=acton, O=acton, L=BJ, ST=BJ, C=CN
> 序列号: 28ab6921
> 有效期为 Mon Nov 27 17:22:38 CST 2023 至 Sun Jun 21 17:22:38 CST 2122
> 证书指纹:
> 	 MD5:  20:DC:B9:57:65:B1:77:FE:07:33:D6:7B:BE:E5:4A:AC
> 	 SHA1: 00:1A:D4:2A:A9:F0:56:D7:33:41:4D:05:BA:8A:6B:7E:E4:E7:7D:12
> 	 SHA256: 38:0F:24:D3:FA:E4:49:D6:D2:B8:E7:84:ED:4A:86:D2:93:4E:9E:5D:56:EA:6F:9F:C3:E9:85:3A:14:F9:E2:AE
> 签名算法名称: SHA1withRSA
> 主体公共密钥算法: 2048 位 RSA 密钥
> 版本: 3
>
> 扩展:
>
> #1: ObjectId: 2.5.29.14 Criticality=false
> SubjectKeyIdentifier [
> KeyIdentifier [
> 0000: 07 F6 FF 44 6D CB 88 E1   64 5C BD 09 FB 3D 83 31  ...Dm...d\...=.1
> 0010: B0 63 5B D5                                        .c[.
> ]
> ]

示例：Base64编码打印

```shell
keytool -printcert -file acton.cer -rfc
```

> -----BEGIN CERTIFICATE-----
> MIIDTzCCAjegAwIBAgIEKKtpITANBgkqhkiG9w0BAQUFADBXMQswCQYDVQQGEwJD
> TjELMAkGA1UECBMCQkoxCzAJBgNVBAcTAkJKMQ4wDAYDVQQKEwVhY3RvbjEOMAwG
> A1UECxMFYWN0b24xDjAMBgNVBAMTBWFjdG9uMCAXDTIzMTEyNzA5MjIzOFoYDzIx
> MjIwNjIxMDkyMjM4WjBXMQswCQYDVQQGEwJDTjELMAkGA1UECBMCQkoxCzAJBgNV
> BAcTAkJKMQ4wDAYDVQQKEwVhY3RvbjEOMAwGA1UECxMFYWN0b24xDjAMBgNVBAMT
> BWFjdG9uMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAr//MAh/T/i6L
> 7zDE9qi33zy0e06Se/c+17xFrTbRSTqQaO9xu57ht7lSgV0DnnrbwLnApKevHttj
> mSOAYOo1hhQwwHNCwd07GtU+x4T0LMwReJH78xlQGegMA5ffhDMR0SF47/oygPsy
> HUKNh6Ynw/5n+LAwU5LYm0eiE4GNj25T/E4hy9TNqMZI8jj3L3WUAgRXhn3aXlhs
> GQxVFxac0QoVhuNXGac7q9kTe7CvUzWU7RGf9Mg/CbDvn0MuUbk67Hw1VSEbLcC6
> 1BTV7p1xpfJc2vHnRfrLM96/U0XTiJM2V4MGxP7Qe+JDWos6Mnxtm+kUOWb+ZaXh
> g385SHNvnwIDAQABoyEwHzAdBgNVHQ4EFgQUB/b/RG3LiOFkXL0J+z2DMbBjW9Uw
> DQYJKoZIhvcNAQEFBQADggEBAGsaAW70ru1tSnEN7g6mbRvtsWXdUNz2z90DdOIS
> Vritufz3xlgKWWKMUNwTAjooSFaj3go9bCDhULd49+Y6mrkhcVzgkOx7q67nFl44
> B2mgXvOjzBQ8zhzwzZDNfGhwVShUm9nNNE0J4ucqbV9a600ce3nF2SD8jICbJ5mW
> x2437+j0ki9uhPPm7ryl7v8r/RAX4rXdcy6oqS/UqH+1FMU0qbHzFO7ZB9DVn0vJ
> p5RnatcUqC+s9dKvkP3orShmrpx8aoGWfjdkR1w9C8Rz9D9gVRYN46X655DzkClh
> 5j5XuMzZVwcIUazC83LRbldee4U90vFUdVOGccoGbzcpWCw=
> -----END CERTIFICATE-----

### -certreq

生成证书请求，可用选项：

```ini
-alias <alias>                  要处理的条目的别名
-sigalg <sigalg>                签名算法名称
-file <filename>                输出文件名
-keypass <arg>                  密钥口令
-keystore <keystore>            密钥库名称
-dname <dname>                  唯一判别名
-storepass <arg>                密钥库口令
-storetype <storetype>          密钥库类型
-providername <providername>    提供方名称
-providerclass <providerclass>  提供方类名
-providerarg <arg>              提供方参数
-providerpath <pathlist>        提供方类路径
-v                              详细输出
-protected                      通过受保护的机制的口令
```

示例：

```shell
keytool -certreq -alias acton -keystore acton.keystore -storepass 123456 -file acton.csr -v
```

执行上述命令后，将得到一个PKCS#10编码格式的数字证书签发申请文件acton.csr。

### -printcertreq

打印证书请求的内容，可用选项：

```ini
-file <filename>  输入文件名
-v                详细输出
```

示例：

```shell
keytool -printcertreq -file acton.csr -v
```

> PKCS #10 证书请求 (版本 1.0)
> 主体: CN=acton, OU=acton, O=acton, L=BJ, ST=BJ, C=CN
> 格式: X.509
> 公共密钥: 2048 位 RSA 密钥
> 签名算法: SHA256withRSA
>
> 扩展请求:
>
> #1: ObjectId: 2.5.29.14 Criticality=false
> SubjectKeyIdentifier [
> KeyIdentifier [
> 0000: 07 F6 FF 44 6D CB 88 E1   64 5C BD 09 FB 3D 83 31  ...Dm...d\...=.1
> 0010: B0 63 5B D5                                        .c[.
> ]
> ]

后续可以提交CSR文件内容给CA机构，获得相应的签发数字证书。

### -gencert

根据证书请求生成证书，可用选项：

```ini
-rfc                            以 RFC 样式输出
-infile <filename>              输入文件名
-outfile <filename>             输出文件名
-alias <alias>                  要处理的条目的别名
-sigalg <sigalg>                签名算法名称
-dname <dname>                  唯一判别名
-startdate <startdate>          证书有效期开始日期/时间
-ext <value>                    X.509 扩展
-validity <valDays>             有效天数
-keypass <arg>                  密钥口令
-keystore <keystore>            密钥库名称
-storepass <arg>                密钥库口令
-storetype <storetype>          密钥库类型
-providername <providername>    提供方名称
-providerclass <providerclass>  提供方类名
-providerarg <arg>              提供方参数
-providerpath <pathlist>        提供方类路径
-v                              详细输出
-protected                      通过受保护的机制的口令
```

示例：正常的CA签发证书需要收费，所以我们只能用acton.keystore密钥库中的acton的私钥来签发acton.csr，自己给自己签发证书

```shell
keytool -gencert -infile acton.csr -outfile acton_sign.cer -alias acton -keystore acton.keystore -storepass 123456
```

生成了签发完毕的证书文件acton_sign.cer。

### -importcert

导入证书或证书链，可用选项：

```ini
-noprompt                       不提示
-trustcacerts                   信任来自 cacerts 的证书
-protected                      通过受保护的机制的口令
-alias <alias>                  要处理的条目的别名
-file <filename>                输入文件名
-keypass <arg>                  密钥口令
-keystore <keystore>            密钥库名称
-storepass <arg>                密钥库口令
-storetype <storetype>          密钥库类型
-providername <providername>    提供方名称
-providerclass <providerclass>  提供方类名
-providerarg <arg>              提供方参数
-providerpath <pathlist>        提供方类路径
-v                              详细输出
```

示例：将自己签发完毕的acton_sign.cer导入到密钥库

```shell
keytool -importcert -trustcacerts -alias acton_sign -file acton_sign.cer -keystore acton.keystore -storepass 123456
```

> 所有者: CN=acton, OU=acton, O=acton, L=BJ, ST=BJ, C=CN
> 发布者: CN=acton, OU=acton, O=acton, L=BJ, ST=BJ, C=CN
> 序列号: 342dcb68
> 有效期为 Mon Nov 27 19:51:00 CST 2023 至 Sun Feb 25 19:51:00 CST 2024
> 证书指纹:
> 	 MD5:  FF:A5:4B:71:FD:3B:E2:CC:F3:51:CD:FE:08:A9:3B:D4
> 	 SHA1: 21:2B:9F:12:14:75:0E:A8:EA:CB:C8:C9:F6:88:B7:45:D9:3D:CD:24
> 	 SHA256: B4:53:E6:DD:B4:6E:3D:2B:28:26:66:8B:4F:60:B0:FB:D2:27:90:7E:EC:7A:C5:FB:1E:06:13:7C:2F:23:7F:18
> 签名算法名称: SHA256withRSA
> 主体公共密钥算法: 2048 位 RSA 密钥
> 版本: 3
>
> 扩展:
>
> #1: ObjectId: 2.5.29.14 Criticality=false
> SubjectKeyIdentifier [
> KeyIdentifier [
> 0000: 26 D3 0B CF F3 C5 E7 A0   60 39 F1 C9 8C C5 73 C9  &.......`9....s.
> 0010: EC 66 5A 36                                        .fZ6
> ]
> ]
>
> 是否信任此证书? [否]:  y
> 证书已添加到密钥库中
> AI写代码


示例：查看密钥库内容

```shell
keytool -list -keystore acton.keystore -storepass 123456
```

> 密钥库类型: jks
>
> 密钥库提供方: SUN
>
> 您的密钥库包含 2 个条目
>
> acton_sign, 2023-11-27, trustedCertEntry,
> 证书指纹 (SHA1): 21:2B:9F:12:14:75:0E:A8:EA:CB:C8:C9:F6:88:B7:45:D9:3D:CD:24
> acton, 2023-11-27, PrivateKeyEntry,
> 证书指纹 (SHA1): 86:43:64:83:AC:3A:AE:F1:9D:BB:CE:E5:C1:07:8C:A5:2A:F0:4E:3E

## Maven环境配置

