# token

Cakrawala Mesin Digital 的 AI 网关与公司官网基础设施,全部用 Terraform 管理,部署在 AWS。

这个仓库包含两部分:

* **AI 网关栈**(仓库根目录):一台 EC2 服务器,用 Docker 跑 New API(AI 网关)、LobeChat(聊天前台)、Infisical(密钥库)和 Caddy(反向代理)
* **公司官网**(`website/` 和 `website-infra/`):S3 加 CloudFront 的静态站点,以及域名 DNS 和企业邮箱记录

完整的系统说明、架构图、操作手册和已知风险见 [ARCHITECTURE.md](ARCHITECTURE.md)。

> 仓库必须保持私有。文档和配置里含有真实的 AWS 账号信息和服务器地址。

## 目录结构

```
.
  main.tf, variables.tf, outputs.tf   EC2、弹性 IP、安全组、密钥对
  user_data.sh.tpl                    实例首次启动脚本(Docker、Compose、Caddy、swap)
  website/index.html                  官网源码(单文件,印尼语和英文)
  website-infra/                      官网、DNS、邮件记录的 Terraform(独立状态)
  ARCHITECTURE.md                     架构文档
```

## 前置条件

* Terraform 1.5 或更高版本
* AWS CLI,并配置名为 `pd-newapi` 的 profile(`aws configure --profile pd-newapi`)
* 一把本地 SSH 公钥,默认 `~/.ssh/id_ed25519.pub`
* 密钥只输入在你自己的终端或浏览器里,不要写进代码或提交到仓库

## 部署 AI 网关栈

1. 在仓库根目录创建 `terraform.tfvars`(已被 `.gitignore` 忽略),写入你自己的公网 IP:

   ```hcl
   allowed_ssh_cidr = "你的公网IP/32"
   ```

2. 初始化并查看计划,确认没有意外的销毁:

   ```bash
   terraform init
   terraform plan
   ```

3. 创建资源:

   ```bash
   terraform apply
   ```

4. 等待一到两分钟,实例会自动安装 Docker 并启动全部容器。输出里的 `newapi_url` 就是网关地址。
5. 打开网关地址,走完 New API 的初始化向导(设置管理员账号),然后在后台添加渠道(填 OpenAI 或 Anthropic 官方 key)并创建令牌。
6. 用 `curl` 验证调用:

   ```bash
   curl http://<服务器IP>/v1/chat/completions \
     -H "Authorization: Bearer <你的令牌>" \
     -H "Content-Type: application/json" \
     -d '{"model":"<渠道里的模型名>","messages":[{"role":"user","content":"hello"}]}'
   ```

端口说明:80 为 New API,8080 为 LobeChat,9000 为 Infisical(默认只对管理员 IP 开放)。

默认实例是 `m7i-flex.large`。免费计划的 AWS 账号不允许修改实例规格,需要换规格时用 `terraform apply -replace=aws_instance.newapi` 重建。

## 发布官网

官网源码是 `website/index.html`。发布只需要上传页面并刷新缓存:

```bash
cd website-infra
terraform apply -target=aws_s3_object.index
aws cloudfront create-invalidation --profile pd-newapi \
  --distribution-id <分发ID> --paths "/*"
```

分发 ID 可以用 `terraform state show aws_cloudfront_distribution.site` 查到。第一次部署官网需要先把域名的 Name Server 指向 Route 53,详见 [ARCHITECTURE.md](ARCHITECTURE.md) 的第 5 和第 6 节。

## 日常运维

| 要做的事 | 做法 |
|---|---|
| 换了网络,SSH 或 Infisical 打不开 | 修改 `terraform.tfvars` 里的 `allowed_ssh_cidr`,重新 `terraform apply` |
| 查看容器 | SSH 登录后,在 `/opt/newapi` 执行 `sudo docker compose ps` |
| 给 LobeChat 增加模型 | 编辑服务器 `/opt/newapi/.env` 的 `OPENAI_MODEL_LIST`,再 `sudo docker compose up -d --force-recreate lobe-chat` |
| 临时对全网开放 Infisical | `terraform.tfvars` 设 `infisical_public = true`,用完立刻改回 `false` 并 apply |

## 重要提醒

* **没有备份。** New API 和 Infisical 的数据只在服务器系统盘上,建议开启 EBS 快照,并离线备份 `/opt/newapi/.env`(其中的 Infisical 加密密钥丢失后无法恢复数据)。
* **网关目前是明文 HTTP。** 有域名后给 `domain_name` 赋值,Caddy 会自动申请 HTTPS。
* **Terraform 状态文件只在本机**,已被 `.gitignore` 忽略,请自行备份。
* 上游只使用官方 API 平台的 key。ChatGPT Plus、Claude Pro 这类个人订阅不能当 API 使用,不要接入转发。
* New API 采用 AGPL 许可。向公众提供服务前,请先确认所在地的 AI 服务合规要求。

更多风险和待办见 [ARCHITECTURE.md](ARCHITECTURE.md) 的第 9 和第 10 节。
