FROM ubuntu:24.04

LABEL maintainer="sandy1108 <sandy1108@163.com>"

ARG FRP_VERSION=0.68.1

ADD https://github.com/fatedier/frp/releases/download/v${FRP_VERSION}/frp_${FRP_VERSION}_linux_amd64.tar.gz /tmp/

RUN tar -xzvf /tmp/frp_${FRP_VERSION}_linux_amd64.tar.gz -C / \
    && mv /frp_${FRP_VERSION}_linux_amd64 /frp \
    && mkdir -p /etc/frp /var/log/frp

CMD /frp/frps -c /etc/frp/frps.toml
