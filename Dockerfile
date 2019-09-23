FROM ubuntu:19.04

LABEL maintainer="sandy1108 <sandy1108@163.com>"

ADD https://github.com/fatedier/frp/releases/download/v0.27.1/frp_0.27.1_linux_amd64.tar.gz /tmp/

RUN tar -xzvf /tmp/frp_0.27.1_linux_amd64.tar.gz -C / \
    && mv /frp_0.27.1_linux_amd64 /frp

CMD /frp/frps -c /frp/frps.ini