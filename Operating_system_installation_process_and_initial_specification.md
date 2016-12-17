# 操作系统安装流程及初始化规范

>    v1.0

## 操作系统安装流程
1. 服务器采购
2. 服务器验收并设置raid
    `如果需要验收，就不能出厂做raid`
3. 服务商提供验收单，运维验收负责人签字
4. 服务器上架
5. 资产录入
6. 开始自动化安装

> 6.1.将新服务器划入装机划入VLAN

> 6.2.根据资产清单上的mac地址，自定义安装
>
* 机房
* 机房区域
* 机柜
* 服务器位置
* 服务器网线接入端口
* 该端口MAC地址
* 操作系统、分区等
* 预分配的IP地址、主机名、子网、网关、DNS、角色

> 6.3.自动化装机平台，安装
* IP:10.0.0.111
* 主机名:mb-cbtest
* 掩码:255.255.255.0
* 网关:10.0.0.2
* DNS:114.114.114.114

> 6.4.对固定主机添加安装模版
<pre>
cobbler system add --name=mb-cbtest --mac=00:50:56:20:81:C4 --profile=CentOS-7.2-x86_64 --ip-address=10.0.0.111 --subnet=255.255.255.0 --getway=10.0.0.2 --interface=eth0 --static=1 --hostname=mb-cbtest --name-servers="114.114.114.114" --kicakstart=/var/lib/cobbler/kicakstarts/CentOS-7.2-x86_64.cfg
#同步配置
cobbler sync
</pre>

##操作系统安装规范

1. 当前我公司使用操作系统为CentOS 6和CentOS 7，均使用x86_64位系统，需使用公司cobbler进行自动化安装。禁止自定义设置。
2. 版本选择，数据库统一使用cobbler上CentOS-7-DB这个专用的profile，其他web应用统一使用cobbler上CentOS-7-web。

## 系统初始化规范

###初始化操作
* 设置DNS: 如:192.168.56.111 192.168.56.112
* 安装Zabbix Agent: Zabbix Server:192.168.56.11
* 安装Saltstack Minion: Saltstack Master: 192.168.45.11
* history记录时间
<pre>
    export HISTTIMEFORMAT="%F %T `whoami`"
</pre>
* 日志记录操作
<pre>
#所有日志都记录到message中
export PROMAT_COMMAND=`{ msg=$(history 1|{read x y; echo $y;});logger "[euid=$(whoami)]":$(who am i):[`pwd`]"msg";}`
</pre>
* 内核参数优化
* yum仓库
* 主机名解析

### 目录规范
* 脚本放置目录： /opt/shell
* 脚本日志目录： /opt/shell/log
* 脚本锁文件目录： /opt/shell/lock

### 程序服务安装规范
1. 源码安装路径： /usr/local/appname.version
2. 创建软链接： ln -s /usr/local/appname.version /usr/local/appname

### 主机名命名规范

  **机房名-项目-角色-集群-节点.域名**

例子:

    idc01-xxshop-nginx-bj-node1.shop.com

###服务启动用户规范

所有服务，统一使用www用户，uid为666，除负载均衡需要监听80端口使用root启动外，所有服务必须使用www用户启动，使用大于1024的端口。