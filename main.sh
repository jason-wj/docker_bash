#!/usr/bin/env bash

MODE=$1
STATE=$2

# 项目名(根据项目改，同时需要改掉docker-compose.yml中的myflag)
PROJECT_NAME=myflag

# 项目模式：开发-dev、生产-prod
PROJECT_MODE=dev

# 镜像上传的账号和密码
DOCKER_USERNAME=xxx@xxx.xxx
DOCKER_PASSWORD=xxx

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

# 容器版本
IMAGE_MONGO="mongo"
IMAGE_MYSQL="mysql:5.7"
IMAGE_REDIS="redis"
IMAGE_JEEFREE="java:8"
IMAGE_IPFS="ipfs/go-ipfs:latest"
IMAGE_MQ="rabbitmq:3.8.3-management"

# 镜像推送名称
PUSH_ROOT_REGISTRY="registry.cn-hangzhou.aliyuncs.com"

# 根据不同项目模式切换参数
if [[ ${PROJECT_MODE} == "prod" ]]; then
  IMAGE_JEEFREE=${PUSH_IMAGE_CONTAINER_JEEFREE}
  docker login --username=${DOCKER_USERNAME} --password ${DOCKER_PASSWORD} ${PUSH_ROOT_REGISTRY}
fi

# 日志查看
function logs_one() {
    docker logs -f ${PROJECT_NAME}"-"${STATE} --tail 15
}

# 推送一个项目docker到仓库
function push_one() {
  docker tag ${PROJECT_NAME}"-"$1 ${PUSH_ROOT_REGISTRY}/${PROJECT_NAME}/${PROJECT_NAME}"-"$1
  docker push ${PUSH_ROOT_REGISTRY}/${PROJECT_NAME}/${PROJECT_NAME}"-"$1
  docker rmi -f ${PUSH_ROOT_REGISTRY}/${PROJECT_NAME}/${PROJECT_NAME}"-"$1
}

# 启动指定服务
function start_one() {
    # 程序配置文件的正常读取是在该目录下进行的
    case ${STATE} in
        ${COMMAND_MYSQL})
            IMAGE_MYSQL=${IMAGE_MYSQL} IMAGE_CONTAINER_MYSQL=${PROJECT_NAME}"-"${STATE} ROOT_PATH=${ROOT_PATH} docker-compose --log-level ERROR -f "${ROOT_PATH}"/${DOCKER_COMPOSE_FILE} up -d ${PROJECT_NAME}"-"${STATE}
        ;;
        ${COMMAND_MONGO})
            IMAGE_MONGO=${IMAGE_MONGO} IMAGE_CONTAINER_MONGO=${PROJECT_NAME}"-"${STATE} ROOT_PATH=${ROOT_PATH} docker-compose --log-level ERROR -f "${ROOT_PATH}"/${DOCKER_COMPOSE_FILE} up -d ${PROJECT_NAME}"-"${STATE}
        ;;
        ${COMMAND_REDIS})
            IMAGE_REDIS=${IMAGE_REDIS} IMAGE_CONTAINER_REDIS=${PROJECT_NAME}"-"${STATE} ROOT_PATH=${ROOT_PATH} docker-compose --log-level ERROR -f "${ROOT_PATH}"/${DOCKER_COMPOSE_FILE} up -d ${PROJECT_NAME}"-"${STATE}
        ;;
        ${COMMAND_MQ})
            IMAGE_MQ=${IMAGE_MQ} IMAGE_CONTAINER_MQ=${PROJECT_NAME}"-"${STATE} ROOT_PATH=${ROOT_PATH} docker-compose --log-level ERROR -f "${ROOT_PATH}"/${DOCKER_COMPOSE_FILE} up -d ${PROJECT_NAME}"-"${STATE}
        ;;
        ${COMMAND_IPFS})
            IMAGE_IPFS=${IMAGE_IPFS} IMAGE_CONTAINER_IPFS=${PROJECT_NAME}"-"${STATE} ROOT_PATH=${ROOT_PATH} docker-compose --log-level ERROR -f "${ROOT_PATH}"/${DOCKER_COMPOSE_FILE} up -d ${PROJECT_NAME}"-"${STATE}
        ;;
        ${COMMAND_JEEFREE})
            IMAGE_JEEFREE=${IMAGE_JEEFREE} IMAGE_CONTAINER_JEEFREE=${PROJECT_NAME}"-"${STATE} ROOT_PATH=${ROOT_PATH} docker-compose --log-level ERROR -f "${ROOT_PATH}"/${DOCKER_COMPOSE_FILE} up -d ${PROJECT_NAME}"-"${STATE}
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

# 全局释放所有docker环境，当前系统所有镜像都会受到影响
# 不确定则请慎用
function release_all() {
    # 关闭当前系统正在运行的容器，并清除
    docker stop $(docker ps -a | awk '{ print $1}' | tail -n +2)
    docker rm -f $(docker ps -a | awk '{ print $1}' | tail -n +2)

    docker volume ls -qf dangling=true
    # 查看指定的volume
    # docker inspect docker_orderer.example.com

    # 开始清理
    docker volume rm $(docker volume ls -qf dangling=true)
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

# 清理关闭一个指定容器
function release_one() {
  ROOT_PATH=${ROOT_PATH} docker-compose -f "${ROOT_PATH}"/${DOCKER_COMPOSE_FILE} stop ${PROJECT_NAME}"-"$1
  docker-compose -f "${ROOT_PATH}"/${DOCKER_COMPOSE_FILE} rm -f ${PROJECT_NAME}"-"$1
}

function printHelp() {
    echo "./main.sh start [+操作码]：启动服务"
    echo "          [操作码]"
    echo "               指定服务：启动指定服务,当前支持[mysql,redis,mongo,mq,ipfs,jeefree]"
    echo "./main.sh logs [+操作码]：查看日志"
    echo "          [操作码]"
    echo "               指定服务：查看指定日志,当前支持[mysql,redis,mongo,mq,ipfs,jeefree]"
    echo "./main.sh push [+操作码]：推送镜像到仓库"
    echo "          [操作码]"
    echo "               指定服务：推送到指定仓库，当前支持[jeefree]"
    echo "./main.sh release [+操作码]：用于释放项目和其余容器"
    echo "          [操作码]"
    echo "               all：释放项目所有内容，包括各种容器"
    echo "               指定容器名：释放指定容器，主要是用来释放项目所在的容器,当前支持[mysql,redis,mongo,mq,jeefree,ipfs]"
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
