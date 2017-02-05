#!/usr/bin/env python 
# -*- coding: utf-8 -*-
import xmlrpclib 

class CobblerAPI(object):
    def __init__(self,url,user,password):
        self.cobbler_user= user
        self.cobbler_pass = password
        self.cobbler_url = url
    
    def add_system(self,hostname,ip_add,mac_add,profile):
        '''
        Add Cobbler System Infomation
        '''
        ret = {
            "result": True,
            "comment": [],
        }
        #get token
        remote = xmlrpclib.Server(self.cobbler_url) 
        token = remote.login(self.cobbler_user,self.cobbler_pass) 
		
		#add system
        system_id = remote.new_system(token) 
        remote.modify_system(system_id,"name",hostname,token) 
        remote.modify_system(system_id,"hostname",hostname,token) 
        remote.modify_system(system_id,'modify_interface', { 
            "macaddress-eth0" : mac_add, 
            "ipaddress-eth0" : ip_add, 
            "dnsname-eth0" : hostname, 
        }, token) 
        remote.modify_system(system_id,"profile",profile,token) 
        remote.save_system(system_id, token) 
        try:
            remote.sync(token)
        except Exception as e:
            ret['result'] = False
            ret['comment'].append(str(e))
        return ret

def main():
    cobbler = CobblerAPI("http://192.168.56.11/cobbler_api","cobbler","cobbler")
    ret = cobbler.add_system(hostname='cobbler-api-test',ip_add='192.168.56.111',mac_add='00:50:56:25:C2:AA',profile='CentOS-7-x86_64')
    print ret

if __name__ == '__main__':
    main()