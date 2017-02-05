#! /usr/bin/env python
# -*- coding: utf-8 -*-
# Author: C.C

import requests
import json

url = 'http://zb.etest.org/api_jsonrpc.php'
post_data = {
    "jsonrpm": "2.0",
    "method": "user.login",
    "params": {
        "user": "xiaoyaomoyao",
        "password": "wuJIEtian1989"
    },
    "id": 1
}
post_header = {'Content-Type':'application/json'}

ret = requests.post(url.data=json.dump(post_data),headers=post_header)

zabbix_ret = json.loads(ret.text)
if not zabbix_ret.has_key('result'):
    print 'login error'
else:
    print zabbix_ret.get('result')