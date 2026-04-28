# FRPS Docker 部署说明

本目录用于构建并部署 `frps` 服务端容器，当前内容已从早年的 `frp 0.27.1 + 内嵌配置` 方案，升级为基于 **Ubuntu 24.04**、支持 **动态版本号**、**宿主机挂载配置**、**文件日志输出** 的新方案。

---

## 当前目录结构

```text
Frp/
├── Dockerfile
├── compose.yaml
├── frps.toml
├── logs/
└── README.md
```

说明：
- `Dockerfile`：构建 `frps` 镜像
- `compose.yaml`：启动容器
- `frps.toml`：服务端配置文件
- `logs/`：宿主机上的日志目录，映射容器内 `/var/log/frp`

---

## 当前版本说明

### Dockerfile（当前）
- 基础镜像：`ubuntu:24.04`
- 版本变量：`ARG FRP_VERSION=0.68.1`
- 下载方式：`ADD` 直接下载 GitHub Release 压缩包
- 程序目录：`/frp`
- 启动配置：`/etc/frp/frps.toml`

### compose.yaml（当前）
- 容器名：`myfrps-container`
- 网络模式：`host`
- 重启策略：`always`
- 配置文件挂载：`./frps.toml:/etc/frp/frps.toml`
- 日志目录挂载：`./logs:/var/log/frp`

### frps.toml（当前）
- `bindPort = 7000`
- `auth.method = "token"`
- `transport.tls.force = true`
- 日志输出到：`/var/log/frp/frps.log`
- 日志级别：`info`

---

## 本次更新记录

相对于本仓库最早版本（`frp 0.27.1`），本次已完成以下调整：

1. **基础镜像升级**
   - `ubuntu:19.04` → `ubuntu:24.04`

2. **frp 版本升级**
   - 默认版本升级为 `0.68.1`

3. **增加动态版本参数**
   - Dockerfile 支持：`ARG FRP_VERSION=...`
   - Compose 中可通过 `build.args.FRP_VERSION` 传入

4. **配置方式升级**
   - 不再使用镜像内的 `/frp/frps.ini`
   - 改为宿主机挂载 `/etc/frp/frps.toml`

5. **日志方式升级**
   - 不再只依赖容器标准输出
   - 改为写入文件：`/var/log/frp/frps.log`
   - 通过 volume 暴露到宿主机 `./logs/`

6. **部署方式收敛到 compose**
   - 不再以 `docker run -itd ... /bin/bash` 为主
   - 当前推荐使用 `docker compose up -d --build`

---

## 与旧 README 冲突、现已废弃的做法

以下旧说明已不再适用于当前目录：

### 1. 旧版基础镜像说明已过时
旧文中的：
- `ubuntu:19.04`

已更新为：
- `ubuntu:24.04`

### 2. 旧版 frp 版本说明已过时
旧文中的：
- `frp 0.27.1`

已更新为：
- 默认 `frp 0.68.1`

### 3. 旧版配置路径已过时
旧文中的：
- `/frp/frps.ini`

已更新为：
- `/etc/frp/frps.toml`

### 4. 旧版运行方式已不再推荐
旧文中的：
- `docker run -itd ... /bin/bash`
- 再进容器内手工处理

当前不再推荐这样做。现在应直接：
- 准备 `frps.toml`
- 准备 `logs/`
- 使用 `docker compose up -d --build`

### 5. `docker commit` 不再是当前主流程
旧 README 中提到：
- 先跑容器
- 再 `docker commit`

这不是当前推荐流程。当前目录已经具备：
- Dockerfile
- compose.yaml
- 宿主机配置文件

因此应以“**配置即源文件**”的方式维护，不再依赖容器状态反向固化镜像。

---

## 新云主机直接部署说明

以下步骤适用于：
- 一台全新的 Linux 云主机
- 已安装 Docker / Docker Compose
- 准备直接部署当前目录中的 `frps`

---

### 第一步：获取目录内容

将本目录上传到云主机，例如放到：

```bash
/opt/frps
```

目录结构应类似：

```text
/opt/frps
├── Dockerfile
├── compose.yaml
├── frps.toml
└── README.md
```

如果还没有日志目录，后面创建即可。

---

### 第二步：修改配置文件

编辑：

```bash
/opt/frps/frps.toml
```

至少先把下面这一项改掉：

```toml
token = "CHANGE_ME_TO_A_LONG_RANDOM_TOKEN"
```

改成你自己的随机长 token，例如：

```toml
token = "replace-with-your-own-long-random-token"
```

如果你要改监听端口，也在这里修改：

```toml
bindPort = 7000
```

---

### 第三步：创建日志目录

在项目目录下创建日志目录：

```bash
mkdir -p /opt/frps/logs
```

---

### 第四步：检查 compose 中的默认版本号

当前 `compose.yaml` 中默认是：

```yaml
args:
  FRP_VERSION: "0.68.1"
```

如果你要换版本，可直接改这里，例如改成：

```yaml
args:
  FRP_VERSION: "0.68.2"
```

通常没必要改，除非你明确要升级/回退。

---

### 第五步：先确认云主机上有可用的 Compose

当前文档默认使用的是：

```bash
docker compose up -d --build
```

也就是 **Docker Compose v2 插件**。

但实际在一些老云主机或 Ubuntu 系统仓库环境中，常见情况是：
- 只有旧版 `docker-compose` v1
- 或者 `docker compose` 根本不存在
- 或者系统里已经有正在运行的 `docker.io` / containerd / 网络代理环境，不适合为了装 compose 去大改 Docker 包来源

### 推荐的低风险处理方式

如果你的机器上：
- `docker compose` 不可用
- 但现有 Docker Engine 还能正常工作
- 又不想因为补 compose 去动本机 Docker 包体系

那么更稳的做法通常是：**直接安装独立的 `docker-compose` 二进制**，而不是先切 Docker 官方 apt 仓库。

示例：

```bash
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

如有需要，可再补一个软链接：

```bash
sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
```

验证：

```bash
docker-compose --version
```

如果 GitHub 下载较慢，可自行替换为你信任的镜像/加速源。

> [!warning] 不要轻易在已有业务运行的服务器上混改 Docker 包体系
> 如果机器当前使用的是 Ubuntu 系统仓库的 `docker.io`，而你只是缺一个 compose，优先考虑独立二进制方案。直接切换 Docker 官方 apt 仓库、混装 CLI/plugin，虽然在某些环境可行，但也可能影响现有 Docker、网络代理或依赖它们的服务。

### 什么时候用 `docker compose`，什么时候用 `docker-compose`

- 如果你机器上已经有 **Compose v2 插件**：优先用

```bash
docker compose up -d --build
```

- 如果你当前机器上采用的是上面的**独立二进制安装**方式：就直接用

```bash
docker-compose up -d --build
```

两者都能完成当前项目部署，关键是：**先选对你这台机器风险更低的安装方式。**

---

### 第六步：构建并启动

进入目录：

```bash
cd /opt/frps
```

如果你的机器已经具备 Compose v2：

```bash
docker compose up -d --build
```

如果你采用的是上一步的独立二进制方案：

```bash
docker-compose up -d --build
```

说明：
- `--build`：按当前 Dockerfile 重建镜像
- `-d`：后台启动

---

### 第七步：检查容器状态

查看容器：

```bash
docker ps | grep myfrps-container
```

查看日志：

```bash
tail -f /opt/frps/logs/frps.log
```

也可以查看 Docker 日志：

```bash
docker logs -f myfrps-container
```

不过当前主日志方案是文件日志，优先看：

```bash
/opt/frps/logs/frps.log
```

---

### 第八步：云主机安全组 / 防火墙放行端口

至少要确保：

```text
7000/tcp
```

已在云厂商安全组或系统防火墙中放行。

如果你的客户端协议或后续配置使用了更多端口，需要按实际情况继续放行。

---

## frpc 配置示例

下面给一个与当前服务端配置相匹配的 `frpc.toml` 示例。

当前服务端关键配置是：
- `bindPort = 7000`
- `auth.method = "token"`
- `transport.tls.force = true`

所以客户端至少也要：
- 连到服务端公网 IP 或域名
- 端口填 `7000`
- 使用相同的 `token`
- 开启 TLS

### 示例 1：把内网 SSH 暴露到公网

适合场景：
- 家里或公司内网有一台 Linux 机器
- 本地 SSH 监听 `22`
- 希望通过 frp 从公网访问这台机器

```toml
serverAddr = "YOUR_SERVER_IP_OR_DOMAIN"
serverPort = 7000

[auth]
method = "token"
token = "replace-with-the-same-token-as-frps"

[transport]
tls.enable = true

[[proxies]]
name = "ssh"
type = "tcp"
localIP = "127.0.0.1"
localPort = 22
remotePort = 6000
```

说明：
- `serverAddr`：填你的云主机公网 IP 或域名
- `serverPort`：要与服务端 `bindPort` 一致，这里是 `7000`
- `token`：必须与 `frps.toml` 中完全一致
- `tls.enable = true`：要与服务端 `transport.tls.force = true` 对应
- `remotePort = 6000`：表示公网访问云主机 `6000` 端口时，会转发到客户端本机 `22`

如果你要从外部连接这台 SSH，可使用：

```bash
ssh -p 6000 your-user@YOUR_SERVER_IP_OR_DOMAIN
```

同时别忘了在云主机安全组中额外放行：

```text
6000/tcp
```

---

### 示例 2：把本地 Web 服务暴露到公网

适合场景：
- 客户端本地跑着一个 Web 服务
- 例如监听在 `127.0.0.1:8080`
- 希望通过公网访问

```toml
serverAddr = "YOUR_SERVER_IP_OR_DOMAIN"
serverPort = 7000

[auth]
method = "token"
token = "replace-with-the-same-token-as-frps"

[transport]
tls.enable = true

[[proxies]]
name = "web-8080"
type = "tcp"
localIP = "127.0.0.1"
localPort = 8080
remotePort = 8080
```

说明：
- 外部访问云主机 `8080` 端口时，会转发到客户端本机 `127.0.0.1:8080`
- 云主机安全组中也需要放行：

```text
8080/tcp
```

---

### frpc 使用时要特别注意的点

1. **token 必须一致**
   - `frpc.toml` 里的 token 必须与 `frps.toml` 完全相同

2. **TLS 配置必须匹配**
   - 当前服务端强制 TLS：`transport.tls.force = true`
   - 所以客户端要启用：`tls.enable = true`

3. **remotePort 不能冲突**
   - 如果定义多个代理，`remotePort` 不要重复
   - 同一个服务端上多个客户端也要避免抢同一个端口

4. **安全组要放行业务端口**
   - 不仅要放行 `7000/tcp`
   - 还要放行你实际暴露出去的 `remotePort`

5. **客户端本地服务地址要写对**
   - 如果服务就在本机监听，一般填 `127.0.0.1`
   - 如果服务在局域网其他机器上，也可以填对应内网 IP

---

## frpc 客户端使用方法

下面补充客户端最常见的使用方式：
- 手工启动
- 后台运行
- 查看日志
- systemd 自启动

以下示例假设你已经：
- 下载并解压了 frp 客户端
- 当前目录中有 `frpc` 可执行文件
- 已准备好 `frpc.toml`

---

### 1）前台直接启动

适合场景：
- 首次测试配置是否正确
- 先观察连接过程和报错

```bash
./frpc -c ./frpc.toml
```

如果启动成功，通常会看到：
- 成功连接到服务端
- 各个代理注册成功
- 后续保持前台运行

如果报错，优先检查：
- `serverAddr` 是否写对
- `serverPort` 是否可达
- `token` 是否一致
- `tls.enable = true` 是否已开启
- `remotePort` 是否已被占用

---

### 2）后台运行

如果只是临时后台挂着跑，可以：

```bash
nohup ./frpc -c ./frpc.toml > frpc.log 2>&1 &
```

查看进程：

```bash
ps -ef | grep frpc
```

查看日志：

```bash
tail -f frpc.log
```

停止进程：

```bash
pkill -f 'frpc -c ./frpc.toml'
```

说明：
- 这种方式适合临时使用
- 机器重启后不会自动恢复
- 长期运行更推荐用 systemd

---

### 3）客户端配置里直接写日志

如果你希望客户端也像服务端一样把日志写到文件，可以在 `frpc.toml` 中加入：

```toml
[log]
to = "./frpc.log"
level = "info"
maxDays = 7
```

这样启动后，日志会落到当前目录的 `frpc.log`。

如果你想更清晰一点，也可以写绝对路径，例如：

```toml
[log]
to = "/var/log/frp/frpc.log"
level = "info"
maxDays = 7
```

前提是运行用户对该目录有写权限。

---

### 4）systemd 常驻运行（推荐）

如果客户端是 Linux 机器，推荐用 systemd 托管。

假设文件放在：

```text
/opt/frpc/
├── frpc
└── frpc.toml
```

先创建服务文件：

```bash
sudo tee /etc/systemd/system/frpc.service >/dev/null <<'EOF'
[Unit]
Description=FRP Client Service
After=network.target
Wants=network.target

[Service]
Type=simple
WorkingDirectory=/opt/frpc
ExecStart=/opt/frpc/frpc -c /opt/frpc/frpc.toml
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
```

然后执行：

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now frpc
```

查看状态：

```bash
sudo systemctl status frpc
```

查看日志：

```bash
sudo journalctl -u frpc -f
```

重启：

```bash
sudo systemctl restart frpc
```

停止：

```bash
sudo systemctl stop frpc
```

如果后续修改了 `frpc.toml`，通常执行：

```bash
sudo systemctl restart frpc
```

即可生效。

---

### 5）如何确认客户端已经真正可用

客户端启动成功，不代表业务一定可访问。建议按下面顺序验证：

1. **先看 frpc 日志**
   - 是否成功连接到服务端
   - 是否提示 proxy 注册成功

2. **再看服务端日志**
   - `frps.log` 中是否看到了客户端上线
   - 是否有端口占用、认证失败、TLS 错误

3. **最后从外部真实访问**
   - 例如 SSH 场景：

```bash
ssh -p 6000 your-user@YOUR_SERVER_IP_OR_DOMAIN
```

   - 例如 Web 场景：

```bash
curl http://YOUR_SERVER_IP_OR_DOMAIN:8080
```

如果日志正常但外部访问失败，优先排查：
- 云主机安全组
- 系统防火墙
- `remotePort` 是否被其他程序占用
- 客户端本地服务是否真的在监听

---

## 常用运维命令

### 启动 / 更新

```bash
cd /opt/frps
docker compose up -d --build
```

### 停止

```bash
cd /opt/frps
docker compose down
```

### 重启

```bash
cd /opt/frps
docker compose restart
```

### 查看实时日志

```bash
tail -f /opt/frps/logs/frps.log
```

### 查看容器日志

```bash
docker logs -f myfrps-container
```

---

## 当前配置的设计取向

本目录当前走的是一条“尽量简单但比旧版更可维护”的路线：

- 保留 Dockerfile 的极简风格：`ADD + RUN + CMD`
- 保留动态版本参数：`ARG FRP_VERSION`
- 配置文件在宿主机维护
- 日志写文件并映射到宿主机
- 使用 `docker compose` 管理启动

这套方案适合：
- 个人使用
- 机器数量不多
- 希望部署逻辑简单透明
- 后续还需要自己手改配置和看日志

---

## 备注

如果后续要继续增强，可以再考虑：
- 为下载包增加 checksum 校验
- 补充更完整的 `frps.toml` 示例
- 增加客户端 `frpc` 配套说明
- 增加升级/回滚流程说明

但当前这版 README 只以**现有三个文件的真实状态**为准，不额外引入复杂流程。
