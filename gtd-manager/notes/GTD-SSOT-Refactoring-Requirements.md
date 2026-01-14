---
title: GTD Skills SSOT 架构重构需求文档
type: requirement
version: 1.0
date: 2026-01-13
author: Henry WEN
status: draft
tags: [gtd, ssot, architecture, refactoring]
---

# GTD Skills SSOT 架构重构需求文档

## 📋 文档信息

| 项目 | 内容 |
|------|------|
| 文档版本 | 1.0 |
| 创建日期 | 2026-01-13 |
| 负责人 | Henry WEN |
| 系统名称 | GTD Task Management System |
| 重构目标 | 从分布式数据存储迁移到单一数据源（SSOT）架构 |

---

## 🎯 项目概述

### 项目背景

GTD Skills 是一个 AI 驱动的任务管理系统，整合了 Todolist、Calendar、Projects、Notes 等功能。当前系统采用分布式数据存储架构，导致数据一致性问题严重。

### 核心问题

1. **数据一致性缺失**：同一任务在多个文件（calendar.md, inbox.md, projects.md）中以不同状态存在
2. **index.md 形同虚设**：设计为"仪表盘"但从未被使用，完全是空模板
3. **跨文件修改复杂**：修改任务状态需要手动同步多个文件
4. **无法追溯变更**：不清楚任务在何时、何处被修改

### 重构目标

将系统架构从**分布式数据存储**重构为**单一数据源（SSOT）架构**：
- index.md 作为唯一的任务数据源
- 其他文件（calendar.md, inbox.md, projects.md, waiting.md）作为派生视图
- 确保所有任务的增删改查都经过 index.md
- 实现自动数据同步机制

---

## 📊 现状分析

### 当前架构

```
当前架构（分布式）：

用户操作
    ↓
直接写入目标文件
    ├── calendar.md  （独立数据源 1）
    ├── inbox.md     （独立数据源 2）
    ├── projects.md  （独立数据源 3）
    ├── waiting.md   （独立数据源 4）
    └── log.md       （独立数据源 5）

index.md（未被使用）
```

### 存在的问题

#### 问题 1：数据不一致

**场景示例**：
```markdown
# calendar.md (2026-01-13)
| 14:00-15:00 | 准备演讲稿 | #work | ⬜ |  ← 未完成

# inbox.md (Today)
- [x] [P1] 准备演讲稿 #work          ← 已完成

# projects.md (演讲准备项目)
- [ ] 准备演讲稿                     ← 未完成
```

**后果**：用户在不同视图看到矛盾的任务状态

#### 问题 2：跨文件修改遗漏

**场景示例**：
```
用户: "完成了准备演讲稿"
    ↓
Agent 只更新了 calendar.md
    ↓
inbox.md 和 projects.md 仍显示未完成
    ↓
数据不一致
```

#### 问题 3：index.md 完全未被使用

**当前 index.md 内容**：
```markdown
# GTD 仪表盘

## 今日概览

## 本周目标

## 快速操作
```

**实际读取逻辑**（从 SKILL.md）：
- "今日概览" → 理论上读 index.md，但 index.md 是空的
- 实际执行 → 从 calendar.md、inbox.md 等实时汇总
- **结果**：index.md 毫无作用

#### 问题 4：无法追溯历史

**痛点**：
- 不知道任务何时被添加
- 不知道任务何时被完成
- 不知道任务被谁修改（手动 vs Agent）
- log.md 只记录完成事项，无法追溯所有变更

### 当前文件结构

```
gtd-manager/
├── index.md              ❌ 空模板，未被使用
├── memory.md             ✅ 配置文件，正常使用
├── ideas.md              ✅ 灵感笔记
├── SKILL.md              ⚠️  逻辑需重写
│
├── gtd/
│   ├── calendar.md       🔴 独立数据源（问题）
│   ├── inbox.md          🔴 独立数据源（问题）
│   ├── projects.md       🔴 独立数据源（问题）
│   ├── waiting.md        🔴 独立数据源（问题）
│   └── log.md            🟡 只追加日志
│
├── notes/                ✅ 详细笔记
├── archive/              ✅ 归档文件
└── references/           ✅ 参考文档
```

---

## 🎯 用户需求

### 功能性需求

#### FR-1：单一数据源（SSOT）

**需求描述**：
- index.md 必须成为所有任务数据的唯一真实来源
- 所有任务的 CRUD 操作必须先经过 index.md
- 其他文件（calendar, inbox, projects, waiting）作为派生视图

**验收标准**：
- [ ] 所有新增任务首先写入 index.md
- [ ] 修改任务状态时，index.md 首先更新
- [ ] 删除任务时，index.md 中的任务被标记为删除/归档
- [ ] 派生文件的数据完全由 index.md 生成

#### FR-2：自动数据同步

**需求描述**：
- 当 index.md 更新后，自动同步到所有派生文件
- 同步失败不影响 index.md 写入（数据已安全保存）
- 提供手动触发全量重建功能

**验收标准**：
- [ ] 添加任务后，相关派生文件自动更新
- [ ] 完成任务后，所有相关文件的状态同步
- [ ] 同步失败时有明确的错误提示
- [ ] 提供 `rebuild_derived_files()` 函数重建所有派生文件

#### FR-3：数据一致性保证

**需求描述**：
- 同一任务在所有文件中的状态、内容必须一致
- 检测到不一致时，自动提示用户并提供修复选项
- 优先以 index.md 为准（SSOT 原则）

**验收标准**：
- [ ] 每次 Agent 启动时检查数据一致性
- [ ] 发现不一致时，提示用户选择数据源
- [ ] 默认行为：index.md 优先，覆盖派生文件
- [ ] 提供手动合并选项（显示差异）

#### FR-4：完整的变更历史

**需求描述**：
- 记录每个任务的创建时间、更新时间
- 记录任务的完成时间、归档时间
- 保留任务的变更历史（可选）

**验收标准**：
- [ ] 每个任务包含 `created_at` 字段
- [ ] 每个任务包含 `updated_at` 字段
- [ ] 完成的任务记录 `completed_at` 时间
- [ ] 归档的任务保留归档信息

#### FR-5：向后兼容

**需求描述**：
- 现有数据（calendar.md, inbox.md 等）不能丢失
- 提供迁移工具，将现有数据合并到 index.md
- 迁移过程可逆（可回滚）

**验收标准**：
- [ ] 提供迁移脚本 `migrate_to_ssot.py`
- [ ] 迁移前自动备份所有文件
- [ ] 迁移后数据完整性验证
- [ ] 提供回滚脚本（从备份恢复）

### 非功能性需求

#### NFR-1：性能要求

**需求描述**：
- 读取 index.md 的速度：< 1 秒（1000 个任务以内）
- 写入 index.md 的速度：< 2 秒
- 同步到派生文件的速度：< 3 秒

**验收标准**：
- [ ] 性能测试：1000 个任务下读取 < 1s
- [ ] 性能测试：添加任务并同步 < 3s
- [ ] 大数据集优化：分区存储（当前/归档）

#### NFR-2：可用性要求

**需求描述**：
- 用户在 Obsidian 中可以直接查看所有文件
- Markdown 格式友好，易于手动编辑（如需要）
- 支持 Obsidian 的双链、任务查询等特性

**验收标准**：
- [ ] index.md 保持 Markdown + YAML 混合格式
- [ ] 派生文件保持纯 Markdown 格式
- [ ] 支持 Obsidian 的 `[[双链]]` 语法
- [ ] 支持 Dataview 查询（可选）

#### NFR-3：可维护性要求

**需求描述**：
- 代码逻辑清晰，易于理解
- 函数职责单一，易于测试
- 充分的注释和文档

**验收标准**：
- [ ] 核心函数有完整的文档注释
- [ ] 提供单元测试覆盖关键逻辑
- [ ] 提供集成测试覆盖主要场景
- [ ] 提供故障排查指南

---

## 🏗️ 技术方案

### 目标架构

```
目标架构（SSOT）：

用户操作
    ↓
[Step 1] 写入 index.md（SSOT）
    ↓
[Step 2] 同步到派生文件
    ├── calendar.md   （派生视图）
    ├── inbox.md      （派生视图）
    ├── projects.md   （派生视图）
    └── waiting.md    （派生视图）
    ↓
[Step 3] 追加到 log.md（可选）
```

### 数据模型设计

#### index.md 数据结构（核心）

**格式**：Markdown + YAML frontmatter + YAML 任务数据库

```yaml
---
type: gtd_index
version: "3.0"
updated: 2026-01-13 10:00:00
schema_version: "1.0"
---

# GTD Task Database (SSOT)

## 任务数据库

```yaml
tasks:
  - id: "task-2026-01-13-001"
    content: "准备演讲稿"
    category: "#work"
    priority: "P1"
    status: "pending"  # pending | in_progress | completed | cancelled | waiting

    # 时间维度
    schedule:
      type: "time_block"  # time_block | deadline | someday
      date: "2026-01-13"
      time_start: "14:00"
      time_end: "15:00"

    # 项目维度
    project:
      id: "project-presentation"
      name: "演讲准备"

    # 等待维度
    waiting:
      is_waiting: false
      waiting_for: null
      waiting_since: null

    # 时间戳
    created_at: "2026-01-13 09:00:00"
    updated_at: "2026-01-13 09:00:00"

    # 完成信息
    completion:
      completed_at: null
      logged: false

    # 归档信息
    archive:
      archived: false
      archive_week: null
      archive_path: null
```

## 使用说明

此文件是 GTD 系统的**单一数据源（SSOT）**。

- ✅ 所有任务的增删改查都通过此文件
- ✅ 其他文件（calendar, inbox, projects, waiting）是派生视图
- ⚠️ 请勿直接手动编辑派生文件，除非理解同步机制
- 🔧 如需重建派生文件，运行 `rebuild_derived_files()`
```

#### 派生文件格式

**calendar.md（日程视图）**：
```markdown
---
type: calendar_view
source: index.md
sync_mode: auto
last_sync: 2026-01-13 10:00:00
---

# Calendar

## 2026-01-13 星期一

| Time | Event | Category | Status | Task ID |
|------|-------|----------|--------|---------|
| 14:00-15:00 | 准备演讲稿 | #work | ⬜ | task-2026-01-13-001 |

<!--
  ⚠️ 此文件由 Agent 自动同步，请勿手动编辑
  数据来源：index.md
  如需修改，请通过 Agent 或直接编辑 index.md
-->
```

**inbox.md（待办视图）**：
```markdown
---
type: inbox_view
source: index.md
sync_mode: auto
last_sync: 2026-01-13 10:00:00
---

# Inbox

## Today

- [ ] [P1] 准备演讲稿 #work (14:00-15:00) `task-2026-01-13-001`

<!-- Task ID: task-2026-01-13-001 -->
```

### 核心流程设计

#### 写入流程（添加任务）

```
用户: "明天下午2点开会"
    ↓
[Step 1: Context 加载]
→ 执行 bash: pwd, date
→ 读取 memory.md（配置、人物、项目关键词）
    ↓
[Step 2: 任务解析]
→ 解析时间：明天下午2点 → 2026-01-14 14:00-15:00
→ 解析内容：开会
→ 匹配分类：工作时间 → #work
→ 匹配优先级：明天 → P1
→ 匹配项目：无匹配
    ↓
[Step 3: 生成任务对象]
task = {
  id: "task-2026-01-13-002",
  content: "开会",
  category: "#work",
  priority: "P1",
  status: "pending",
  schedule: {
    type: "time_block",
    date: "2026-01-14",
    time_start: "14:00",
    time_end: "15:00"
  },
  created_at: "2026-01-13 10:05:00",
  ...
}
    ↓
[Step 4: 写入 index.md（SSOT）]
→ 读取 index.md
→ 在 tasks 数组中追加新任务
→ 更新 updated 时间戳
→ 写入 index.md
→ 验证写入成功
    ↓
[Step 5: 同步到派生文件]
→ 因为 schedule.type = "time_block" → 同步到 calendar.md
  - 在 2026-01-14 的表格中添加行

→ 因为 date = 明天 → 同步到 inbox.md
  - 在 "## Tomorrow" 区域添加任务

→ 如果有 project.id → 同步到 projects.md
  - 在对应项目的 Todo 列表中添加

→ 如果 waiting.is_waiting = true → 同步到 waiting.md
    ↓
[Step 6: 处理同步失败]
→ 记录失败的文件
→ 提示用户：任务已保存到 index.md，但部分派生文件同步失败
→ 提供 rebuild 选项
    ↓
[Step 7: 返回确认]
✅ 已添加「开会」
   📅 → 2026-01-14 14:00-15:00 (calendar.md)
   📋 → inbox/Tomorrow
```

#### 读取流程（显示 Dashboard）

```
用户: "今天要干啥"
    ↓
[Step 1: 只读 index.md]
→ 读取 index.md（SSOT）
→ 解析 YAML tasks 数组
    ↓
[Step 2: 过滤今日任务]
→ 筛选条件：
  - schedule.date = 今天
  - status ∈ [pending, in_progress]
  - archive.archived = false
    ↓
[Step 3: 按优先级排序]
→ P0 > P1 > P2
→ 同优先级按时间排序
    ↓
[Step 4: 生成 Dashboard]
→ 渲染今日焦点（P0 任务）
→ 渲染今日日程（time_block 任务）
→ 渲染待办清单（所有今日任务）
    ↓
[Step 5: 返回结果]
📋 2026-01-13 星期一 ⏰ 10:05

🎯 今日焦点
  - [ ] [P0] BP解析实现方案

📅 今日日程
  | 14:00-15:00 | 准备演讲稿 | #work | ⬜ |

📋 待办清单
  - [ ] [P1] 准备演讲稿 #work
  - [ ] [P1] 整理日程 #work
```

#### 更新流程（完成任务）

```
用户: "完成了准备演讲稿"
    ↓
[Step 1: 定位任务]
→ 在 index.md 中搜索
→ 匹配条件：content 包含 "准备演讲稿"
→ 找到 task-2026-01-13-001
    ↓
[Step 2: 更新 index.md（SSOT）]
→ 修改字段：
  - status = "completed"
  - completion.completed_at = "2026-01-13 15:30:00"
  - updated_at = "2026-01-13 15:30:00"
→ 写入 index.md
    ↓
[Step 3: 同步到所有派生文件]
→ calendar.md: 状态改为 ✅
→ inbox.md:
  - 从 "## Today" 移除
  - 添加到 "## Completed Today"
→ projects.md: 标记为 [x]
    ↓
[Step 4: 记录到 log.md]
→ 在 log.md 今日区域添加：
  - 15:30 ✅ 准备演讲稿 #work
→ 更新 index.md:
  - completion.logged = true
    ↓
[Step 5: 返回确认]
✅ 已完成「准备演讲稿」
🎉 干得漂亮！今天已完成 3 件事
```

### 一致性检查机制

#### 启动时检查

```python
def check_consistency_on_startup():
    """每次 Agent 启动时执行"""

    # 1. 读取 index.md
    index_tasks = read_index_md()

    # 2. 读取派生文件
    calendar_tasks = parse_calendar_md()
    inbox_tasks = parse_inbox_md()
    projects_tasks = parse_projects_md()

    # 3. 对比一致性
    conflicts = []

    for task in index_tasks:
        # 检查 calendar.md
        if task.schedule.type == "time_block":
            calendar_task = find_in_calendar(task.id, calendar_tasks)
            if not calendar_task:
                conflicts.append({
                    "type": "missing",
                    "file": "calendar.md",
                    "task": task
                })
            elif calendar_task.status != task.status:
                conflicts.append({
                    "type": "status_mismatch",
                    "file": "calendar.md",
                    "task": task,
                    "index_status": task.status,
                    "file_status": calendar_task.status
                })

        # 检查 inbox.md（同理）
        # 检查 projects.md（同理）

    # 4. 处理冲突
    if conflicts:
        return prompt_user_to_resolve(conflicts)

    return {"status": "consistent"}
```

#### 冲突解决流程

```
检测到冲突
    ↓
[提示用户]
⚠️ 检测到数据不一致：

任务：准备演讲稿
- index.md 状态：pending
- calendar.md 状态：completed

请选择以哪个为准：
1. 保留 index.md（推荐，SSOT 原则）
2. 保留 calendar.md → 同步回 index.md
3. 手动合并 → 查看详细差异
    ↓
[用户选择]
    ↓
[执行同步]
→ 选项 1：覆盖 calendar.md
→ 选项 2：更新 index.md，然后同步所有派生文件
→ 选项 3：显示差异，等待用户编辑 index.md
```

### 归档流程

```
触发条件：
- 手动：用户说 "归档本周任务"
- 自动：每周一提示

    ↓
[Step 1: 筛选归档任务]
→ 从 index.md 中筛选：
  - status = "completed"
  - completion.completed_at < 本周开始
  - archive.archived = false
    ↓
[Step 2: 标记归档]
→ 更新任务字段：
  - archive.archived = true
  - archive.archive_week = "2026-W02"
  - archive.archive_path = "archive/2026-W02/tasks.md"
    ↓
[Step 3: 导出归档文件]
→ 将归档任务导出到 archive/2026-W02/tasks.md
→ 归档 log.md → archive/2026-W02/log.md
    ↓
[Step 4: 重建派生文件]
→ 调用 rebuild_derived_files()
→ 清理已归档任务
    ↓
[Step 5: 更新归档索引]
→ 更新 archive/index.yaml
```

---

## 📅 实施计划

### 阶段划分

#### Phase 1：数据模型设计与验证（2 天）

**任务清单**：
- [ ] 设计 index.md 的 YAML 数据结构
- [ ] 设计派生文件的格式
- [ ] 编写数据模型验证脚本
- [ ] 创建示例数据进行测试

**交付物**：
- `index.md` 数据结构文档
- 派生文件格式文档
- 数据验证脚本

#### Phase 2：核心函数开发（3 天）

**任务清单**：
- [ ] 实现 `read_index_md()` - 读取 index.md
- [ ] 实现 `write_to_index_md(task)` - 写入 index.md
- [ ] 实现 `sync_to_calendar(task)` - 同步到 calendar.md
- [ ] 实现 `sync_to_inbox(task)` - 同步到 inbox.md
- [ ] 实现 `sync_to_projects(task)` - 同步到 projects.md
- [ ] 实现 `sync_to_waiting(task)` - 同步到 waiting.md
- [ ] 实现 `sync_to_derived_files(task)` - 统一同步函数
- [ ] 实现 `check_consistency()` - 一致性检查
- [ ] 实现 `rebuild_derived_files()` - 重建派生文件

**交付物**：
- 核心函数代码
- 单元测试

#### Phase 3：SKILL.md 逻辑重写（2 天）

**任务清单**：
- [ ] 重写"写入路由"部分
- [ ] 重写"读取路由"部分
- [ ] 添加一致性检查流程
- [ ] 添加错误处理逻辑
- [ ] 更新文件结构说明

**交付物**：
- 新版 SKILL.md
- 逻辑流程图

#### Phase 4：迁移工具开发（1 天）

**任务清单**：
- [ ] 开发 `migrate_to_ssot.py` 迁移脚本
- [ ] 开发数据收集函数（从现有文件读取）
- [ ] 开发数据合并函数（去重、冲突解决）
- [ ] 开发备份函数
- [ ] 开发回滚函数
- [ ] 测试迁移脚本

**交付物**：
- `migrate_to_ssot.py` 迁移脚本
- 迁移操作手册

#### Phase 5：测试与验证（2 天）

**任务清单**：
- [ ] 单元测试：核心函数
- [ ] 集成测试：添加任务
- [ ] 集成测试：完成任务
- [ ] 集成测试：跨文件同步
- [ ] 集成测试：一致性检查
- [ ] 性能测试：1000 个任务
- [ ] 压力测试：并发操作
- [ ] 用户验收测试

**交付物**：
- 测试报告
- Bug 修复记录

#### Phase 6：正式迁移与上线（1 天）

**任务清单**：
- [ ] 备份所有现有数据
- [ ] 执行迁移脚本
- [ ] 验证迁移结果
- [ ] 更新文档
- [ ] 用户培训

**交付物**：
- 迁移报告
- 用户手册

### 时间线

```
总计：11 天

Week 1 (Day 1-5):
  Day 1-2: Phase 1 - 数据模型设计
  Day 3-5: Phase 2 - 核心函数开发

Week 2 (Day 6-10):
  Day 6-7: Phase 3 - SKILL.md 重写
  Day 8:   Phase 4 - 迁移工具开发
  Day 9-10: Phase 5 - 测试验证

Week 3 (Day 11):
  Day 11: Phase 6 - 正式迁移上线
```

---

## ✅ 验收标准

### 功能验收

#### AC-1：添加任务

**测试用例**：
```
用户输入：明天下午2点开会
期望结果：
  ✓ index.md 中新增任务
  ✓ calendar.md 中出现日程
  ✓ inbox.md/Tomorrow 中出现待办
  ✓ 所有文件的任务内容一致
```

#### AC-2：完成任务

**测试用例**：
```
用户输入：完成了开会
期望结果：
  ✓ index.md 中任务状态 = completed
  ✓ calendar.md 中状态 = ✅
  ✓ inbox.md 中任务移到 Completed Today
  ✓ log.md 中记录完成时间
```

#### AC-3：跨文件同步

**测试用例**：
```
场景：任务既有日程，又关联项目
期望结果：
  ✓ index.md 中只有一条记录
  ✓ calendar.md 中显示日程
  ✓ projects.md 中显示项目待办
  ✓ 完成任务时，所有地方同步更新
```

#### AC-4：一致性检查

**测试用例**：
```
场景：手动编辑 calendar.md，将任务标记为完成
期望结果：
  ✓ Agent 启动时检测到冲突
  ✓ 提示用户选择数据源
  ✓ 选择 index.md 后，calendar.md 被覆盖
  ✓ 选择 calendar.md 后，index.md 被更新，其他文件同步
```

#### AC-5：迁移

**测试用例**：
```
场景：从旧系统迁移到 SSOT
期望结果：
  ✓ 所有现有任务都迁移到 index.md
  ✓ 任务数量一致（迁移前 = 迁移后）
  ✓ 任务内容完整（无数据丢失）
  ✓ 派生文件重新生成
```

### 性能验收

| 指标 | 要求 | 实际 |
|------|------|------|
| 读取 index.md（1000 任务） | < 1 秒 | __ |
| 写入 index.md | < 2 秒 | __ |
| 同步到派生文件 | < 3 秒 | __ |
| 一致性检查 | < 2 秒 | __ |
| 重建所有派生文件 | < 5 秒 | __ |

### 文档验收

- [ ] 用户手册完整
- [ ] API 文档完整
- [ ] 迁移指南完整
- [ ] 故障排查指南完整

---

## ⚠️ 风险与缓解措施

### 风险 1：数据丢失

**风险描述**：迁移过程中可能丢失现有数据

**影响等级**：🔴 高

**缓解措施**：
- 迁移前完整备份所有文件
- 提供数据验证脚本（对比迁移前后任务数量）
- 提供回滚脚本（从备份恢复）
- 双写验证期（保留旧系统 2 周）

### 风险 2：性能问题

**风险描述**：YAML 数据量大时读写性能下降

**影响等级**：🟡 中

**缓解措施**：
- 性能测试（1000、5000、10000 任务）
- 分区存储（当前任务 vs 归档任务）
- 建立索引（按日期、项目、状态）
- 懒加载（只加载活跃任务）

### 风险 3：用户习惯改变

**风险描述**：用户习惯直接编辑 calendar.md 等文件

**影响等级**：🟡 中

**缓解措施**：
- 在派生文件顶部添加明显警告
- 一致性检查会自动检测手动修改
- 提供用户培训文档
- 提供手动同步工具

### 风险 4：同步失败

**风险描述**：写入 index.md 成功，但同步到派生文件失败

**影响等级**：🟢 低

**缓解措施**：
- index.md 写入成功是关键（数据不会丢）
- 同步失败时明确提示用户
- 提供手动重建功能 `rebuild_derived_files()`
- Agent 启动时自动检测并修复

### 风险 5：Obsidian 兼容性

**风险描述**：YAML 格式可能影响 Obsidian 的某些功能

**影响等级**：🟢 低

**缓解措施**：
- 保持 Markdown + YAML frontmatter 混合格式
- 派生文件保持纯 Markdown
- 测试 Obsidian 双链、任务查询等功能
- 提供 Dataview 查询示例（可选）

---

## 📚 参考资料

### 相关文档

- [[SKILL.md]] - 当前系统逻辑
- [[references/memory-guide.md]] - 记忆功能指南
- [[references/templates.md]] - 回顾模板

### 技术参考

- YAML 规范：https://yaml.org/spec/1.2.2/
- Obsidian 文档：https://help.obsidian.md/
- GTD 方法论：《Getting Things Done》by David Allen

### 设计决策记录

| 日期 | 决策 | 理由 |
|------|------|------|
| 2026-01-13 | 采用 SSOT 架构 | 解决数据一致性问题 |
| 2026-01-13 | index.md 使用 YAML 存储任务 | 结构化数据便于操作 |
| 2026-01-13 | 派生文件保持 Markdown | 保持 Obsidian 可读性 |
| 2026-01-13 | 优先以 index.md 为准 | SSOT 原则 |

---

## 📝 变更历史

| 版本 | 日期 | 作者 | 变更内容 |
|------|------|------|----------|
| 1.0 | 2026-01-13 | Henry WEN | 初始版本，完成需求分析和技术方案设计 |

---

## 📞 联系方式

- **项目负责人**：Henry WEN
- **技术支持**：请在 GitHub Issues 中提问
- **文档位置**：`/Users/henry/Library/Mobile Documents/iCloud~md~obsidian/Documents/Wen/05_Purvar/00 Inbox/.claude/skills/gtd-manager/notes/`

---

**备注**：本文档为 GTD Skills SSOT 架构重构的核心需求文档，所有开发和测试工作都应以本文档为准。
