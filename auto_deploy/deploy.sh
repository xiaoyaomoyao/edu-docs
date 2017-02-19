#!/bin/bash

. /etc/init.d/functions

#node list
NODE_LIST="172.16.1.8 172.16.1.7"
GROUP1_LIST="172.16.1.8"        #一般来讲取名预热节点，就一个机器。
GROUP2_LIST="172.16.1.7"

#env
SHELL_NAME="deploy.sh"
SHELL_DIR="/home/www/"
SHELL_LOG="${SHELL_DIR}/${SHELL_NAME}.log"
LOCK_FILE="/tmp/deploy.lock"

#Date/Time Variables
LOG_DATE=`date "+%Y-%m-%d"`
LOG_TIME=`date "+%H-%M-%S"`

CDATE=`date "+%Y-%m-%d"`
CTIME=`date "+%H-%M-%S"`

#Code Env
PRO_NAME="web-demo"
CODE_DIR="/deploy/code/web-demo"
CONFIG_DIR="/deploy/config/web-demo"
TMP_DIR="/deploy/tmp"
TAR_DIR="/deploy/tar"

usage(){
    echo $"Usage: $0 [deploy|rollback]"
}

writelog(){
    LOGINFO=$1
    echo "${CDATE} ${CTIME}: ${SHELL_NAME} : ${LOGINFO}" >>${SHELL_LOG}
}

shell_lock(){
    touch ${LOCK_FILE}
}

url_test(){
    URL=$1
    curl -Is $URL|grep "200 ok"
    if [ $? -ne 0 ];then
      shell_unlock
      writelog "test error" && exit
    fi
}

shell_unlock(){
    rm ${LOCK_FILE} -f
}

code_get(){
    writelog "code_get";
    cd ${CODE_DIR} && echo "git pull"    #这个目录不能动，只做git pull用，然后拷贝到别处进行打包
    cp -r ${CODE_DIR} ${TMP_DIR}/
    API_VER="V3010"
}

code_build(){
    echo "code_build"
}

code_config(){
    writelog "code_config"
    /bin/cp -r ${CONFIG_DIR}/base/* ${TMP_DIR}/${PRO_NAME}/
    PKG_NAME=${PRO_NAME}_${API_VER}-${CDATE}-${CTIME}
    cd ${TMP_DIR} && mv ${PRO_NAME} ${PKG_NAME}
}

code_tar(){
    writelog "code_tar"
    cd ${TMP_DIR} && tar zcf ${PKG_NAME}.tar.gz ${PKG_NAME}
    writelog "${PKG_NAME}.tar.gz"
}

code_scp(){
    writelog "code_scp"
    for node in $GROUP1_LIST;do
      scp ${TMP_DIR}/${PKG_NAME}.tar.gz $node:/opt/webroot/
    done
    for node in $GROUP2_LIST;do
      scp ${TMP_DIR}/${PKG_NAME}.tar.gz $node:/opt/webroot/
    done
}

cluster_node_remove(){
    writelog "cluster_node_remove"
}

#预热节点就一个节点，也不需要for循环，并且上边的移除节点合在一个函数中写
pre_deploy(){
    writelog "remove from cluster"
    ssh $PRE_LIST "cd /opt/webroot && tar zxf ${PKG_NAME}.tar.gz"
    ssh $PRE_LIST "rm -rf /webroot/${PRO_NAME} && ln -s /opt/webroot/${PKG_NAME} /webroot/${PRO_NAME}"
}
pre_test(){
    url_test "http://$PRT_LIST/index.html"
    echo "add to cluster"
}

group1_deploy(){
    echo "group2_deploy"
    for node in $GROUP1_LIST
    do
      ssh $node "cd /opt/webroot && tar zxf ${PKG_NAME}.tar.gz"
      ssh $node "rm -rf /webroot/${PRO_NAME} && ln -s /opt/webroot/${PKG_NAME} /webroot/${PRO_NAME}"
    done
}

group1_test(){
    write_log "group1_test"
    url_test "http://www.etest.org/index.html"
    echo "add to cluster"
}

group2_deploy(){
    echo "group2_deploy"
    for node in $GROUP2_LIST
    do
      ssh $node "cd /opt/webroot && tar zxf ${PKG_NAME}.tar.gz"
      ssh $node "rm -rf /webroot/${PRO_NAME} && ln -s /opt/webroot/${PKG_NAME} /webroot/${PRO_NAME}"
    done
    scp ${CONFIG_DIR}/other/172.16.1.7.crontab.xml 172.16.1.7:/webroot/${PRO_NAME}/crontab.xml
}

group2_test(){
    write_log "group2_test"
    url_test "http://www.etest.org/index.html"
    echo "add to cluster"
}

#可以和上边合在一起，函数太多看着也乱，而且都属于部署的任务
#config_diff(){
#    writelog "config_diff"
#    for node in $GROUP2_LIST
#    do
#      ssh $node "rm -rf /webroot/${PRO_NAME} && ln -s /opt/webroot/${PKG_NAME} /webroot/${PRO_NAME}"
#    done
#    scp ${CONFIG_DIR}/other/172.16.1.7.crontab.xml 172.16.1.7:/webroot/${PRO_NAME}/crontab.xml
#}

#code_test(){
#    echo "code_test"
#    curl -Is http://www.etest1.org/index.html|grep "200"|wc -l
#}

cluster_node_in(){
    echo "cluster_node_in"
}

rollback(){
    echo "rollback"
}

main(){
  if [ -f $LOCK_FILE ];then
    echo "Deploy is running" && exit 1
  fi
  DEPLOY_METHOD=$1
  case "$1" in
    deploy)
      shell_lock;
      code_get;
      code_build;
      code_config;
      code_tar;
      code_scp;
      cluster_node_remove;
      group1_deploy;
      group1_test;
      group2_deploy;
      group2_test;
#      config_diff;
#      code_test;
      cluster_node_in;
      shell_unlock;
      ;;
    rollback)
      shell_lock;
      rollback;
      shell_unlock;
      ;;
    *)
      usage;
  esac
}

main $*
