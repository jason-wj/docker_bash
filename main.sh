#!/usr/bin/env bash

MODE=$1
STATE=$2

# 项目名(根据项目改，同时需要改掉docker-compose.yml中的)
PROJECT_NAME=x

# 项目模式：开发-dev、生产-prod
# 当 使用到了传到仓库的自定义镜像的时候，需要切换为prod，否则默认dev即可
PROJECT_MODE=dev

# 镜像推送的账号和密码
DOCKER_USERNAME=xxx@xxx.xx
DOCKER_PASSWORD=xxx

# 镜像推送名称
PUSH_ROOT_REGISTRY="registry.cn-hangzhou.aliyuncs.com"

# docker-compose 文件名
DOCKER_COMPOSE_FILE="docker-compose.yml"

# 项目根路径
export ROOT_PATH=$(pwd)

# 如果环境变量docker_compose所在目录不为空，则优先使用
if [[ -n ${DOCKER_COMPOSE_PATH} ]]; then
    export ROOT_PATH=${DOCKER_COMPOSE_PATH}
fi

# 外部触发指令
# 用户级
COMMAND_MONGO="mongo"
COMMAND_MYSQL="mysql"
COMMAND_MARIADB="mariadb"
COMMAND_REDIS="redis"
COMMAND_MQ="mq"
COMMAND_IPFS="ipfs"
COMMAND_JAVA="java"
COMMAND_NGINX="nginx"
COMMAND_PORTAINER="portainer"
COMMAND_YAPI="yapi"
COMMAND_PYTHON="python"
COMMAND_CONSUL1="consul1"
COMMAND_CONSUL2="consul2"
COMMAND_CONSUL3="consul3"
COMMAND_UI="consului"
COMMAND_ETCD1="etcd1"
COMMAND_ETCD2="etcd2"
COMMAND_ETCD3="etcd3"
COMMAND_ETCDUI="etcdui"
COMMAND_ARBNODE="arbnode"
COMMAND_DTF="dtf"
COMMAND_YNODE="ynode"

# 容器版本
export IMAGE_MONGO="mongo"
export IMAGE_MYSQL="mysql:5.7"
export IMAGE_MARIADB="mariadb:10.3"
export IMAGE_REDIS="redis"
export IMAGE_IPFS="ipfs/go-ipfs:latest"
export IMAGE_MQ="rabbitmq:3.8.3-management"
export IMAGE_JAVA="java:8"
export IMAGE_NGINX="nginx"
export IMAGE_PORTAINER="portainer/portainer"
export IMAGE_YAPI="jayfong/yapi:latest"
export IMAGE_PYTHON="python:3.4"
export IMAGE_CONSUL="consul"
export IMAGE_ETCD="bitnami/etcd:latest"
export IMAGE_ETCDUI="evildecay/etcdkeeper"
export IMAGE_ARBNODE="offchainlabs/arb-node:v1.1.2-cffb3a0"
export IMAGE_DTF="yedf/dtm:latest"
export IMAGE_YNODE="jitesoft/node-yarn"

# container：必须保留，当一个容器涉及到多个依赖时，方便选择加入
export CONTAINER_MONGO=${PROJECT_NAME}"-"${COMMAND_MONGO}
export CONTAINER_MYSQL=${PROJECT_NAME}"-"${COMMAND_MYSQL}
export CONTAINER_MARIADB=${PROJECT_NAME}"-"${COMMAND_MARIADB}
export CONTAINER_REDIS=${PROJECT_NAME}"-"${COMMAND_REDIS}
export CONTAINER_MQ=${PROJECT_NAME}"-"${COMMAND_MQ}
export CONTAINER_IPFS=${PROJECT_NAME}"-"${COMMAND_IPFS}
export CONTAINER_JAVA=${PROJECT_NAME}"-"${COMMAND_JAVA}
export CONTAINER_NGINX=${PROJECT_NAME}"-"${COMMAND_NGINX}
export CONTAINER_PORTAINER=${PROJECT_NAME}"-"${COMMAND_PORTAINER}
export CONTAINER_YAPI=${PROJECT_NAME}"-"${COMMAND_YAPI}
export CONTAINER_PYTHON=${PROJECT_NAME}"-"${COMMAND_PYTHON}
export CONTAINER_CONSUL1=${PROJECT_NAME}"-"${COMMAND_CONSUL1}
export CONTAINER_CONSUL2=${PROJECT_NAME}"-"${COMMAND_CONSUL2}
export CONTAINER_CONSUL3=${PROJECT_NAME}"-"${COMMAND_CONSUL3}
export CONTAINER_UI=${PROJECT_NAME}"-"${COMMAND_UI}
export CONTAINER_ETCD1=${PROJECT_NAME}"-"${COMMAND_ETCD1}
export CONTAINER_ETCD2=${PROJECT_NAME}"-"${COMMAND_ETCD2}
export CONTAINER_ETCD3=${PROJECT_NAME}"-"${COMMAND_ETCD3}
export CONTAINER_ETCDUI=${PROJECT_NAME}"-"${COMMAND_ETCDUI}
export CONTAINER_ARBNODE=${PROJECT_NAME}"-"${COMMAND_ARBNODE}
export CONTAINER_DTF=${PROJECT_NAME}"-"${COMMAND_DTF}
export CONTAINER_YNODE=${PROJECT_NAME}"-"${COMMAND_YNODE}

# 根据不同项目模式切换镜像，同时
if [[ ${PROJECT_MODE} == "prod" ]]; then
  export IMAGE_JAVA=${PUSH_ROOT_REGISTRY}/${PROJECT_NAME}/${PROJECT_NAME}"-"$1
  docker login --username=${DOCKER_USERNAME} --password ${DOCKER_PASSWORD} ${PUSH_ROOT_REGISTRY}
fi

# 日志查看
function logs_one() {
    docker logs -f ${PROJECT_NAME}"-"${STATE} --tail 15
}

# 进入容器
function exec_one() {
    docker exec -it ${PROJECT_NAME}"-"${STATE} /bin/sh
}

# 推送一个项目docker到仓库
function push_one() {
  docker tag ${IMAGE_JAVA} ${PUSH_ROOT_REGISTRY}/${PROJECT_NAME}/${PROJECT_NAME}"-"${STATE}
  docker push ${PUSH_ROOT_REGISTRY}/${PROJECT_NAME}/${PROJECT_NAME}"-"${STATE}
  docker rmi -f ${PUSH_ROOT_REGISTRY}/${PROJECT_NAME}/${PROJECT_NAME}"-"${STATE}
}

# 启动指定服务
function start_one() {
    docker-compose --log-level ERROR -f "${ROOT_PATH}"/${DOCKER_COMPOSE_FILE} up -d ${PROJECT_NAME}"-"${STATE}
}

function release_state() {
    if [[ ${STATE} == "" ]]; then
        printHelp
        exit 1
    elif [[ ${STATE} == "all" ]]; then
        release_all
    else
        release_one "${STATE}"
    fi
}

# 无论全局清理还是单独清理，都会执行如下内容，删除无效网络、卷、容器、镜像等
function release_base(){
    docker volume ls -qf dangling=true
    # 查看指定的volume
    # docker inspect docker_orderer.example.com

    # 开始清理
    if [[ -n $(docker volume ls -qf dangling=true) ]]; then
      docker volume rm $(docker volume ls -qf dangling=true)
    fi
    # 删除为none的镜像
    docker images | grep none | awk '{print $3}' | xargs docker rmi -f
    docker images --no-trunc | grep '<none>' | awk '{ print $3 }' | xargs docker rmi

    # 该指令默认会清除所有如下资源：
    # 已停止的容器（container）、未被任何容器所使用的卷（volume）、未被任何容器所关联的网络（network）、所有悬空镜像（image）。
    # 该指令默认只会清除悬空镜像，未被使用的镜像不会被删除。添加-a 或 --all参数后，可以一并清除所有未使用的镜像和悬空镜像。
    docker system prune -f

    # 删除无用的卷
    docker volume prune -f

    # 删除无用网络
    docker network prune -f
}

# 全局释放所有docker环境，当前系统所有镜像都会受到影响
# 不确定则请慎用
function release_all() {
    docker-compose -f "${ROOT_PATH}"/${DOCKER_COMPOSE_FILE} stop
    # 关闭当前系统正在运行的容器，并清除
    docker stop $(docker ps -a | awk '{ print $1}' | tail -n +2)
    docker rm -f $(docker ps -a | awk '{ print $1}' | tail -n +2)
    release_base
}

# 清理关闭一个指定容器
function release_one() {
  docker-compose -f "${ROOT_PATH}"/${DOCKER_COMPOSE_FILE} stop ${PROJECT_NAME}"-"$1
  docker-compose -f "${ROOT_PATH}"/${DOCKER_COMPOSE_FILE} rm -f ${PROJECT_NAME}"-"$1
  release_base
}

function printHelp() {
    echo "当前支持的指定服务：[mysql,redis,mongo,mq,ipfs,java,nginx,portainer]"
    echo "./main.sh start [+操作码]：启动服务"
    echo "          [操作码]"
    echo "               指定服务：启动指定服务"
    echo "./main.sh logs [+操作码]：查看日志"
    echo "          [操作码]"
    echo "               指定服务：查看指定日志"
    echo "./main.sh exec [+操作码]：进入容器"
    echo "          [操作码]"
    echo "               指定服务：进入指定容器"
    echo "./main.sh push [+操作码]：推送镜像到仓库"
    echo "          [操作码]"
    echo "               指定服务：推送到指定仓库，当前支持[java]"
    echo "./main.sh release [+操作码]：用于释放项目和其余容器"
    echo "          [操作码]"
    echo "               all：释放项目所有内容，包括各种容器、网络等，非当前docker-compose编排的容器也会被清理，务必谨慎使用！"
    echo "               指定容器名：释放指定容器，主要是用来释放项目所在的容器"
    echo "其余操作将触发此说明"
}

#启动模式
case ${MODE} in
    "start")
        start_one ;;
    "logs")
        logs_one ;;
    "exec")
        exec_one ;;
    "push")
        push_one ;;
    "release")
        release_state ;;
    *)
        printHelp
        exit 1
esac
