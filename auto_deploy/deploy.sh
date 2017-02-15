#!/bin/bash

. /etc/init.d/functions

#env
SHELL_NAME="deploy.sh"
SHELL_DIR="/home/www/"
SHELL_LOG="${SHELL_DIR}/${SHELL_NAME}.log"
LOCK_FILE="/tmp/deploy.lock"

#Code Env
CODE_DIR="/deploy/code/deploy"
CONFIG_DIR="/deploy/config"
TMP_DIR="/deploy/tmp"
TAR_DIR="/deploy/tar"

usage(){
    echo $"Usage: $0 [deploy|rollback]"
}

shell_lock(){
    touch ${LOCK_FILE}
}

shell_unlock(){
    rm ${LOCK_FILE} -f
}

code_get(){
    echo "code_get"
}

code_build(){
    echo "code_build"
}

code_config(){
    echo "code_config"
}
code_tar(){
    echo "code_tar"
}

code_scp(){
    echo "code_scp"
}

cluster_node_remove(){
    echo "cluster_node_remove"
}

code_deploy(){
    echo "code_deploy"
}

config_diff(){
    echo "config_diff"
}

code_test(){
    echo "code_test"
}

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
      sleep 30;
      code_build;
      code_config;
      code_tar;
      code_scp;
      cluster_node_remove;
      code_deploy;
      code_diff;
      code_test;
      cluster_node_in;
      shell_unlock;
      ;;
    rollback)
      shell_lock;
      sleep 30;
      rollback;
      shell_unlock;
      ;;
    *)
      usage;
  esac
}

main $*
