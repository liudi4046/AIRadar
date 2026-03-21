# MVP 执行报告

**执行时间**：2026-03-22 ~00:00 - ~01:00 (约 1 小时)
**分支**：feat/mvp-implementation
**执行方式**：Subagent-Driven Development（自动化执行，无人工确认）

## 完成的 Task

| Task | 描述 | Commit |
|------|------|--------|
| Task 1 | 初始化 Python 后端项目 (FastAPI + 依赖) | `2d149f2` |
| Task 2 | 配置模块 (pydantic-settings, Qwen3.5 双模型) | `905869f` |
| Task 3 | Pydantic 数据模型 (Entity, Post) | `b3783c9` |
| Task 4 | Supabase Schema & 数据库客户端 | `6fd7d30` |
| Task 5 | 种子数据 (15 个核心实体) | `59eb619` |
| Task 6 | RSSHub 抓取模块 | `3f6eb93` |
| Task 7 | AI 内容审核模块 (Qwen3.5-Flash) | `95aed2b` |
| Task 8 | AI 内容生成模块 (Qwen3.5-Plus) | `a188052` |
| Task 9 | Pipeline 编排器 | `53190f7` |
| Task 10 | Pipeline CLI 运行脚本 | `ea84449` |
| Task 11 | 实体 API 端点 (列表/过滤/详情) | `ab2cf62` |
| Task 12 | 帖子 API 端点 (时间线/热门/实体帖/详情) | `56ce3fd` |
| Task 13 | 初始化 Flutter 项目 | `b705991` |
| Task 14 | Flutter 数据层 (模型 + API 客户端) | `5f67b9a` |
| Task 15 | Flutter App Shell (路由 + Tab 导航) | `b72e475` |
| Task 16 | 时间线页面 (Tab 1) | `2d19546` |
| Task 17 | 发现页面 (Tab 2) | `a077deb` |
| Task 18 | 帖子详情页 | `326e64c` |
| Task 19 | 实体专属页面 | `2f5e16a` |
| Task 20 | 个人中心页面 (Tab 3) | `3952c22` |
| Task 21 | Docker Compose (RSSHub) | `071fb08` |
| Task 22 | 后端 Dockerfile & 部署配置 | `1aef175` |
| Task 23 | Cron 定时任务配置 | `18864d5` |
| Task 25 | README 文档 | `1ad944d` |
| — | Code Review 修复 (2 个关键问题) | `ee9a44b` |

## 跳过的 Task

| Task | 描述 | 原因 |
|------|------|------|
| Task 24 | 端到端冒烟测试 | ⏭️ 需要活跃的 Supabase、RSSHub、API 服务才能运行 |

## 测试结果

### 后端 (Python)
- **19 个测试全部通过** ✅
- 覆盖：配置、数据库客户端、数据模型、RSS 抓取器、AI 审核、AI 生成、Pipeline 编排器、实体 API、帖子 API
- 运行命令：`cd backend && source .venv/bin/activate && python -m pytest tests/ -v`

### 前端 (Flutter)
- **2 个测试全部通过** ✅
- 覆盖：Entity.fromJson、Post.fromJson
- 运行命令：`cd client && flutter test`

## Code Review 发现及修复

### 已修复的关键问题
1. **RSS 源字段不匹配**：fetcher 使用 `source['path']`（相对路径），但种子数据使用 `source['url']`（绝对 URL）。修复：fetcher 现在同时支持 `path` 和 `url` 两种格式。
2. **默认订阅实体 ID 不匹配**：Flutter 默认订阅使用 `'karpathy'`，但种子数据中 ID 为 `'andrej-karpathy'`。修复：更正为正确的 ID。
3. **热点推荐开关未连接到时间线**：ProfileScreen 有开关但 TimelineScreen 不读取它。修复：将 provider 移至共享位置，时间线根据开关决定是否加载热点。

### 未修复的重要问题（建议后续处理）
1. **订阅状态未持久化到 SharedPreferences**：应用重启后订阅状态会重置
2. **`_buildAvatar` 辅助函数在 4 个文件中重复**：应提取为共享组件
3. **`lru_cache` 在 `get_settings()` 上可能影响测试隔离**：建议使用 `conftest.py` 全局清理
4. **CORS 在生产环境完全开放**：应根据环境变量配置
5. **Pipeline 串行处理所有实体**：建议使用 `asyncio.gather` 提升性能
6. **缺少 `backend/.dockerignore`**：Docker 镜像会包含不必要的文件

### 次要问题
1. `Post.published_at` 是 `str` 而非 `datetime`
2. 缺少 `conftest.py` 共享 pytest fixtures
3. Post ID 截断为 16 字符有小概率碰撞
4. `shimmer` 依赖未使用
5. entities 表缺少 `updated_at` 自动更新触发器

## 环境信息

| 项目 | 版本/状态 |
|------|----------|
| Python | 3.12.13 (via uv) |
| Flutter | 3.41.5 |
| Dart | 3.11.3 |
| Git 分支 | feat/mvp-implementation |
| 总 Commits | 26 (含初始 + code review fix) |

## 用户醒来后需要做的事

1. **配置 Supabase**：创建项目，在 SQL Editor 中运行 `backend/scripts/init_schema.sql`，将凭据填入 `backend/.env`
2. **配置阿里云百炼 API**：获取 Qwen API Key，填入 `backend/.env`
3. **运行种子脚本**：`cd backend && source .venv/bin/activate && python scripts/seed_entities.py`
4. **启动 RSSHub**：`cd infra && docker-compose up -d rsshub`
5. **启动后端**：`cd backend && source .venv/bin/activate && uvicorn src.main:app --reload --port 8000`
6. **运行 Pipeline**：`cd backend && python scripts/run_pipeline.py`
7. **启动 Flutter App**：`cd client && flutter run`
8. **Review 代码**：检查 `feat/mvp-implementation` 分支，确认后合并到 main
9. **处理未修复的重要问题**（可选，上面列出的 6 项）
10. **添加 SharedPreferences 持久化**（订阅状态在应用重启后会丢失）
