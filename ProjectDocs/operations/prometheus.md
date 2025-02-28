## 介绍

> Prometheus 是由 SoundCloud开源的系统监控报警工具和时间序列数据库(TSDB)。基于Go语言开发，专为云原生环境和大规模分布式系统设计。Prometheus的基本原理是通过HTTP协议周期性抓取被监控组件的状态，任意组件只要提供对应的HTTP接口就可以接入监控，不需要任何SDK或者其他的集成过程。这样做非常适合做虚拟化环境监控系统，比如VM、Docker、Kubernetes等。输出被监控组件信息的HTTP接口被叫做exporter 。目前互联网公司常用的组件大部分都有exporter可以直接使用，比如Varnish、Haproxy、Nginx、MySQL、Linux系统信息(包括磁盘、内存、CPU、网络等等)。

**其核心特点包括：**

- **高效的数据抓取机制**：Prometheus 通过拉取（pull）模式定期从目标应用收集指标数据。支持PushGateway采集瞬时任务的数据
- **支持多维数据模型**：由度量名和键值对组成的时间序列数据
- **时序数据库**：内置时间序列数据库TSDB，用于存储来自不同来源的时序数据（如 CPU、内存使用率等），支持高效查询和聚合
- **灵活的查询语言 PromQL（Prometheus Query Language）**：提供强大的查询功能，支持复杂的数据聚合、计算和分析
- **集成告警系统**：可以基于设定的规则触发报警，并通过多种渠道（如邮件、Slack、钉钉等）通知相关人员
- **可扩展性和丰富的生态**：多种可视化和仪表盘，支持第三方Dashboard，比如Grafana集成，进行高效的可视化分析
- **监控目标发现**：支持服务发现和静态配置两种方式发现目标

**Prometheus的存在的局限性:**

- **更多地展示的是趋势性的监控**：Prometheus作为一个基于度量的系统，不适合存储事件或者日志等，它更多地展示的是趋势性的监控。如果用户需要数据的精准性（不足），可以考虑ELK或其他日志架构。另外，APM更适用于链路追踪的场景。

- **Prometheus本地不适合存储大量历史数据存储**：Prometheus认为只有最近的监控数据才有查询的需要，所有Prometheus本地存储的设计初衷只是保存短期（如一个月）的数据，不会针对大量的历史数据进行存储。如果需要历史数据，则建议：使用Prometheus的远端存储，如：OpenTSDB、M3DB等。

- **成熟度没有 InfluxDB高**：Prometheus在集群上不论是采用联邦集群还是采用Improbable开源的Thanos等方案，都没有InfluxDB成熟度高，需要解决很多细节上的技术问题（如耗尽CPU、消耗机器资源等问题），部分互联网公司拥有海量业务，出于集群的原因会考虑对单机免费但是集群收费的InfluxDB进行自主研发。

## 工作原理

### 系统架构概述

![prometheus](../images/operations/prometheus-architecture.gif) 

### 组件概述

#### Prometheus Server

Prometheus 服务器是基于指标的监控系统的大脑。服务器的主要工作是使用拉模型从各个目标收集指标。目标只不过是服务器、pod、端点等，使用 Prometheus 从目标收集指标的通用术语称为抓取。Prometheus服务端以一个进程方式启动，如果不考虑参数和后台运行的话，只需要解压安装包之后运行 ./prometheus脚本即可启动，程序默认监听在9090端口。每次采集到的数据叫做metrics。这些采集到的数据会先存放在内存中，然后定期再写入硬盘，如果服务重新启动的话会将硬盘数据写回到内存中，所以对内存有一定消耗。Prometheus不需要重视历史数据，所以默认只会保留15天的数据。 Prometheus Server配置示例：

```yml
global:
  scrape_interval: 15s 
  evaluation_interval: 15s 
  scrape_timeout: 10s 

rule_files:
  - "rules/*.rules"

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090'] 
  - job_name: 'node-exporter'
    static_configs:
      - targets: ['node-exporter:9100'] 

alerting:
  alertmanagers:
    - static_configs:
        - targets: ['alertmanager:9093']
```

#### Service Discovery

> Prometheus 使用两种方法从目标中获取指标

- 静态配置：当目标具有静态 IP 或 DNS 端点时，我们可以使用这些端点作为目标。
- 服务发现：在大多数自动伸缩系统和 Kubernetes 等分布式系统中，目标不会有静态端点。在这种情况下，使用 prometheus 服务发现来发现目标端点，并且目标会自动添加到 prometheus 配置中。

#### Time-Series Database (TSDB)

> Prometheus 接收到的指标数据随着时间的推移而变化（CPU、内存、网络 IO 等）。它被称为时间序列数据。因此 Prometheus 使用时间序列数据库（TSDB）来存储其所有数据。默认情况下，Prometheus 以高效的格式（块）将其所有数据存储在本地磁盘中。随着时间的推移，它会压缩所有旧数据以节省空间。它还具有删除旧数据的保留策略。TSDB 具有内置的机制来管理长期保存的数据。您可以选择以下任意数据保留策略。

- 基于时间的保留：数据将保留指定的天数。默认保留期为 15 天。
- 基于大小的保留：您可以指定 TSDB 可以容纳的最大数据量。一旦达到这个限制，普罗米修斯将释放空间来容纳新数据。

Prometheus 还提供远程存储选项。这主要是存储可扩展性、长期存储、备份和灾难恢复等所需要的。

#### Prometheus Exporters

#### Prometheus Service Discovery

#### Prometheus Pushgateway

#### Prometheus Alert Manager

#### PromQL







## 部署安装



## 集群与高可用部署

## 服务发现

## Exporter采集组件

## PromQL查询语言

## 告警通知配置
