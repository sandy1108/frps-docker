## 以Dockerfile脚本的形式制作Docker镜像

### 制作步骤

1. 下载ubuntu基础镜像(这里采用了19.04版)

```
docker pull ubuntu:19.04
```

2. 查看本地镜像列表

```
docker image ls -a
```

```
docker images
```

3. 编写Dockerfile

```
FROM ubuntu:19.04

LABEL maintainer="sandy1108 <sandy1108@163.com>"

ADD https://github.com/fatedier/frp/releases/download/v0.27.1/frp_0.27.1_linux_amd64.tar.gz /tmp/

RUN tar -xzvf /tmp/frp_0.27.1_linux_amd64.tar.gz -C / \
    && mv /frp_0.27.1_linux_amd64 /frp

CMD /frp/frps -c /frp/frps.ini
```

4. 构建镜像

```
docker build -t frps:0.27.1
```

## 由镜像生成容器

1. 运行镜像到容器

```
docker run -itd -p [要映射到的宿主机端口]:[容器内需要被映射服务端口] --name [要新建的容器ID或名称] [镜像ID或名称] /bin/bash
```

其中，d参数代表后台运行容器，返回容器ID；不添加d参数，则会在当前会话执行容器的CMD。

例如：

```
docker run -itd -p 9191:7000 -p 9191:7000/udp --name myfrp-test-08 frps:0.27.1
```

## 进入容器

```
docker exec -it [container名称或者ID] /bin/bash
```

## 附：以容器当前状态保存为镜像（一般是测试或者备份使用）

1. 命令解释

```
# docker commit [OPTIONS] CONTAINER [REPOSITORY[:TAG]]

-a :提交的镜像作者；
-c :使用Dockerfile指令来创建镜像；
-m :提交时的说明文字；
-p :在commit时，将容器暂停。
```

2. 示例

```
docker commit -a "zhangyipeng" -m "just for test" container_ID_OR_NAME ImageName:tagv1
```

3. 查看镜像会发现本地多了一个镜像

```
docker images
```

