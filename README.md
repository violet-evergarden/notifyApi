# Notify API

一个基于 Express.js 的通知服务 Web API，支持 Docker 部署。

## 功能特性

- ✅ 单一 POST 接口
- ✅ Header API 密钥验证
- ✅ CORS 支持
- ✅ Docker 容器化部署
- ✅ JSON 数据格式

## API 端点

- `POST /sendBot` - 发送消息到 Telegram Bot（需要 API 密钥验证）

## 快速开始

### 使用 Docker 部署

#### 方式1: 使用 .env 文件（推荐）

```bash
# 1. 复制环境变量模板文件
cp env.example .env

# 2. 编辑 .env 文件，填入你的配置
nano .env  # 或使用其他编辑器

# 3. 构建镜像
docker build -t notify-api .

# 4. 运行容器（从 .env 文件加载环境变量，开放端口 8848）
docker run -d -p 8848:8848 \
  --env-file .env \
  --name notify-api \
  --restart unless-stopped \
  notify-api

# 查看日志
docker logs -f notify-api

# 停止容器
docker stop notify-api

# 删除容器
docker rm notify-api

# 重启容器
docker restart notify-api
```

#### 方式2: 直接在命令中设置环境变量

```bash
# 1. 构建镜像
docker build -t notify-api .

# 2. 运行容器（直接在命令中设置环境变量，开放端口 8848）
docker run -d -p 8848:8848 \
  -e API_KEY=f3808faa-8147-41ee-9795-e1c04ddf319e \
  -e NOTIFY_BOT_CHAT_ID=your-chat-id \
  -e NOTIFY_BOT_URL=https://api.telegram.org/bot<your-bot-token>/ \
  --name notify-api \
  --restart unless-stopped \
  notify-api

# 查看日志
docker logs -f notify-api

# 停止容器
docker stop notify-api

# 删除容器
docker rm notify-api

# 重启容器
docker restart notify-api
```

### 服务器一键部署（推荐）

#### 方式1: 使用部署脚本（首次部署）

```bash
# 1. 下载部署脚本（或直接克隆仓库）
git clone https://github.com/violet-evergarden/notifyApi.git
cd notifyApi

# 2. 给脚本添加执行权限
chmod +x deploy.sh

# 3. 运行部署脚本
./deploy.sh
```

脚本会自动：
- ✅ 检查 Docker 和 Git 是否安装
- ✅ 克隆/更新代码仓库
- ✅ 检查并创建 .env 文件（如果不存在）
- ✅ 构建 Docker 镜像
- ✅ 停止并删除旧容器（如果存在）
- ✅ 启动新容器

#### 方式2: 快速部署（已配置好 .env）

```bash
# 如果已经配置好 .env 文件，可以使用快速部署脚本
chmod +x quick-deploy.sh
./quick-deploy.sh
```

#### 方式3: 手动部署

```bash
# 1. 克隆代码仓库
git clone https://github.com/violet-evergarden/notifyApi.git
cd notifyApi

# 2. 复制并编辑环境变量文件
cp env.example .env
nano .env  # 或使用其他编辑器（vi, vim 等）
# 编辑 .env 文件，填入你的实际配置：
#   API_KEY=你的API密钥
#   NOTIFY_BOT_CHAT_ID=你的Chat ID
#   NOTIFY_BOT_URL=https://api.telegram.org/bot<your-bot-token>/

# 3. 构建 Docker 镜像
docker build -t notify-api .

# 4. 运行容器（使用 --env-file 加载 .env 文件，开放端口 8848）
docker run -d -p 8848:8848 \
  --env-file .env \
  --name notify-api \
  --restart unless-stopped \
  notify-api

# 5. 检查容器状态
docker ps

# 6. 查看日志确认服务正常运行
docker logs -f notify-api
```

**注意**：使用 `--env-file .env` 时，Docker 会自动读取 `.env` 文件中的所有环境变量，无需使用 `-e` 参数逐个设置。

### 防火墙配置

确保服务器防火墙开放端口 8848：

```bash
# Ubuntu/Debian (ufw)
sudo ufw allow 8848/tcp
sudo ufw reload

# CentOS/RHEL (firewalld)
sudo firewall-cmd --permanent --add-port=8848/tcp
sudo firewall-cmd --reload

# 或者直接编辑 iptables
sudo iptables -A INPUT -p tcp --dport 8848 -j ACCEPT
```

### 本地开发

```bash
# 复制环境变量模板文件
cp env.example .env

# 编辑 .env 文件，填入你的配置
# 或者直接设置环境变量

# 安装依赖
npm install

# 运行服务
npm start

# 开发模式（自动重启）
npm run dev
```

## 环境变量配置

### 必需的环境变量

- `API_KEY` - API 密钥，用于验证请求（默认值：`f3808faa-8147-41ee-9795-e1c04ddf319e`）
- `NOTIFY_BOT_CHAT_ID` - Telegram Bot 的 Chat ID
- `NOTIFY_BOT_URL` - Telegram Bot API 的 URL（格式：`https://api.telegram.org/bot<your-bot-token>/`）

### 可选的环境变量

- `PORT` - 服务端口（默认值：`8848`）

**生产环境请务必设置强密钥和正确的 Telegram Bot 配置！**

## 示例请求

### 发送消息到 Telegram Bot（使用 X-API-Key header）

```bash
# 本地测试
curl -X POST "http://localhost:8848/sendBot" \
  -H "Content-Type: application/json" \
  -H "X-API-Key: f3808faa-8147-41ee-9795-e1c04ddf319e" \
  -d '{
    "message": "这是一条测试消息"
  }'

# 服务器部署后（替换为你的服务器IP或域名）
curl -X POST "http://your-server-ip:8848/sendBot" \
  -H "Content-Type: application/json" \
  -H "X-API-Key: f3808faa-8147-41ee-9795-e1c04ddf319e" \
  -d '{
    "message": "这是一条测试消息"
  }'
```

### 使用 Authorization header（Bearer Token）

```bash
# 本地测试
curl -X POST "http://localhost:8848/sendBot" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer f3808faa-8147-41ee-9795-e1c04ddf319e" \
  -d '{
    "message": "这是一条测试消息"
  }'

# 服务器部署后（替换为你的服务器IP或域名）
curl -X POST "http://your-server-ip:8848/sendBot" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer f3808faa-8147-41ee-9795-e1c04ddf319e" \
  -d '{
    "message": "这是一条测试消息"
  }'
```

### 请求体格式

```json
{
  "message": "要发送的消息内容（支持 HTML 格式）"
}
```

### 响应示例

**成功响应 (200):**
```json
{
  "success": true,
  "message": "Message sent successfully"
}
```

**错误响应 (400 - 缺少 message 参数):**
```json
{
  "error": "Bad Request",
  "message": "Message parameter is required"
}
```

**错误响应 (401 - 缺少密钥):**
```json
{
  "error": "Unauthorized",
  "message": "API key is required. Please provide X-API-Key header."
}
```

**错误响应 (403 - 密钥无效):**
```json
{
  "error": "Forbidden",
  "message": "Invalid API key."
}
```

**错误响应 (500 - Telegram Bot 配置缺失):**
```json
{
  "error": "Internal Server Error",
  "message": "Telegram Bot configuration is missing"
}
```

## 技术栈

- **Node.js**: JavaScript 运行时
- **Express.js**: Web 框架
- **CORS**: 跨域资源共享
- **Docker**: 容器化部署

## 注意事项

- **必须设置 API_KEY 环境变量**，生产环境请使用强密钥
- **必须设置 NOTIFY_BOT_CHAT_ID 和 NOTIFY_BOT_URL** 环境变量才能正常发送消息
- 支持两种 header 方式传递密钥：
  - `X-API-Key: your-secret-key`
  - `Authorization: Bearer your-secret-key`
- 消息支持 HTML 格式（通过 `parse_mode: "HTML"`）
- Telegram Bot API 调用失败时会被忽略（不抛出异常），但会在日志中记录错误
- **服务端口固定为 8848**，确保服务器防火墙开放此端口
- 生产环境建议添加更多安全措施（如速率限制、HTTPS、Nginx 反向代理等）
- 使用 `--restart unless-stopped` 确保容器自动重启

## Telegram Bot 配置

1. 在 Telegram 中搜索 `@BotFather`，创建新的 Bot 并获取 Token
2. 获取 Chat ID：
   - 发送消息给你的 Bot
   - 访问 `https://api.telegram.org/bot<your-bot-token>/getUpdates`
   - 在返回的 JSON 中找到 `chat.id`
3. 设置环境变量：
   - `NOTIFY_BOT_CHAT_ID`: 你的 Chat ID
   - `NOTIFY_BOT_URL`: `https://api.telegram.org/bot<your-bot-token>/`

## 项目结构

```
notifyApi/
├── app.js              # 主应用文件
├── package.json        # 项目依赖配置
├── Dockerfile          # Docker 镜像构建文件
├── docker-compose.yml  # Docker Compose 配置（可选，如不使用可忽略）
├── env.example         # 环境变量配置模板
├── deploy.sh           # 一键部署脚本（首次部署）
├── quick-deploy.sh     # 快速部署脚本（已配置环境变量）
├── example.js          # Node.js 环境使用示例
├── example-browser.js  # 浏览器环境使用示例
├── .gitignore         # Git 忽略文件
└── README.md          # 项目说明文档
```

## 环境变量文件配置

项目提供了 `env.example` 文件作为环境变量配置模板。使用前请：

1. **复制模板文件**：`cp env.example .env`
2. **编辑 `.env` 文件**，填入你的实际配置值：
   - `API_KEY`: 你的 API 密钥
   - `NOTIFY_BOT_CHAT_ID`: Telegram Bot 的 Chat ID
   - `NOTIFY_BOT_URL`: Telegram Bot API 的 URL
   - `PORT`: 服务端口（可选，默认 8848）
3. **注意**：`.env` 文件已被 `.gitignore` 忽略，不会提交到版本控制，确保敏感信息安全

## JavaScript/Node.js 调用示例

项目提供了 `example.js` 和 `example-browser.js` 作为调用示例。

### Node.js 环境使用

```bash
# 安装 axios（如果还没有）
npm install axios

# 运行示例
node example.js
```

### 基本使用示例

```javascript
const axios = require('axios');

async function sendMessage() {
  try {
    const response = await axios.post(
      'http://localhost:8848/sendBot',
      { message: '这是一条测试消息' },
      {
        headers: {
          'Content-Type': 'application/json',
          'X-API-Key': 'f3808faa-8147-41ee-9795-e1c04ddf319e'
        }
      }
    );
    
    console.log('✅ 消息发送成功:', response.data);
  } catch (error) {
    console.error('❌ 发送失败:', error.response?.data || error.message);
  }
}

sendMessage();
```

### 浏览器环境使用

```html
<!DOCTYPE html>
<html>
<head>
  <script src="https://cdn.jsdelivr.net/npm/axios/dist/axios.min.js"></script>
</head>
<body>
  <script>
    async function sendMessage() {
      try {
        const response = await axios.post(
          'http://your-server-ip:8848/sendBot',
          { message: '这是一条测试消息' },
          {
            headers: {
              'Content-Type': 'application/json',
              'X-API-Key': 'f3808faa-8147-41ee-9795-e1c04ddf319e'
            }
          }
        );
        
        console.log('✅ 消息发送成功:', response.data);
        alert('消息发送成功！');
      } catch (error) {
        console.error('❌ 发送失败:', error.response?.data || error.message);
        alert('消息发送失败：' + (error.response?.data?.message || error.message));
      }
    }
    
    // 调用示例
    sendMessage();
  </script>
</body>
</html>
```

更多示例请查看 `example.js` 和 `example-browser.js` 文件。

