# frp

## frps

在云服务器启动 frps

## frpc

本地计算机启动了后台服务, 希望能从公网穿透进来的话, 在本地启动 frpc.

### 修改配置文件

参考 `frpc.toml.template` 模板文件, 进行修改, 主要包括以下几项
- 云服务器公网IP(frps ip)
- 本地需要穿透的后台应用(`name`, `localPort`, `remotePort`)
- 云服务器暴露端口
  - 需要暴露 frps 监听的端口, 具体见 [frps.toml](./frps/frps.toml)
  - 需要暴露 frpc 配置文件 [frpc.toml](./frpc/frpc.toml.template) 中指定的 `remotePort`.

```shell
cd frpc
cp frpc.toml.template frpc.toml
docker-compose up -d
```

### 举例

比如 frpc 所在机器, 启动了后端应用 `app-1` (端口 `8888`)

那么, 我们在 `frpc.toml` 中配置如下, 然后我们便可以借助云服务器(frps所在机器) 穿透进内网, 通过 `http://<frps_ip>:<remotePort>`

```toml
[[proxies]]
name = "app-1"
# 代理类型 有tcp\udp\stcp\p2p
type = "tcp"
# 客户端代理应用IP
localIP = "127.0.0.1"
# 客户端代理应用端口
localPort = 8888
# 服务端反向代理端口；提供给外部访问
remotePort = 8888
```