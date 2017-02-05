#smokeping安装

##时间同步
<pre>
yum -y install ntpdate
ntpdate times.aliyun.com
</pre>

##安装依赖包
<pre>
yum groupinstall "Compatibility libraries" "Base" "Development tools" -y

yum -y install cpan perl perl-FCGI perl-CGI perl-Digest-HMAC perl-Net-Telnet perl-Net-OpenSSH perl-Net-SNMP perl-LDAP perl-Net-DNS perl-IO-Pty-Easy perl-Test-Simple perl-Sys-Syslog perl-libwww-perl perl-IO-Socket-SSL perl-Socket6 perl-CGI-SpeedyCGI perl-Time-HiRes perl-ExtUtils-MakeMaker rrdtool rrdtool-perl rrdtool-devel rrdtool-utils curl fping httpd httpd-devel gcc make wget libxml2-devel libpng-devel glib pango pango-devel freetype freetype-devel fontconfig cairo cairo-devel libart_lgpl libart_lgpl-devel mod_fcgid screen perl-RadiusPerl perl-CGI-SpeedCGI perl-RRD-Simple perl-Sys-Syslog zlib-devel apr-util-devel apr-devel libxml2 perl-XML-Simple.noarch perl-Crypt-SSLeay perl-Digest-HMAC perl-ExtUtils-CBuilder perl-ExtUtils-Embed
</pre>

##安装echoping
<pre>
tar xf echoping-6.0.2.tar.gz
cd echoping-6.0.2
./configure--prefix=/usr/local/echoping
make && makeinstall
</pre>

##安装smokeping
<pre>
cd /application/tools
tar xf smokeping-2.6.11.tar.gz
cd smokeping-2.6.11

#export PERL5LIB=/usr/local/smokeping/thirdparty/lib/perl5/
./setup/build-perl-modules.sh /usr/local/smokeping/thirdparty
./configure --prefix=/usr/local/smokeping
gmake install

如果./configure过程中提示找不到某些perl扩展，如下所示
checking checking for perl module‘Config::Grammar‘... Can‘t locate Config/Grammar.pm in @INC (@INC contains:/usr/local/smokeping/thirdparty/lib/perl5 /usr/local/lib64/perl5 /usr/local/share/perl5/usr/lib64/perl5/vendor_perl /usr/share/perl5/vendor_perl /usr/lib64/perl5/usr/share/perl5 .) at -e line 1.
BEGIN failed--compilation aborted at -e line 1.
</pre>

请使用以下命令安装对应模块：
<pre>
perl -MCPAN -e ‘install Config::Grammar‘
</pre>
**注意：有时候需要重复安装几次才能装上模块。**

**注意要选择国内的的模块源，不然速度很慢。**

##创建相关目录和日志文件
<pre>
cd /usr/local/smokeping
mkdir cache data var 
touch /var/log/smokeping.log 
chown apache.apache cache/ data/ var/ /var/log
</pre>
因为这里的web服务使用的是httpd，所以相关文件的属主属组均为apache

##创建相关配置文件

###fcgi文件
<pre>
cp /usr/local/smokeping/htdocs/smokeping.fcgi.dist /usr/local/smokeping/htdocs/smokeping.fcgi 
</pre>
###主配置文件
<pre>
cp /usr/local/smokeping/etc/config.dist/usr/local/smokeping/etc/config
</pre>

##修改配置文件

###指定cgi的url地址为本机
<pre>
sed -i ‘s#cgiurl   = http://some.url/smokeping.cgi#cgiurl   = http://10.0.0.111/smokeping.cgi#g’/usr/local/smokeping/etc/config
</pre>

###指定检测的时间为60秒
<pre>
sed -i ‘s#step    = 300#step     = 60#g’/usr/local/smokeping/etc/config 
</pre>

###指定ping的次数为60
<pre>
sed -i ‘s#pings   =20#pings    =60#g’/usr/local/smokeping/etc/config
</pre>
将step和pings都设置为60表示每60秒ping60次。

###修改fping目录
<pre>
binary = /usr/local/sbin/fping
</pre>

###修改字符集和字体支持中文
<pre>
vim /usr/local/smokeping/etc/config
***Presentation ***
charset= utf-8

yum -y install wqy-zenhei-fonts

vim/usr/local/smokeping//lib/Smokeping/Graphs.pm

        my$val = 0;

        formy $host (@hosts){

            my ($graphret,$xs,$ys) = RRDs::graph

           ("dummy",

           ‘--start‘, $tasks[0][1],

           ‘--end‘, $tasks[0][2],

            ‘--font TITLE:20"WenQuanYiZen Hei Mono"‘,

           "DEF:maxping=$cfg->{General}{datadir}${host}.rrd:median:AVERAGE",

           ‘PRINT:maxping:MAX:%le‘ );

           my $ERROR = RRDs::error();
</pre>

###修改apache配置文件增加登录验证
<pre>
htpasswd -c /usr/local/smokeping/htdocs/htpasswd smokeping
chmod 600 /usr/local/smokeping/etc/smokeping_secrets.dist
</pre>

##修改httpd.conf增加smokeping的web界面

在httpd.conf末尾添加如下内容
<pre>
vim /etc/httpd/conf/httpd.conf

Alias /cache "/usr/local/smokeping/cache/"
Alias /cropper "/usr/local/smokeping/htdocs/cropper/"
Alias /smokeping "/usr/local/smokeping/htdocs/smokeping.fcgi"
`<`Directory "/usr/local/smokeping"`>`
AllowOverride None
Options All
AddHandler cgi-script .fcgi .cgi
AllowOverride AuthConfig
Order allow,deny
Allow from all
AuthName "Smokeping"
AuthType Basic
AuthUserFile /usr/local/smokeping/htdocs/htpasswd
Require valid-user
DirectoryIndex smokeping.fcgi
`<`/Directory`>`
</pre>
**注意：双引号英文，正常会变成红色**

##添加监控对象
<pre>
vim /usr/local/smokeping/etc/config
*** Targets ***
++ Localhost
menu = Localhost
title = Localhost
alerts = someloss
#slaves = boomer slave2
host = 10.0.0.111
</pre>

##添加监控节点

注意：每次修改配置文件后需要重启smokeping进程
<pre>
/usr/local/smokeping/bin/smokeping --restart
或
/usr/local/smokeping/bin/smokeping --reload
或
pkill smokeping
/usr/local/smokeping/bin/smokeping
</pre>

监控节点样例如下，注意+是第一层，++是第二层，+++ 是第三层：
<pre>
vim /usr/local/smokeping/etc/config
+ Other
menu = 三大网络监控
title = 监控统计
++ dianxin
menu = 电信网络监控
title = 电信网络监控列表
host = /Other/dianxin/dianxin-bj/Other/dianxin/dianxin-hlj /Other/dianxin/dianxin-tj  /Other/dianxin/dianxin-sc  /Other/dianxin/dianxin-sh/Other/dianxin/dianxin-gz
+++ dianxin-bj
menu = 北京电信
title = 北京电信
alerts = someloss
host = 202.96.199.133
 
+++ dianxin-hlj
menu = 黑龙江电信
title = 黑龙江电信
alerts = someloss
host = 219.147.198.242
 
+++ dianxin-tj
menu = 天津电信
title = 天津电信
alerts = someloss
host = 219.150.32.132
 
+++ dianxin-sc
menu = 四川电信
title = 四川电信
alerts = someloss
host = 61.139.2.69
 
+++ dianxin-sh
menu = 上海电信
title = 上海电信
alerts = someloss
host = 116.228.111.118
 
+++ dianxin-gz
menu = 广东电信
title = 广东电信
alerts = someloss
host = 113.111.211.22
 
++ liantong
menu = 联通网络监控
title = 联通网络监控列表
host = /Other/liantong/liantong-bj/Other/liantong/liantong-hlj /Other/liantong/liantong-tj  /Other/liantong/liantong-sc/Other/liantong/liantong-sh /Other/liantong/liantong-gz
 
+++ liantong-bj
menu = 北京联通
title = 北京联通
alerts = someloss
host = 61.135.169.121
 
+++ liantong-hlj
menu = 黑龙江联通
title = 黑龙江联通
alerts = someloss
host = 202.97.224.69
 
+++ liantong-tj
menu = 天津联通
title = 天津联通
alerts = someloss
host = 202.99.96.68
 
+++ liantong-sc
menu = 四川联通
title = 四川联通
alerts = someloss
host = 119.6.6.6
 
+++ liantong-sh
menu = 上海联通
title = 上海联通
alerts = someloss
host = 210.22.84.3
 
+++ liantong-gz
menu = 广东联通
title = 广东联通
alerts = someloss
host = 221.5.88.88
 
++ yidong
menu = 移动网络监控
title = 移动网络监控列表
host = /Other/yidong/yidong-bj/Other/yidong/yidong-hlj /Other/yidong/yidong-tj  /Other/yidong/yidong-sc  /Other/yidong/yidong-sh/Other/yidong/yidong-gz
 
+++ yidong-bj
menu = 北京移动
title = 北京移动
alerts = someloss
host = 221.130.33.52
 
+++ yidong-hlj
menu = 黑龙江移动
title = 黑龙江移动
alerts = someloss
host = 211.137.241.35
 
+++ yidong-tj
menu = 天津移动
title = 天津移动
alerts = someloss
host = 211.137.160.5
 
+++ yidong-sc
menu = 四川移动
title = 四川移动
alerts = someloss
host = 218.201.4.3
 
+++ yidong-sh
menu = 上海移动
title = 上海移动
alerts = someloss
host = 117.131.19.23
 
+++ yidong-gz
menu = 广东移动
title = 广东移动
alerts = someloss
host = 211.136.192.6
</pre>

smokeping会根据配置文件中配置监控节点的内容，在/usr/local/smokeping/data目录下生成对应的moniter文件夹，其下包含website子文件夹。
<pre>
[root@linux-node2 smokeping]# tree/usr/local/smokeping/data/
/usr/local/smokeping/data/
├── Other
│   ├── dianxin
│   │   ├── dianxin-bj.rrd
│   │   ├── dianxin-gd.rrd
│   │   ├── dianxin-gs.rrd
│   │   ├── dianxin-gz.rrd
│   │   ├── dianxin-hlj.rrd
│   │   ├── dianxin-sc.rrd
│   │   ├── dianxin-sh.rrd
│   │   └── dianxin-tj.rrd
│   ├── liantong
│   │   ├── liantong-bj.rrd
│   │   ├── liantong-gz.rrd
│   │   ├── liantong-hlj.rrd
│   │   ├── liantong-sc.rrd
│   │   ├── liantong-sh.rrd
│   │   └── liantong-tj.rrd
│   └── yidong
│      ├── yidong-bj.rrd
│      ├── yidong-gz.rrd
│      ├── yidong-hlj.rrd
│      ├── yidong-sc.rrd
│      ├── yidong-sh.rrd
│      └── yidong-tj.rrd
├── __sortercache
│   └── data.FPing.storable
└── Test
    ├──James~boomer.rrd
    ├──James.rrd
    ├──James~slave2.rrd
    └──Localhost.rrd
</pre>

##启动服务并测试
<pre>
systemctl start httpd
/usr/local/smokeping/bin/smokeping
</pre>

###在浏览器中访问

http://10.0.0.111/smokeping

#附录：

##更改CPAN源的方法：
<pre>
[root@linux-node2 smokeping-2.6.11]# cpan
Sorry, we have to rerun the configuration dialogfor CPAN.pm due to
some missing parameters. Configuration will bewritten to
 <</root/.cpan/CPAN/MyConfig.pm>>
 
 
CPAN.pm requires configuration, but most of it canbe done automatically.
If you answer ‘no‘ below, you will enter aninteractive dialog for each
configuration option instead.
 
Would you like to configure as much as possibleautomatically? [yes] yes
 
 <install_help>
 
Warning: You do not have write permission for Perllibrary directories.
 
To install modules, you need to configure a localPerl library directory or
escalate your privileges.  CPAN can help you by bootstrapping thelocal::lib
module or by configuring itself to use ‘sudo‘ (ifavailable).  You may also
resolve this problem manually if you need tocustomize your setup.
 
What approach do you want?  (Choose ‘local::lib‘, ‘sudo‘ or ‘manual‘)
 [local::lib]
 
Autoconfigured everything but ‘urllist‘.
 
Now you need to choose your CPAN mirror sites.  You can let me
pick mirrors for you, you can select them from alist or you
can enter them by hand.
 
Would you like me to automatically choose someCPAN mirror
sites for you? (This means connecting to theInternet) [yes] no
 
Would you like to pick from the CPAN mirror list?[yes] yes
Found a cached mirror list as of Mon Jun 1307:01:48 2016
 
If you‘d like to just use the cached copy, answer‘yes‘, below.
If you‘d like an updated copy of the mirror list,answer ‘no‘ and
I‘ll get a fresh one from the Internet.
 
Shall I use the cached mirror list? [yes] yes
First, pick a nearby continent and country bytyping in the number(s)
in front of the item(s) you want to select. Youcan pick several of
each, separated by spaces. Then, you will bepresented with a list of
URLs of CPAN mirrors in the countries youselected, along with
previously selected URLs. Select some of thoseURLs, or just keep the
old list. Finally, you will be prompted for anyextra URLs -- file:,
ftp:, or http: -- that host a CPAN mirror.
 
You should select more than one (just in case thefirst isn‘t available).
 
(1) Africa
(2) Asia
(3) Europe
(4) North America
(5) Oceania
(6) South America
Select your continent (or several nearbycontinents) [] 2
(1) Bangladesh
(2) China
(3) India
(4) Indonesia
(5) Iran
(6) Israel
(7) Japan
(8) Kazakhstan
(9) Philippines
(10) Qatar
(11) Republic of Korea
(12) Singapore
(13) Taiwan
(14) Turkey
(15) Viet Nam
Select your country (or several nearby countries)[] 2
(1) ftp://ftp.cuhk.edu.hk/pub/packages/perl/CPAN/
(2) ftp://mirrors.ustc.edu.cn/CPAN/
(3) ftp://mirrors.xmu.edu.cn/CPAN/
(4) http://cpan.communilink.net/
(5) http://ftp.cuhk.edu.hk/pub/packages/perl/CPAN/
(6) http://mirror.lzu.edu.cn/CPAN/
(7) http://mirrors.163.com/cpan/
(8) http://mirrors.hust.edu.cn/CPAN/
(9) http://mirrors.neusoft.edu.cn/cpan/
(10) http://mirrors.sohu.com/CPAN/
(11) http://mirrors.ustc.edu.cn/CPAN/
(12) http://mirrors.xmu.edu.cn/CPAN/
(13) http://mirrors.zju.edu.cn/CPAN/
Select as many URLs as you like (by number),
put them on one line, separated by blanks,hyphenated ranges allowed
 e.g. ‘1 45‘ or ‘7 1-4 8‘ [] 7 
Now you can enter your own CPAN URLs by hand. Alocal CPAN mirror can be
listed using a ‘file:‘ URL like‘file:///path/to/cpan/‘
 
Enter another URL or ENTER to quit: []
New urllist
 http://mirrors.163.com/cpan/
 
Autoconfiguration complete.
 
Attempting to bootstrap local::lib...
 
Writing /root/.cpan/CPAN/MyConfig.pm forbootstrap...
commit: wrote ‘/root/.cpan/CPAN/MyConfig.pm‘
Fetching with LWP:
http://mirrors.163.com/cpan/authors/01mailrc.txt.gz
Reading‘/root/.cpan/sources/authors/01mailrc.txt.gz‘
............................................................................DONE
Fetching with LWP:
http://mirrors.163.com/cpan/modules/02packages.details.txt.gz
Reading‘/root/.cpan/sources/modules/02packages.details.txt.gz‘
  Databasewas generated on Thu, 09 Jun 2016 22:53:42 GMT
.............
  NewCPAN.pm version (v2.10) available.
  [Currentlyrunning version is v1.9800]
  You mightwant to try
    install CPAN
    reloadcpan
  to bothupgrade CPAN.pm and run the new version without leaving
  thecurrent session.
 
 
...............................................................DONE
Fetching with LWP:
http://mirrors.163.com/cpan/modules/03modlist.data.gz
Reading‘/root/.cpan/sources/modules/03modlist.data.gz‘
DONE
Writing /root/.cpan/Metadata
Running make forH/HA/HAARG/local-lib-2.000019.tar.gz
Fetching with LWP:
http://mirrors.163.com/cpan/authors/id/H/HA/HAARG/local-lib-2.000019.tar.gz
Fetching with LWP:
http://mirrors.163.com/cpan/authors/id/H/HA/HAARG/CHECKSUMS
Checksum for/root/.cpan/sources/authors/id/H/HA/HAARG/local-lib-2.000019.tar.gz ok
 
  CPAN.pm:Building H/HA/HAARG/local-lib-2.000019.tar.gz
 
 
Checking if your kit is complete...
Looks good
Warning: prerequisite Test::More 0 not found.
Generating a Unix-style Makefile
Writing Makefile for local::lib
Writing MYMETA.yml and MYMETA.json
---- Unsatisfied dependencies detected during ----
----     HAARG/local-lib-2.000019.tar.gz    ----
    Test::More [build_requires]
Running make test
  Delayeduntil after prerequisites
Running make install
  Delayeduntil after prerequisites
Tried to deactivate inactive local::lib‘/root/perl5‘
 
local::lib is installed. You must now add thefollowing environment variables
to your shell configuration files (or registry, ifyou are on Windows) and
then restart your command line shell and CPANbefore installing modules:
 
Use of uninitialized value $deactivating innumeric eq (==) at /usr/share/perl5/vendor_perl/local/lib.pm line 381.
Use of uninitialized value $deactivating innumeric eq (==) at /usr/share/perl5/vendor_perl/local/lib.pm line 383.
Use of uninitialized value$options{"interpolate"} in numeric eq (==) at /usr/share/perl5/vendor_perl/local/lib.pmline 424.
Use of uninitialized value$options{"interpolate"} in numeric eq (==) at/usr/share/perl5/vendor_perl/local/lib.pm line 424.
Use of uninitialized value$options{"interpolate"} in numeric eq (==) at /usr/share/perl5/vendor_perl/local/lib.pmline 424.
exportPERL_LOCAL_LIB_ROOT="$PERL_LOCAL_LIB_ROOT:/root/perl5";
export PERL_MB_OPT="--install_base/root/perl5";
exportPERL_MM_OPT="INSTALL_BASE=/root/perl5";
exportPERL5LIB="/root/perl5/lib/perl5:$PERL5LIB";
export PATH="/root/perl5/bin:$PATH";
 
Would you like me to append that to /root/.bashrcnow? [yes]
 
 
commit: wrote ‘/root/.cpan/CPAN/MyConfig.pm‘
 
You can re-run configuration any time with ‘o confinit‘ in the CPAN shell
Terminal does not support AddHistory.
 
cpan shell -- CPAN exploration and modulesinstallation (v1.9800)
Enter ‘h‘ for help.
 
cpan[1]> exit
Terminal does not support GetHistory.
Lockfile removed.
 
*** Remember to restart your shell before runningcpan again ***
</pre>

或
<pre>
# perl -MCPAN -e shell
cpan> o conf urllist unshift http://mirrors.aliyun.com/CPAN/ 
cpan> o conf commit
</pre>
或
<pre>
vim /usr/share/perl5/CPAN/Config.pm
'urllist' => [], -> 'urllist' => [q[http://mirrors.163.com/cpan/]],
然后手动通过cpan安装模块
</pre>

###smokeping配置文件常用参数
<pre>
** General ***
http://smokeping.xxx.com/smokeping.cgi  # 访问smokeping网页的URL，必须与web服务器配置一致

*** Database ***
step     = 300  # ping检测的周期，单位s
pings    = 100  # 每个周期内ping的次数
                # 调整step和pings参数 会使之前的监控记录失效（？）

*** Presentation ***
charset = utf-8 # 指定字符集为UTF-8。默认没有该参数，网页上显示的中文是乱码

+ overview      # overview视图的尺寸
width = 1000
height = 150
range = 12h

+ detail        # detail视图的尺寸
width = 1000
height = 200
unison_tolerance = 2
# 详细视图中要显示的几个图表，前面的字符串是标题，后面的数字+单位控制时间范围

"Last 3 Hours"    1h    # 最近1小时的丢包率
"Last 24 Hours"   24h
"Last 7 Days"    7d     # 最近7天的丢包率
"Last 30 Days"   30d

*** Slaves ***  # （单节点模式可以不配置slave）
secrets=/usr/local/smokeping/etc/smokeping_secrets  # 用于验证slave的密码文件

+192.168.X.X                # 一个slave节点的配置样例
display_name = 192.168.X.X
color = 00ff00              # slave的丢包率曲线颜色（要与其他节点的曲线颜色有区别）

*** Targets ***     # 配置要监控的目标

+ IDC1
menu = IDC1         # 浏览器左栏的节点名
title = IDC_1       # 标题
remark = IDC_1      # 注释

++ host1
menu = host1
title = host_1
host = 192.168.1.1

++ host2
menu = host2
title = host_2
host = 192.168.1.2
slaves=192.168.X.X  # （单节点模式可以不配置slave）
# 这样，在浏览器的左栏会有一个树状的监控对象列表。根节点是IDC1，展开之后可以看到host1、host2。点击host1、host2可以看到详细的监控记录。 其中host2除了有master ping host2的监控图、还有slave ping host2的监控图
</pre>