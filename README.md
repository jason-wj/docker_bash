# docker_bash

#### 介绍
编排了一些常用的docker镜像，脚本中的容器是测试案例，用于参考

#### 软件架构
必须先安装docker和docker-compose

#### 使用前须知
需要将`main.sh`和`docker-compose.yml`中的`flag`改为自定义的项目名称。

#### 支持镜像
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
```
