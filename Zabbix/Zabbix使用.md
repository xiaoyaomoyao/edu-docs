#Zabbix使用

- 主机组

**标准化有利于二次开发**

> 主机组：对主机分组，
> Hosts：name使用fqdn名

- 添加一个Hosts：

当Hosts选择使用SNMP时，Macros至少要创建一个自定义宏： {$SNMP_COMMUNITY}等于你SNMP服务器的团体名。