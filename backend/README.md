# 时光家项目后端服务

## 项目结构

```
backend/
├── src/
│   ├── config/         # 配置文件
│   ├── controllers/     # 控制器
│   ├── middleware/      # 中间件
│   ├── models/          # 数据模型
│   │   ├── mysql/       # MySQL模型
│   │   └── mongodb/     # MongoDB模型
│   ├── routes/          # 路由
│   ├── services/        # 业务逻辑
│   ├── utils/           # 工具函数
│   ├── workers/         # 工作进程
│   ├── queues/          # 消息队列
│   └── app.js          # 应用入口
├── tests/              # 测试文件
├── scripts/            # 脚本文件
├── package.json        # 项目配置
├── .env                # 环境变量
├── .env.example        # 环境变量示例
└── README.md           # 项目说明
```

## 技术栈

- Node.js 18.17.0 LTS
- Express.js 4.18.2
- MySQL 8.0.34
- MongoDB 6.0.12
- Redis 7.0.15
- JWT 9.0.2

## 环境变量

复制 `.env.example` 文件为 `.env` 并根据实际情况修改配置：

```bash
cp .env.example .env
```

## 安装依赖

```bash
npm install
```

## 启动服务

### 开发模式

```bash
npm run dev
```

### 生产模式

```bash
npm start
```

## API 接口

### 认证接口

- `POST /api/v1/auth/register` - 用户注册
- `POST /api/v1/auth/login` - 用户登录
- `PUT /api/v1/auth/password` - 修改密码
- `GET /api/v1/auth/profile` - 获取用户信息

### 健康检查

- `GET /api/v1/health` - 健康检查

## 数据库初始化

1. 确保 MySQL 服务已启动
2. 创建数据库：`CREATE DATABASE timehouse`
3. 执行数据库初始化脚本：

```bash
node scripts/initDb.js
```

## 测试

```bash
npm test
```

## 代码检查

```bash
npm run lint
```

## 注意事项

- 本项目使用 JWT 进行认证，token 有效期为 7 天
- 密码使用 bcrypt 加密存储
- 所有 API 接口都有速率限制，防止恶意请求
- 错误处理采用统一的格式

## 部署

本项目支持部署到火山引擎 SCF 或容器服务。