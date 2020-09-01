#!/usr/bin/env bash

MODE=$1
STATE=$2

# 项目名(根据项目改，同时需要改掉docker-compose.yml中的myflag)
PROJECT_NAME=myflag

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
ROOT_PATH=$(pwd)

# 如果环境变量docker_compose所在目录不为空，则优先使用
if [[ -n ${DOCKER_COMPOSE_PATH} ]]; then
    ROOT_PATH=${DOCKER_COMPOSE_PATH}
fi

# 外部触发指令
# 用户级
COMMAND_MONGO="mongo"
COMMAND_MYSQL="mysql"
COMMAND_REDIS="redis"
COMMAND_MQ="mq"
COMMAND_IPFS="ipfs"
COMMAND_JEEFREE="jeefree"
COMMAND_JEEFREEUI="jeefreeui"
COMMAND_PORTAINER="portainer"

# 容器版本
IMAGE_MONGO="mongo"
IMAGE_MYSQL="mysql:5.7"
IMAGE_REDIS="redis"
IMAGE_IPFS="ipfs/go-ipfs:latest"
IMAGE_MQ="rabbitmq:3.8.3-management"
IMAGE_JEEFREE="java:8"
IMAGE_JEEFREEUI="nginx"
IMAGE_PORTAINER="portainer/portainer"

# 设置容器网段,格式：xx.xx.xx.0/xx
SUBNET=172.20.0.0/20

# 每个容器设置固定ip
CONTAINER_MONGO_IP=172.20.0.2
CONTAINER_MYSQL_IP=172.20.0.3
CONTAINER_REDIS_IP=172.20.0.4
CONTAINER_IPFS_IP=172.20.0.5
CONTAINER_MQ_IP=172.20.0.6
CONTAINER_JEEFREE_IP=172.20.0.7
CONTAINER_JEEFREEUI_IP=172.20.0.8
CONTAINER_PORTAINER_IP=172.20.0.9

# 根据不同项目模式切换镜像，同时
if [[ ${PROJECT_MODE} == "prod" ]]; then
  IMAGE_JEEFREE=${PUSH_ROOT_REGISTRY}/${PROJECT_NAME}/${PROJECT_NAME}"-"$1
  docker login --username=${DOCKER_USERNAME} --password ${DOCKER_PASSWORD} ${PUSH_ROOT_REGISTRY}
fi

# 日志查看
function logs_one() {
    docker logs -f ${PROJECT_NAME}"-"${STATE} --tail 15
}

# 推送一个项目docker到仓库
function push_one() {
  docker tag ${IMAGE_JEEFREE} ${PUSH_ROOT_REGISTRY}/${PROJECT_NAME}/${PROJECT_NAME}"-"${STATE}
  docker push ${PUSH_ROOT_REGISTRY}/${PROJECT_NAME}/${PROJECT_NAME}"-"${STATE}
  docker rmi -f ${PUSH_ROOT_REGISTRY}/${PROJECT_NAME}/${PROJECT_NAME}"-"${STATE}
}

# 启动指定服务
function start_one() {
    # 程序配置文件的正常读取是在该目录下进行的
    case ${STATE} in
        ${COMMAND_MYSQL})
           SUBNET=${SUBNET} CONTAINER_MYSQL_IP=${CONTAINER_MYSQL_IP} IMAGE_MYSQL=${IMAGE_MYSQL} CONTAINER_MYSQL=${PROJECT_NAME}"-"${STATE} ROOT_PATH=${ROOT_PATH} docker-compose --log-level ERROR -f "${ROOT_PATH}"/${DOCKER_COMPOSE_FILE} up -d ${PROJECT_NAME}"-"${STATE}
        ;;
        ${COMMAND_MONGO})
            SUBNET=${SUBNET} CONTAINER_MONGO_IP=${CONTAINER_MONGO_IP} IMAGE_MONGO=${IMAGE_MONGO} CONTAINER_MONGO=${PROJECT_NAME}"-"${STATE} ROOT_PATH=${ROOT_PATH} docker-compose --log-level ERROR -f "${ROOT_PATH}"/${DOCKER_COMPOSE_FILE} up -d ${PROJECT_NAME}"-"${STATE}
        ;;
        ${COMMAND_REDIS})
            SUBNET=${SUBNET} CONTAINER_REDIS_IP=${CONTAINER_REDIS_IP} IMAGE_REDIS=${IMAGE_REDIS} CONTAINER_REDIS=${PROJECT_NAME}"-"${STATE} ROOT_PATH=${ROOT_PATH} docker-compose --log-level ERROR -f "${ROOT_PATH}"/${DOCKER_COMPOSE_FILE} up -d ${PROJECT_NAME}"-"${STATE}
        ;;
        ${COMMAND_MQ})
            SUBNET=${SUBNET} CONTAINER_MQ_IP=${CONTAINER_MQ_IP} IMAGE_MQ=${IMAGE_MQ} CONTAINER_MQ=${PROJECT_NAME}"-"${STATE} ROOT_PATH=${ROOT_PATH} docker-compose --log-level ERROR -f "${ROOT_PATH}"/${DOCKER_COMPOSE_FILE} up -d ${PROJECT_NAME}"-"${STATE}
        ;;
        ${COMMAND_IPFS})
            SUBNET=${SUBNET} CONTAINER_IPFS_IP=${CONTAINER_IPFS_IP} IMAGE_IPFS=${IMAGE_IPFS} CONTAINER_IPFS=${PROJECT_NAME}"-"${STATE} ROOT_PATH=${ROOT_PATH} docker-compose --log-level ERROR -f "${ROOT_PATH}"/${DOCKER_COMPOSE_FILE} up -d ${PROJECT_NAME}"-"${STATE}
        ;;
        ${COMMAND_JEEFREE})
            SUBNET=${SUBNET} CONTAINER_JEEFREE_IP=${CONTAINER_JEEFREE_IP} IMAGE_JEEFREE=${IMAGE_JEEFREE} CONTAINER_JEEFREE=${PROJECT_NAME}"-"${STATE} ROOT_PATH=${ROOT_PATH} docker-compose --log-level ERROR -f "${ROOT_PATH}"/${DOCKER_COMPOSE_FILE} up -d ${PROJECT_NAME}"-"${STATE}
        ;;
        ${COMMAND_JEEFREEUI})
            SUBNET=${SUBNET} CONTAINER_JEEFREEUI_IP=${CONTAINER_JEEFREEUI_IP} IMAGE_JEEFREEUI=${IMAGE_JEEFREEUI} CONTAINER_JEEFREEUI=${PROJECT_NAME}"-"${STATE} ROOT_PATH=${ROOT_PATH} docker-compose --log-level ERROR -f "${ROOT_PATH}"/${DOCKER_COMPOSE_FILE} up -d ${PROJECT_NAME}"-"${STATE}
        ;;
        ${COMMAND_PORTAINER})
            SUBNET=${SUBNET} CONTAINER_PORTAINER_IP=${CONTAINER_PORTAINER_IP} IMAGE_PORTAINER=${IMAGE_PORTAINER} CONTAINER_PORTAINER=${PROJECT_NAME}"-"${STATE} ROOT_PATH=${ROOT_PATH} docker-compose --log-level ERROR -f "${ROOT_PATH}"/${DOCKER_COMPOSE_FILE} up -d ${PROJECT_NAME}"-"${STATE}
        ;;
        *)
            printHelp
    esac
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
  ROOT_PATH=${ROOT_PATH} docker-compose -f "${ROOT_PATH}"/${DOCKER_COMPOSE_FILE} stop ${PROJECT_NAME}"-"$1
  docker-compose -f "${ROOT_PATH}"/${DOCKER_COMPOSE_FILE} rm -f ${PROJECT_NAME}"-"$1
  release_base
}

function printHelp() {
    echo "当前支持的指定服务：[mysql,redis,mongo,mq,ipfs,jeefree,jeefreeui,portainer]"
    echo "./main.sh start [+操作码]：启动服务"
    echo "          [操作码]"
    echo "               指定服务：启动指定服务"
    echo "./main.sh logs [+操作码]：查看日志"
    echo "          [操作码]"
    echo "               指定服务：查看指定日志"
    echo "./main.sh push [+操作码]：推送镜像到仓库"
    echo "          [操作码]"
    echo "               指定服务：推送到指定仓库，当前支持[jeefree]"
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
    "push")
        push_one ;;
    "release")
        release_state ;;
    *)
        printHelp
        exit 1
esac
