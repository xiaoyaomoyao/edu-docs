#Cobbler自动化安装系统流程

> 1.0
> 
> 这里只对CentOS7系操作系统讲解

##安装Cobbler软件包
###操作系统版本及环境准备
<pre>
[root@cobbler ~]# cat /etc/redhat-release     #系统版本
CentOS Linux release 7.2.1511 (Core) 
[root@cobbler ~]# uname -r                #内核版本
3.10.0-327.18.2.el7.x86_64
[root@cobbler ~]# getenforce              #检测selinux是否关闭(必须关闭)
Disabled
[root@cobbler ~]# systemctl status firewalld
● firewalld.service - firewalld - dynamic firewall daemon
   Loaded: loaded (/usr/lib/systemd/system/firewalld.service; disabled; vendor preset: enabled)
   Active: inactive (dead)
[root@cobbler ~]# ifconfig eth0|awk -F '[ :]+' 'NR==2{print $3}'
10.0.0.72
[root@cobbler ~]# hostname
cobbler
[root@cobbler ~]# wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo
--2016-12-18 19:41:16--  http://mirrors.aliyun.com/repo/epel-7.repo
Resolving mirrors.aliyun.com (mirrors.aliyun.com)... 115.28.122.210, 112.124.140.210
Connecting to mirrors.aliyun.com (mirrors.aliyun.com)|115.28.122.210|:80... connected.
HTTP request sent, awaiting response... 200 OK
Length: 1084 (1.1K) [application/octet-stream]
Saving to: ‘/etc/yum.repos.d/epel.repo’

100%[===========================================================================================>] 1,084       --.-K/s   in 0s      

2016-12-18 19:41:16 (150 MB/s) - ‘/etc/yum.repos.d/epel.repo’ saved [1084/1084]
[root@cobbler ~]# ll /etc/yum.repos.d/epel.repo 
-rw-r--r-- 1 root root 1084 May 15  2015 /etc/yum.repos.d/epel.repo
</pre>

**注意：使用虚拟机的话，NAT模式注意取消自带的DHCP功能，以免冲突。**

###安装Cobbler

<pre>
[root@cobbler ~]# yum install cobbler cobbler-web pykickstart httpd dhcp tftp-server -y
</pre>

###安装后相关重要目录文件说明
<pre>
[root@cobbler ~]# rpm -ql cobbler  # 查看安装的文件，下面列出部分。
/etc/cobbler                  # 配置文件目录
/etc/cobbler/settings         # cobbler主配置文件，这个文件是yaml格式，cobbler是python写的程序。
/etc/cobbler/dhcp.template    # dhcp服务的配置模板
/etc/cobbler/tftpd.template   # tftp服务的配置模板
/etc/cobbler/rsync.template   # rsync服务的配置模板
/etc/cobbler/iso              # iso模板配置文件目录
/etc/cobbler/pxe              # pxe模板文件目录
/etc/cobbler/power            # 电源的配置文件目录
/etc/cobbler/users.conf       # web服务授权配置文件
/etc/cobbler/users.digest     # web访问的用户名密码配置文件
/etc/cobbler/dnsmasq.template # DNS服务的配置模板
/etc/cobbler/modules.conf     # cobbler模块配置文件
/var/lib/cobbler              # cobbler数据目录
/var/lib/cobbler/config       # 配置文件
/var/lib/cobbler/kickstarts   # 默认存放kickstart文件
/var/lib/cobbler/loaders      # 存放的各种引导程序
/var/www/cobbler              # 系统安装镜像目录
/var/www/cobbler/ks_mirror    # 导入的系统镜像列表
/var/www/cobbler/images       # 导入的系统镜像启动文件
/var/www/cobbler/repo_mirror  # yum源存储目录
/var/log/cobbler              # 日志目录
/var/log/cobbler/install.log  # 客户端系统安装日志
/var/log/cobbler/cobbler.log  # cobbler日志
</pre>

###检测Cobbler
####启动httpd和cobbler服务
<pre>
[root@cobbler ~]# systemctl start httpd
[root@cobbler ~]# systemctl status httpd
● httpd.service - The Apache HTTP Server
   Loaded: loaded (/usr/lib/systemd/system/httpd.service; disabled; vendor preset: disabled)
   Active: active (running) since Sun 2016-12-18 20:00:36 CST; 20s ago
     Docs: man:httpd(8)
           man:apachectl(8)
 Main PID: 1681 (httpd)
   Status: "Total requests: 0; Current requests/sec: 0; Current traffic:   0 B/sec"
   CGroup: /system.slice/httpd.service
           ├─1681 /usr/sbin/httpd -DFOREGROUND
           ├─1682 (wsgi:cobbler_w -DFOREGROUND
           ├─1683 /usr/sbin/httpd -DFOREGROUND
           ├─1684 /usr/sbin/httpd -DFOREGROUND
           ├─1685 /usr/sbin/httpd -DFOREGROUND
           ├─1686 /usr/sbin/httpd -DFOREGROUND
           └─1687 /usr/sbin/httpd -DFOREGROUND

Dec 18 20:00:35 cobbler systemd[1]: Starting The Apache HTTP Server...
Dec 18 20:00:36 cobbler httpd[1681]: AH00558: httpd: Could not reliably determine the server's fully qualified domain name,...message
Dec 18 20:00:36 cobbler systemd[1]: Started The Apache HTTP Server.
Hint: Some lines were ellipsized, use -l to show in full.
[root@cobbler ~]# systemctl start cobblerd
[root@cobbler ~]# systemctl status cobblerd
● cobblerd.service - Cobbler Helper Daemon
   Loaded: loaded (/usr/lib/systemd/system/cobblerd.service; disabled; vendor preset: disabled)
   Active: active (running) since Sun 2016-12-18 20:01:44 CST; 5s ago
  Process: 1725 ExecStartPost=/usr/bin/touch /usr/share/cobbler/web/cobbler.wsgi (code=exited, status=0/SUCCESS)
 Main PID: 1724 (cobblerd)
   CGroup: /system.slice/cobblerd.service
           └─1724 /usr/bin/python2 /usr/bin/cobblerd -F

Dec 18 20:01:44 cobbler systemd[1]: Starting Cobbler Helper Daemon...
Dec 18 20:01:44 cobbler systemd[1]: Started Cobbler Helper Daemon.
</pre>

####检测Cobbler配置存在的问题
<pre>
[root@cobbler ~]# cobbler check
The following are potential configuration items that you may want to fix:

1 : The 'server' field in /etc/cobbler/settings must be set to something other than localhost, or kickstarting features will not work.  This should be a resolvable hostname or IP for the boot server as reachable by all machines that will use it.
2 : For PXE to be functional, the 'next_server' field in /etc/cobbler/settings must be set to something other than 127.0.0.1, and should match the IP of the boot server on the PXE network.
3 : change 'disable' to 'no' in /etc/xinetd.d/tftp
4 : some network boot-loaders are missing from /var/lib/cobbler/loaders, you may run 'cobbler get-loaders' to download them, or, if you only want to handle x86/x86_64 netbooting, you may ensure that you have installed a *recent* version of the syslinux package installed and can ignore this message entirely.  Files in this directory, should you want to support all architectures, should include pxelinux.0, menu.c32, elilo.efi, and yaboot. The 'cobbler get-loaders' command is the easiest way to resolve these requirements.
5 : enable and start rsyncd.service with systemctl
6 : debmirror package is not installed, it will be required to manage debian deployments and repositories
7 : The default password used by the sample templates for newly installed machines (default_password_crypted in /etc/cobbler/settings) is still set to 'cobbler' and should be changed, try: "openssl passwd -1 -salt 'random-phrase-here' 'your-password-here'" to generate new one
8 : fencing tools were not found, and are required to use the (optional) power management features. install cman or fence-agents to use them

Restart cobblerd and then run 'cobbler sync' to apply changes.
</pre>

####逐一解决检测出的问题
1. 修改/etc/cobbler/settings文件中的server参数的值为提供cobbler服务的主机相应的IP地址或主机名，如server: 10.0.0.72;
<pre>
[root@cobbler ~]# cp /etc/cobbler/settings{,.ori20161218}
[root@cobbler ~]# sed -i 's#server: 127.0.0.1#server: 10.0.0.72#g' /etc/cobbler/settings
</pre>

2. 修改/etc/cobbler/settings文件中的next_server参数的值为提供PXE服务的主机相应的IP地址，如next_server: 192.168.31.71;
**这里是设置pxe服务器的地址，因为都是同一台，而且sed语法跟上一个一样，所以同时替换了**
<pre>
[root@cobbler ~]# grep "server: 10.0.0.72" /etc/cobbler/settings
next_server: 10.0.0.72
server: 10.0.0.72
</pre>

3. 修改/etc/xinetd.d/tftp文件中的disable参数修改为 disable = no
<pre>
#备份
[root@cobbler ~]# cp /etc/xinetd.d/tftp{,.ori20161218}
#修改
[root@cobbler ~]# sed 's#disable.*= yes#disable\t\t\t= no#g' /etc/xinetd.d/tftp
</pre>

4. 执行 cobbler get-loaders 命令即可；否则，需要安装syslinux程序包，而后复制/usr/share/syslinux/{pxelinux.0,memu.c32}等文件至/var/lib/cobbler/loaders/目录中;
<pre>
[root@cobbler ~]# cobbler get-loaders
task started: 2016-12-18_202500_get_loaders
task started (id=Download Bootloader Content, time=Sun Dec 18 20:25:00 2016)
downloading http://cobbler.github.io/loaders/README to /var/lib/cobbler/loaders/README
downloading http://cobbler.github.io/loaders/COPYING.elilo to /var/lib/cobbler/loaders/COPYING.elilo
downloading http://cobbler.github.io/loaders/COPYING.yaboot to /var/lib/cobbler/loaders/COPYING.yaboot
downloading http://cobbler.github.io/loaders/COPYING.syslinux to /var/lib/cobbler/loaders/COPYING.syslinux
downloading http://cobbler.github.io/loaders/elilo-3.8-ia64.efi to /var/lib/cobbler/loaders/elilo-ia64.efi
downloading http://cobbler.github.io/loaders/yaboot-1.3.17 to /var/lib/cobbler/loaders/yaboot
downloading http://cobbler.github.io/loaders/pxelinux.0-3.86 to /var/lib/cobbler/loaders/pxelinux.0
downloading http://cobbler.github.io/loaders/menu.c32-3.86 to /var/lib/cobbler/loaders/menu.c32
downloading http://cobbler.github.io/loaders/grub-0.97-x86.efi to /var/lib/cobbler/loaders/grub-x86.efi
downloading http://cobbler.github.io/loaders/grub-0.97-x86_64.efi to /var/lib/cobbler/loaders/grub-x86_64.efi
*** TASK COMPLETE ***
[root@cobbler ~]# ls /var/lib/cobbler/loaders/
COPYING.elilo     COPYING.yaboot  grub-x86_64.efi  menu.c32    README
COPYING.syslinux  elilo-ia64.efi  grub-x86.efi     pxelinux.0  yaboot
</pre>

5. 启动rsync服务
<pre>
[root@cobbler ~]# systemctl start rsyncd
</pre>

7. 生成密码来取代默认的密码，更安全
<pre>
#生成密码
[root@cobbler ~]# openssl passwd -1 -salt 'xiaoyaomoyao' 'xxxxxx'
$1$xiaoyaom$Lg1puGDj/0E4gENH.M6b7/
#写入文件
[root@cobbler ~]# vim /etc/cobbler/settings
default_password_crypted: "$1$xiaoyaom$Lg1puGDj/0E4gENH.M6b7/"
</pre>

8. fenc-agents安装
<pre>
[root@cobbler ~]# yum install -y cman ence-agents
</pre>

####修改完再次检查
<pre>
[root@cobbler ~]# systemctl restart cobblerd
[root@cobbler ~]# cobbler check
The following are potential configuration items that you may want to fix:

1 : debmirror package is not installed, it will be required to manage debian deployments and repositories

Restart cobblerd and then run 'cobbler sync' to apply changes.
</pre>
**debmirror是debian系统相关，这里不需要.**

####配置Cobbler管理其他相关服务功能
<pre>
# 用Cobbler管理DHCP
sed -i 's/manage_dhcp: 0/manage_dhcp: 1/' /etc/cobbler/settings
# 防止循环装系统，适用于服务器第一启动项是PXE启动。
sed -i 's/pxe_just_once: 0/pxe_just_once: 1/' /etc/cobbler/settings
</pre>

###配置DHCP服务
<pre>
[root@cobbler ~]# vim /etc/cobbler/dhcp.template
subnet 10.0.0.0 netmask 255.255.255.0 {
     option routers             10.0.0.2;
     option domain-name-servers 114.114.114.114;
     option subnet-mask         255.255.255.0;
     range dynamic-bootp        10.0.0.100 10.0.0.254;
     default-lease-time         21600;
     max-lease-time             43200;
     next-server                $next_server;
......
</pre>

###同步Cobbler配置
<pre>
[root@cobbler ~]# cobbler sync
task started: 2016-12-18_211157_sync
task started (id=Sync, time=Sun Dec 18 21:11:57 2016)
running pre-sync triggers
cleaning trees
removing: /var/lib/tftpboot/pxelinux.cfg/default
removing: /var/lib/tftpboot/grub/images
removing: /var/lib/tftpboot/grub/grub-x86.efi
removing: /var/lib/tftpboot/grub/grub-x86_64.efi
removing: /var/lib/tftpboot/grub/efidefault
removing: /var/lib/tftpboot/s390x/profile_list
copying bootloaders
trying hardlink /var/lib/cobbler/loaders/grub-x86.efi -> /var/lib/tftpboot/grub/grub-x86.efi
trying hardlink /var/lib/cobbler/loaders/grub-x86_64.efi -> /var/lib/tftpboot/grub/grub-x86_64.efi
copying distros to tftpboot
copying images
generating PXE configuration files
generating PXE menu structure
rendering DHCP files
generating /etc/dhcp/dhcpd.conf
rendering TFTPD files
generating /etc/xinetd.d/tftp
cleaning link caches
running post-sync triggers
running python triggers from /var/lib/cobbler/triggers/sync/post/*
running python trigger cobbler.modules.sync_post_restart_services
running: dhcpd -t -q
received on stdout: 
received on stderr: 
running: service dhcpd restart
received on stdout: 
received on stderr: Redirecting to /bin/systemctl restart  dhcpd.service

running shell triggers from /var/lib/cobbler/triggers/sync/post/*
running python triggers from /var/lib/cobbler/triggers/change/*
running python trigger cobbler.modules.scm_track
running shell triggers from /var/lib/cobbler/triggers/change/*
*** TASK COMPLETE ***
</pre>
**这里其实就是将源配置移除，在重新根据模版文件生成**

###设置开机自启动
<pre>
#设置开机自动启动，避免白辛苦一场
[root@cobbler ~]# systemctl enable dhcpd.service
[root@cobbler ~]# systemctl enable rsyncd.service
[root@cobbler ~]# systemctl enable tftp.service 
[root@cobbler ~]# systemctl enable httpd.service 
[root@cobbler ~]# systemctl enable cobblerd.service
#将所有的服务重启一遍,避免有服务忘了开启
[root@cobbler ~]# systemctl restart dhcpd.service
[root@cobbler ~]# systemctl restart rsyncd.service
[root@cobbler ~]# systemctl restart tftp.service 
[root@cobbler ~]# systemctl restart httpd.service 
[root@cobbler ~]# systemctl restart cobblerd.service
</pre>

##Cobbler的命令行管理
###查看命令帮助
<pre>
[root@cobbler ~]# cobbler
usage
=====
cobbler <distro|profile|system|repo|image|mgmtclass|package|file> ... 
        [add|edit|copy|getks*|list|remove|rename|report] [options|--help]
cobbler <aclsetup|buildiso|import|list|replicate|report|reposync|sync|validateks|version|signature|get-loaders|hardlink> [options|--help]
</pre>
<pre>
cobbler check    核对当前设置是否有问题
cobbler list     列出所有的cobbler元素
cobbler report   列出元素的详细信息
cobbler sync     同步配置到数据目录,更改配置最好都要执行下
cobbler reposync 同步yum仓库
cobbler distro   查看导入的发行版系统信息
cobbler system   查看添加的系统信息
cobbler profile  查看配置信息
</pre>

###Cobbler工作模式
![Cobbler工作模式](https://raw.githubusercontent.com/xiaoyaomoyao/edu-docs/master/Cobbler_workmode.png)

###导入镜像
1. 查看命令参数：
<pre>
[root@cobbler ~]# cobbler import --help
Usage: cobbler [options]

Options:
  -h, --help            show this help message and exit
  --arch=ARCH           OS architecture being imported
  --breed=BREED         the breed being imported
  --os-version=OS_VERSION
                        the version being imported
  --path=PATH           local path or rsync location
  --name=NAME           name, ex 'RHEL-5'
  --available-as=AVAILABLE_AS
                        tree is here, don't mirror
  --kickstart=KICKSTART_FILE
                        assign this kickstart file
  --rsync-flags=RSYNC_FLAGS
                        pass additional flags to rsync
</pre>

2. 导入镜像
<pre>
#导入CentOS-7.2系统
[root@cobbler ~]# cobbler import --path=/mnt/ --name=CentOS-7.2-x86_64 --arch=x86_64task started: 2016-12-18_215823_import
task started (id=Media import, time=Sun Dec 18 21:58:23 2016)
Found a candidate signature: breed=redhat, version=rhel6
Found a candidate signature: breed=redhat, version=rhel7
Found a matching signature: breed=redhat, version=rhel7
Adding distros from path /var/www/cobbler/ks_mirror/CentOS-7.2-x86_64:
creating new distro: CentOS-7.2-x86_64
trying symlink: /var/www/cobbler/ks_mirror/CentOS-7.2-x86_64 -> /var/www/cobbler/links/CentOS-7.2-x86_64
creating new profile: CentOS-7.2-x86_64
associating repos
checking for rsync repo(s)
checking for rhn repo(s)
checking for yum repo(s)
starting descent into /var/www/cobbler/ks_mirror/CentOS-7.2-x86_64 for CentOS-7.2-x86_64
processing repo at : /var/www/cobbler/ks_mirror/CentOS-7.2-x86_64
need to process repo/comps: /var/www/cobbler/ks_mirror/CentOS-7.2-x86_64
looking for /var/www/cobbler/ks_mirror/CentOS-7.2-x86_64/repodata/*comps*.xml
Keeping repodata as-is :/var/www/cobbler/ks_mirror/CentOS-7.2-x86_64/repodata
*** TASK COMPLETE ***
#导入CentOS6.8系统
[root@cobbler ~]# cobbler import --path=/mnt/ --name=CentOS-6.8-x86_64 --arch=x86_64
......
#镜像存放路径
[root@cobbler ~]# ll /var/www/cobbler/ks_mirror/
total 8
dr-xr-xr-x 7 root root 4096 May 23  2016 CentOS-6.8-x86_64
dr-xr-xr-x 8 root root 4096 Dec 10  2015 CentOS-7.2-x86_64
drwxr-xr-x 2 root root   68 Dec 18 22:09 config
[root@cobbler ~]# du -sh /var/www/cobbler/ks_mirror/*
3.7G	/var/www/cobbler/ks_mirror/CentOS-6.8-x86_64
4.2G	/var/www/cobbler/ks_mirror/CentOS-7.2-x86_64
8.0K	/var/www/cobbler/ks_mirror/config
</pre>

###指定ks.cfg文件及调整内核参数
<pre>
# Cobbler的ks.cfg文件存放的位置
[root@cobbler ~]# cd /var/lib/cobbler/kickstarts/
[root@cobbler kickstarts]# ls
default.ks        legacy.ks            sample_esx4.ks   sample_old.seed
esxi4-ks.cfg      pxerescue.ks         sample_esxi4.ks  sample.seed
esxi5-ks.cfg      sample_autoyast.xml  sample_esxi5.ks
install_profiles  sample_end.ks        sample.ks

#上传准备好的ks文件到本目录
[root@cobbler kickstarts]# mv CentOS-6.8-cobbler.cfg CentOS-6.8-x86_64.cfg
[root@cobbler kickstarts]# mv CentOS-7.2-cobbler.cfg CentOS-7.2-x86_64.cfg
[root@cobbler kickstarts]# ls CentOS-*
CentOS-6.8-x86_64.cfg  CentOS-7.2-x86_64.cfg

#在第一次导入镜像后，Cobbler会给镜像指定一个默认的kickstart自动安装文件在/var/lib/cobbler/kickstarts下的sample_end.ks。
[root@cobbler kickstarts]# cobbler list
distros:
   CentOS-6.8-x86_64
   CentOS-7.2-x86_64

profiles:
   CentOS-6.8-x86_64
   CentOS-7.2-x86_64

systems:

repos:

images:

mgmtclasses:

packages:

files:

# 查看安装镜像文件信息
[root@cobbler kickstarts]# cobbler distro report
Name                           : CentOS-7.2-x86_64
Architecture                   : x86_64
TFTP Boot Files                : {}
Breed                          : redhat
Comment                        : 
Fetchable Files                : {}
Initrd                         : /var/www/cobbler/ks_mirror/CentOS-7.2-x86_64/images/pxeboot/initrd.img
Kernel                         : /var/www/cobbler/ks_mirror/CentOS-7.2-x86_64/images/pxeboot/vmlinuz
Kernel Options                 : {}
Kernel Options (Post Install)  : {}
Kickstart Metadata             : {'tree': 'http://@@http_server@@/cblr/links/CentOS-7.2-x86_64'}
Management Classes             : []
OS Version                     : rhel7
Owners                         : ['admin']
Red Hat Management Key         : <<inherit>>
Red Hat Management Server      : <<inherit>>
Template Files                 : {}

Name                           : CentOS-6.8-x86_64
Architecture                   : x86_64
TFTP Boot Files                : {}
Breed                          : redhat
Comment                        : 
Fetchable Files                : {}
Initrd                         : /var/www/cobbler/ks_mirror/CentOS-6.8-x86_64/images/pxeboot/initrd.img
Kernel                         : /var/www/cobbler/ks_mirror/CentOS-6.8-x86_64/images/pxeboot/vmlinuz
Kernel Options                 : {}
Kernel Options (Post Install)  : {}
Kickstart Metadata             : {'tree': 'http://@@http_server@@/cblr/links/CentOS-6.8-x86_64'}
Management Classes             : []
OS Version                     : rhel6
Owners                         : ['admin']
Red Hat Management Key         : <<inherit>>
Red Hat Management Server      : <<inherit>>
Template Files                 : {}

#查看所有profile设置(加--name查看指定)
[root@cobbler kickstarts]# cobbler profile report
Name                           : CentOS-7.2-x86_64
TFTP Boot Files                : {}
Comment                        : 
DHCP Tag                       : default
Distribution                   : CentOS-7.2-x86_64
Enable gPXE?                   : 0
Enable PXE Menu?               : 1
Fetchable Files                : {}
Kernel Options                 : {}
Kernel Options (Post Install)  : {}
Kickstart                      : /var/lib/cobbler/kickstarts/sample_end.ks  -->默认ks文件
Kickstart Metadata             : {}
Management Classes             : []
Management Parameters          : <<inherit>>
Name Servers                   : []
Name Servers Search Path       : []
Owners                         : ['admin']
Parent Profile                 : 
Internal proxy                 : 
Red Hat Management Key         : <<inherit>>
Red Hat Management Server      : <<inherit>>
Repos                          : []
Server Override                : <<inherit>>
Template Files                 : {}
Virt Auto Boot                 : 1
Virt Bridge                    : xenbr0
Virt CPUs                      : 1
Virt Disk Driver Type          : raw
Virt File Size(GB)             : 5
Virt Path                      : 
Virt RAM (MB)                  : 512
Virt Type                      : kvm

Name                           : CentOS-6.8-x86_64
TFTP Boot Files                : {}
Comment                        : 
DHCP Tag                       : default
Distribution                   : CentOS-6.8-x86_64
Enable gPXE?                   : 0
Enable PXE Menu?               : 1
Fetchable Files                : {}
Kernel Options                 : {}
Kernel Options (Post Install)  : {}
Kickstart                      : /var/lib/cobbler/kickstarts/sample_end.ks
Kickstart Metadata             : {}
Management Classes             : []
Management Parameters          : <<inherit>>
Name Servers                   : []
Name Servers Search Path       : []
Owners                         : ['admin']
Parent Profile                 : 
Internal proxy                 : 
Red Hat Management Key         : <<inherit>>
Red Hat Management Server      : <<inherit>>
Repos                          : []
Server Override                : <<inherit>>
Template Files                 : {}
Virt Auto Boot                 : 1
Virt Bridge                    : xenbr0
Virt CPUs                      : 1
Virt Disk Driver Type          : raw
Virt File Size(GB)             : 5
Virt Path                      : 
Virt RAM (MB)                  : 512
Virt Type                      : kvm

#编辑profile，修改关联的ks文件
[root@cobbler kickstarts]# cobbler profile edit --name=CentOS-6.8-x86_64 --kickstart=/var/lib/cobbler/kickstarts/CentOS-6.8-x86_64.cfg
[root@cobbler kickstarts]# cobbler profile edit --name=CentOS-7.2-x86_64 --kickstart=/var/lib/cobbler/kickstarts/CentOS-7.2-x86_64.cfg

#因为CentOS7系列网卡名称改变，为了统一管理，要变成常用的eth0，因此需要使用下面的参数，CentOS7需要操作
[root@cobbler kickstarts]# cobbler profile edit --name=CentOS-7.2-x86_64 --kopts='net.ifnames=0 biosdevname=0'
[root@cobbler kickstarts]# cobbler profile report
Name                           : CentOS-7.2-x86_64
TFTP Boot Files                : {}
Comment                        : 
DHCP Tag                       : default
Distribution                   : CentOS-7.2-x86_64
Enable gPXE?                   : 0
Enable PXE Menu?               : 1
Fetchable Files                : {}
Kernel Options                 : {'biosdevname': '0', 'net.ifnames': '0'}
Kernel Options (Post Install)  : {}
Kickstart                      : /var/lib/cobbler/kickstarts/CentOS-7.2-x86_64.cfg
Kickstart Metadata             : {}
Management Classes             : []
Management Parameters          : <<inherit>>
Name Servers                   : []
Name Servers Search Path       : []
Owners                         : ['admin']
Parent Profile                 : 
Internal proxy                 : 
Red Hat Management Key         : <<inherit>>
Red Hat Management Server      : <<inherit>>
Repos                          : []
Server Override                : <<inherit>>
Template Files                 : {}
Virt Auto Boot                 : 1
Virt Bridge                    : xenbr0
Virt CPUs                      : 1
Virt Disk Driver Type          : raw
Virt File Size(GB)             : 5
Virt Path                      : 
Virt RAM (MB)                  : 512
Virt Type                      : kvm

Name                           : CentOS-6.8-x86_64
TFTP Boot Files                : {}
Comment                        : 
DHCP Tag                       : default
Distribution                   : CentOS-6.8-x86_64
Enable gPXE?                   : 0
Enable PXE Menu?               : 1
Fetchable Files                : {}
Kernel Options                 : {}
Kernel Options (Post Install)  : {}
Kickstart                      : /var/lib/cobbler/kickstarts/CentOS-6.8-x86_64.cfg
Kickstart Metadata             : {}
Management Classes             : []
Management Parameters          : <<inherit>>
Name Servers                   : []
Name Servers Search Path       : []
Owners                         : ['admin']
Parent Profile                 : 
Internal proxy                 : 
Red Hat Management Key         : <<inherit>>
Red Hat Management Server      : <<inherit>>
Repos                          : []
Server Override                : <<inherit>>
Template Files                 : {}
Virt Auto Boot                 : 1
Virt Bridge                    : xenbr0
Virt CPUs                      : 1
Virt Disk Driver Type          : raw
Virt File Size(GB)             : 5
Virt Path                      : 
Virt RAM (MB)                  : 512
Virt Type                      : kvm

#修改Cobbler提示(装机时客户端的提示界面信息)
[root@cobbler kickstarts]# vim /etc/cobbler/pxe/pxedefault.template

# 每次修改完配置，都要同步一下
[root@cobbler kickstarts]# cobbler sync
</pre>

###安装系统
新建一台虚拟机，启动之后就会进入安装：

![新虚拟机安装系统界面](https://raw.githubusercontent.com/xiaoyaomoyao/edu-docs/master/Cobbler_Boot.png)

##定制化安装
###指定某台机器使用指定的ks文件
* 1.查看机器的MAC地址，如：

![VM_MAC](https://raw.githubusercontent.com/xiaoyaomoyao/edu-docs/master/VM_MAC.png)

* 2.指定固定机器安装
<pre>
[root@cobbler kickstarts]# cobbler system add --name=mb-cbtest --mac=00:50:56:20:81:C4 --profile=CentOS-7.2-x86_64 --ip-address=10.0.0.111 --subnet=255.255.255.0 --gateway=10.0.0.2 --interface=eth0 --static=1 --hostname=mb-cbtest.example.com --name-servers="114.114.114.114" --kickstart=/var/lib/cobbler/kickstarts/CentOS-7.2-x86_64.cfg 
[root@cobbler kickstarts]# cobbler system list
   mb-cbtest
[root@cobbler kickstarts]# cobbler sync
</pre>

###构建YUM源
* 1.添加外网源并同步下来
<pre>
[root@cobbler ~]# cobbler repo add --name=openstack-mitaka --mirror= http://mirrors.aliyun.com/centos/7.2.1511/cloud/x86_64/openstack-mitaka/ --arch=x86_64 --breed=yum
[root@cobbler ~]# cobbler reposync
</pre>
**注：会将连接地址的中的包都下载下来，并且自动创建repo文件。创建的虚机会自动创建repo文件。**

* 2.添加到默认的repo中(能让新建新装机器有这个repo文件)
<pre>
[root@cobbler ~]# cobbler profile edit --name=CentOS-7.2-x86_64 --repo="openstack-mitaka"
#说明：添加之后，默认情况是会增加。此处的默认情况指：
[root@cobbler ~]# grep "yum_post" /etc/cobbler/settings
yum_post_install_mirror: 1     #这个默认开启，说明默认会同步自定义repo文件
#同时，在Kickstart文件中：
%post
systemctl disable postfix.service
$yum_config_stanza
%end
#post段中添加这个参数。
#添加定时任务，定期同步repo,如：
echo "1 3 * * * cobbler reposync --tries=3 --no-fail" >>/var/spool/cron/root
</pre>

###使用api自定义安装
查看api配置：
<pre>
[root@cobbler conf.d]# cd /etc/httpd/conf.d/
[root@cobbler conf.d]# cat cobbler_web.conf
#文件中对应的api的proxy。
ProxyPass /cobbler_api http://localhost:25151/
ProxyPassReverse /cobbler_api http://localhost:25151/
</pre>
例如：

1）通过API接口调用：
<pre>
[root@CentOS6 ~]# cat cobbler_list.py 
#!/usr/env python

import xmlrpclib

server=xmlrpclib.Server("http://10.0.0.72/cobbler_api")

print server.get_distros()
print server.get_profiles()
print server.get_systems()
print server.get_images()
print server.get_repos()
</pre>
- 更多参考：cobbler.github.io
- 参考：cobbler_web网站的代码来编写。

###自动重装
**在你要重装的机器上操作**
<pre>
#安装koan工具，注需要准备好epel源
[root@mb-cbtest ~]# yum install -y koan

#查看Cobbler服务器上的可用模版
[root@mb-cbtest ~]# koan --server=10.0.0.72 --list=profiles
- looking for Cobbler at http://10.0.0.72:80/cobbler_api
CentOS-7.2-x86_64
CentOS-6.8-x86_64

#指定从哪个镜像进行安装
[root@mb-cbtest ~]# koan --replace-self --server=10.0.0.72 --profile=CentOS-7.2-x86_64
......
- reboot to apply changes

#重启系统进行重装
[root@mb-cbtest ~]# reboot
</pre>