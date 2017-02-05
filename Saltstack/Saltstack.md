#Saltstack

提供python REST API

##三大功能：
>
- 远程执行
- 配置管理（状态）
- 云管理

##四种运行方式
>
- Local
- Minion/Master C/S模式
- Syndic  与zabbix_proxy类似
- Salt SSH

##典型案例
<pre>
#执行之前最好测试，并且确认执行的代码是需要的解决
salt 'saltmini' state.highstate test=True
</pre>
1. 远程执行 salt '*' cmd.run 'uptime'
2. State 要写一个文件，格式:YAML  后缀:.sls

##YAML:三板斧
1. 缩进   2个空格，不能使用Tab。
2. 冒号
3. 短横线

##saltsctck快速入门--执行
<pre>
#mini端收到的文件
/var/cache/salt
</pre>

<pre>
#不使用top文件时，叫做普通执行
salt '*' state.sls web.apache
#使用top文件时，叫做高级状态(top文件中记录了对应关系)
salt '*' state.highstate
</pre>

注意：
> 
- 生产环境不推荐使用'*'
- 执行前要进行测试
`salt 'saltmini' state.highstate test=True`

##ZeroMQ
我们进行自动化运维大多数情况下，是我们的服务器数量已经远远超过人工SSH维护的范围，SaltStack可以支数以千计，甚至更多的服务器。这些性能的提供主要来自于ZeroMQ，因为SaltStack底层是基于ZeroMQ进行高效的网络通信。ZMQ用于node与node间的通信，node可以是主机也可以是进程。

ZeroMQ（我们通常还会用ØMQ , 0MQ, zmq等来表示）是一个简单好用的传输层，像框架一样的一个套接字库，他使得Socket编程更加简单、简洁和性能更高。它还是一个消息处理队列库，可在多个线程、内核和主机盒之间弹性伸缩。
发布与订阅
ZeroMQ支持Publish/Subscribe，即发布与订阅模式，我们经常简称Pub/Sub。

![ZeroMQ](https://www.unixhot.com/uploads/article/20151027/055f24981e25860e08942d7f0aa9d0ab.png)

<pre>
[root@m01 /srv/salt]# lsof -i:4505 -n
COMMAND    PID USER   FD   TYPE DEVICE SIZE/OFF NODE NAME
salt-mast 7377 root   12u  IPv4  43267      0t0  TCP 172.16.1.61:4505 (LISTEN)
salt-mast 7377 root   14u  IPv4  45066      0t0  TCP 172.16.1.61:4505->172.16.1.9:46228 (ESTABLISHED)
salt-mast 7377 root   15u  IPv4  45579      0t0  TCP 172.16.1.61:4505->172.16.1.11:12699 (ESTABLISHED)
</pre>
**所有minion都连接着master的4505端口，4505用于发送的**
<pre>
[root@m01 /srv/salt]# lsof -i:4506 -n
COMMAND    PID USER   FD   TYPE DEVICE SIZE/OFF NODE NAME
salt-mast 7397 root   20u  IPv4  43296      0t0  TCP 172.16.1.61:4506 (LISTEN)
salt-mast 7397 root   22u  IPv4  43299      0t0  TCP 172.16.1.61:4506->172.16.1.11:64768 (ESTABLISHED)
salt-mast 7397 root   23u  IPv4  43300      0t0  TCP 172.16.1.61:4506->172.16.1.9:49817 (ESTABLISHED)
</pre>
**4506端口用于接收包**

###可以通过安装python-setproctitle
<pre>
#安装包：
yum install python-setproctitle
#查看进程，可以显示名称(重启salt-master进程)
[root@m01 /srv/salt]# ps aux|grep salt
root       9565  0.6  4.4 291120 21724 ?        S    18:20   0:00 /usr/bin/python2.6 /usr/bin/salt-master -d ProcessManager
root       9566  9.6  5.4 393828 26420 ?        Sl   18:20   0:00 /usr/bin/python2.6 /usr/bin/salt-master -d Maintenance
root       9567  0.0  4.5 377144 22176 ?        Sl   18:20   0:00 /usr/bin/python2.6 /usr/bin/salt-master -d Publisher
root       9568  0.0  4.6 377144 22424 ?        Sl   18:20   0:00 /usr/bin/python2.6 /usr/bin/salt-master -d EventPublisher
root       9573  0.6  4.4 291120 21460 ?        S    18:20   0:00 /usr/bin/python2.6 /usr/bin/salt-master -d ReqServer_ProcessManager
root       9574  9.6  4.8 464828 23600 ?        Sl   18:20   0:00 /usr/bin/python2.6 /usr/bin/salt-master -d MWorker
root       9577 10.0  4.8 464828 23600 ?        Sl   18:20   0:00 /usr/bin/python2.6 /usr/bin/salt-master -d MWorker
root       9578 10.0  4.8 464832 23608 ?        Sl   18:20   0:00 /usr/bin/python2.6 /usr/bin/salt-master -d MWorker
root       9579  9.6  4.8 464832 23604 ?        Sl   18:20   0:00 /usr/bin/python2.6 /usr/bin/salt-master -d MWorker
root       9584  9.3  4.8 464836 23612 ?        Sl   18:20   0:00 /usr/bin/python2.6 /usr/bin/salt-master -d MWorker
root       9585  0.0  4.5 614728 22288 ?        Sl   18:20   0:00 /usr/bin/python2.6 /usr/bin/salt-master -d MWorkerQueue
root       9645  0.0  4.4 464836 21860 ?        R    18:20   0:00 /usr/bin/python2.6 /usr/bin/salt-master -d MWorker
</pre>

##SaltStack数据系统
为其他数据功能提供数据支持的
- Grains  (谷粒)
- Pillar  (柱子)

###Grains
静态数据，Minion启动的时候收集的Minion本地的相关信息。
> 操作系统版本，内核版本，CPU，内存，硬盘。设备型号。序列号。
> 
> 只收集一次(除非重启)

用途：

1. 资产管理。信息查询。
2. 用于目标选择。
3. 在配置管理中使用。

####目标选择
<pre>
#目标选择
salt -G 'roles:apache' cmd.run 'service httpd restart'
#topfile中使用案例
base:
  'saltmini':
    - web.apache
  'roles:apache':
    - match: grain
    - web.apache
</pre>

**注：**
<pre>
#不重启直接刷新grains
salt '*' saltutil.sync_grains
</pre>

####配置管理案例:1

开发一个Graing：

> 脚本必须存放于base环境下的_grains目录内

<pre>
[root@m01 /srv/salt/_grains]# cat my_grains.py 
#!/usr/bin/env python
#-*- coding: utf-8 -*-

def my_grains():
    #初始化一个grains字典
    grains={}
    #设置字典中的key-value
    grains['iaas']='openstack'
    grains['edu']='oldboyedu'
    #返回这个字典
    return grains

#刷新grains
salt '*' saltutil.sync_grains
#可能的重载模块
salt '*' sys.reload_modules
</pre>
**如果出问题，可以查看minion日志**

####Grains优先级

1. 系统自带
2. grains文件写的
3. minion配置文件写的
4. 自己写的

###Pillar

　　动态数据。

　　给特定的Minion指定特定的数据，只有指定的minion自己能看到自己的数据。

　　top file

<pre>
#查看items
salt '*' pillar.items
#设置master配置的pillar位置
pillar_roots:
  base:
    - /srv/pillar
#在pillar目录中写完pillar之后，可能需要刷新
salt '*' saltutil.refresh_pillar
</pre>

1. 写pillar sls
2. top file

###Pillar使用场景

1. 目标选择

##Grains VS Pillar

|        |类型|数据采集方式|应用场景|定义位置|
|--------|:---|----------|-------|------:|
|Grains  |静态|minion启动时收集|数据查询、目标选择、配置管理|minion|
|Pillar  |动态|master自定义|目标选择、配置管理、敏感数据|master|

#深入学习Saltstack远程执行

eg:
`salt '*' cmd.run 'w'`
<pre>
命令：salt
目标：'*'
模块：cmd.run 自带150+模块。还可以自己写模块
返回：执行后结果返回，Returnners
</pre>

##目标:Targeting

两种:

1. 一种和Minion ID有关
2. 一种和Minion ID无关

###和Minion ID有关的
- Minion ID
- 通配符
- 列表
- 正则表达式

**eg:**
<pre>
#通配符
[root@m01 ~]# salt 'saltmini[1|2]' test.ping

[root@m01 ~]# salt 'saltmini[!1]' test.ping

[root@m01 ~]# salt 'saltmini?' test.ping

[root@m01 ~]# salt 'saltmini[1-2]' test.ping
#列表
salt -L 'saltmini,saltmini2' test.ping
</pre>
**所有匹配目标的方式，都可以用到top file里面来指定目标。**

主机名设置方案：

1. IP地址
2. 根据业务来进行设置

eg：
`redis-node1-redis04-idc04-soa.example.com`
redis第一个节点，redis04集群，idc04机房，soa业务线

###和Minion ID无关

<pre>
[root@m01 ~]# salt -S '172.16.1.9' test.ping

[root@m01 ~]# salt -S '172.16.1.0/24' test.ping
</pre>
<pre>
#master中的组配置
[root@m01 ~]# vim /etc/salt/master
nodegroups:
  web: 'L@saltmini,saltmini2'
[root@m01 ~]# salt -N web test.ping
#混合匹配
salt -C 'G@os:Ubuntu and webser* or E@database.*' test.ping
</pre>

##执行模块
[Saltstack所有执行模块](http://docs.saltstack.cn/ref/modules/all/index.html#all-salt-modules)

[返回到mysql](http://docs.saltstack.cn/ref/returners/all/salt.returners.mysql.html#module-salt.returners.mysql)

##如何编写状态模块

自带模块路径：
`[root@m01 ~]# vim /usr/lib/python2.6/site-packages/salt/modules/service.py`

编写模块：

- 放哪
`/srv/salt/_modules`
- 命令
`文件名就是模块名`

预习：
[Saltstack自动化部署OpenStack](https://github.com/unixhot/saltstack-openstack-yum)