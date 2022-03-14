# docker_bash
通过docker-compose和shell，简化docker容器管理的一些快捷使用操作（如启动、停止等）。
无论在linux、mac、windows(git bash) 均可以便捷操作docker容器，方便程序猿开发和测试项目。

## 地址
[docker_bash 码云](https://gitee.com/jason-wj/docker_bash)  
[docker_bash Github](https://github.com/jason-wj/docker_bash)

## 软件架构
必须先安装docker和docker-compose

## 使用前须知
默认项目名称为：`x`，不建议修改名称  
如果非要变更名称：则需要将`main.sh`和`docker-compose.yml`中的`x`改为自定义的项目名称

## 使用方式
1. 可以配置环境变量，方便全局快速启动
```shell
# docker 快捷入口
export PATH=/xxx/docker_bash:$PATH
# docker-compose.yml 文件所在目录
export DOCKER_COMPOSE_PATH=/xxx/docker_bash/
```
2. 启动所需镜像
以mariadb为例
```shell
# 启动
main.sh start mariadb

# 查看容器日志
main.sh logs mariadb

# 停止容器
main.sh release mariadb
```

## 支持镜像
```text
mongo       略  
mysql       略  
mariadb     略  
redis       略  
java        略  
nginx       略  
ipfs        星际网络存储协议  
portainer   docker可视化管理  
mq          消息队列  
yapi        接口管理 
python      略
consul      微服务注册和发现，涉及4个容器，集群 consul1、consul2、consul3、consului
etcd        微服务注册和发现，涉及4个容器，集群 etcd1、etcd2、etcd3、etcdui
arbnode     arbitrum节点，可配置连接来变更测试和正式节点
dtf         分布式事务锁
```
