---
stepsCompleted: ['step-01-validate-prerequisites', 'step-02-design-epics', 'step-03-create-stories', 'step-04-final-validation']
status: 'complete'
inputDocuments: ['_bmad-output/planning-artifacts/prd.md', '_bmad-output/planning-artifacts/architecture.md']
totalEpics: 6
totalStories: 33
completedDate: '2026-01-14'
---

# ai_assistance - Epic Breakdown

## Overview

This document provides the complete epic and story breakdown for ai_assistance, decomposing the requirements from the PRD and Architecture into implementable stories.

## Requirements Inventory

### Functional Requirements

**FR1: 快速捕获组件 (Quick Capture)**
- FR1.1: 全局快捷键唤起捕获窗口 (P0)
- FR1.2: Dock 栏图标点击唤起 (P0)
- FR1.3: 菜单栏图标点击唤起 (P1)
- FR1.4: 空白输入框，支持文本粘贴 (P0)
- FR1.5: 支持截图粘贴 Cmd+V (P0)
- FR1.6: 回车键确认发送 (P0)
- FR1.7: 发送后显示反馈 (P0)

**FR2: AI 解析引擎**
- FR2.1: 自动分类到三大容器 (P0)
- FR2.2: 自然语言时间解析 (P0)
- FR2.3: 自动推荐优先级 (P1)
- FR2.4: 智能关联相关内容 (P2)
- FR2.5: 截图 OCR 识别 (P1)

**FR3: 三大容器系统**
- FR3.1: 日历容器 (P0)
- FR3.2: Todo 容器 (P0)
- FR3.3: 笔记容器 (P0)
- FR3.4: 跨容器一键转化 (P1)
- FR3.5: Time Sheet 自动生成 (P2)

**FR4: Memory 记忆系统**
- FR4.1: 存储分类偏好规则 (P1)
- FR4.2: 存储人际关系 (P2)
- FR4.3: 存储常用信息 (P2)
- FR4.4: Memory 优化分类 (P1)

**FR5: 视图与展示**
- FR5.1: 日历三维视图 (P1)
- FR5.2: 成就可视化 (P1)
- FR5.3: 今日概览 (P1)
- FR5.4: 批量处理模式 (P1)

### NonFunctional Requirements

**NFR1: 性能**
- NFR1.1: 快捷键响应时间 < 200ms
- NFR1.2: 输入确认到反馈 < 2s（含 AI 分类）
- NFR1.3: 应用启动时间 < 3s
- NFR1.4: 内存占用 < 200MB

**NFR2: 可用性 (ADHD 专属)**
- NFR2.1: 零学习曲线，首次使用无需教程
- NFR2.2: 操作步骤最小化 ≤ 3 步
- NFR2.3: 视觉干扰最小化
- NFR2.4: 容错设计，AI 分类错误可一键纠正

**NFR3: 可靠性**
- NFR3.1: 数据不丢失，发送即保存
- NFR3.2: 离线可用，联网后同步
- NFR3.3: 崩溃恢复，未发送内容自动恢复

**NFR4: 安全与隐私**
- NFR4.1: 数据本地优先
- NFR4.2: AI 调用可控
- NFR4.3: 无账号可用

**NFR5: 兼容性**
- NFR5.1: macOS 14+（SwiftData 要求）
- NFR5.2: Apple Silicon 原生支持
- NFR5.3: Intel Mac 兼容

### Additional Requirements

**从 Architecture 提取的技术需求：**

**项目初始化：**
- 使用 SwiftUI + XcodeGen 初始化项目
- 安装依赖：`brew install xcodegen`
- 添加 SPM 依赖：KeyboardShortcuts, OpenAI (MacPaw)

**数据架构：**
- SwiftData + CloudKit 实现数据持久化和同步
- 图片存储使用 iCloud Drive 容器
- API Key 使用 Keychain 安全存储

**LLM 集成：**
- OpenAI SDK 兼容层
- Dashscope (阿里云) 作为后端
- 离线时队列缓存，联网后处理

**OCR 集成：**
- Apple Vision Framework
- 支持中文识别

**系统集成：**
- KeyboardShortcuts 库处理全局快捷键
- MenuBarExtra 处理菜单栏常驻
- AppDelegate 处理系统事件

**架构模式：**
- Feature-based + Shared 目录结构
- MVVM 模式（@Observable + @State）
- AIAssistantError 统一错误枚举
- async/await 异步处理

### FR Coverage Map

| FR | Epic | 说明 |
|----|------|------|
| FR1.1 | Epic 2 | 全局快捷键唤起 |
| FR1.2 | Epic 2 | Dock 图标唤起 |
| FR1.3 | Epic 2 | 菜单栏图标唤起 |
| FR1.4 | Epic 2 | 文本粘贴 |
| FR1.5 | Epic 2 | 截图粘贴 |
| FR1.6 | Epic 2 | 回车确认 |
| FR1.7 | Epic 2 | 反馈提示 |
| FR2.1 | Epic 4 | 自动分类 |
| FR2.2 | Epic 4 | 时间解析 |
| FR2.3 | Epic 4 | 优先级推荐 |
| FR2.4 | Epic 6 | 智能关联 |
| FR2.5 | Epic 5 | OCR 识别 |
| FR3.1 | Epic 3 | 日历容器 |
| FR3.2 | Epic 3 | Todo 容器 |
| FR3.3 | Epic 3 | 笔记容器 |
| FR3.4 | Epic 3 | 跨容器转化 |
| FR3.5 | Epic 5 | Time Sheet 自动生成 |
| FR4.1 | Epic 6 | 分类偏好规则 |
| FR4.2 | Epic 6 | 人际关系存储 |
| FR4.3 | Epic 6 | 常用信息存储 |
| FR4.4 | Epic 6 | Memory 优化分类 |
| FR5.1 | Epic 5 | 日历三维视图 |
| FR5.2 | Epic 5 | 成就可视化 |
| FR5.3 | Epic 5 | 今日概览 |
| FR5.4 | Epic 3 | 批量处理模式 |

**覆盖率：** 25/25 FRs (100%)

## Epic List

### Epic 1: 项目基础与数据架构

**用户价值：** 可运行的应用骨架，数据模型就绪，为后续功能提供基础

**FRs 覆盖：** 基础架构（无直接 FR，但是所有 FR 的前提）

**技术要求：**
- SwiftUI + XcodeGen 项目初始化
- SwiftData 数据模型定义
- MenuBarExtra 菜单栏常驻
- 基础 Service 层骨架

---

### Epic 2: 快速捕获核心

**用户价值：** 快捷键 → 粘贴(文本/截图) → 回车 → 反馈，全流程 <3 秒

**FRs 覆盖：** FR1.1, FR1.2, FR1.3, FR1.4, FR1.5, FR1.6, FR1.7

**关键特性：**
- 全局快捷键唤起（任何应用下可触发）
- Dock 图标 + 菜单栏图标唤起
- 文本和截图统一粘贴入口
- 回车确认，反馈提示后自动消失
- 捕获后用户继续工作（不打断）

---

### Epic 3: 容器管理与展示

**用户价值：** 用户可浏览、编辑、管理三大容器中的内容，批量处理 AI 分类结果

**FRs 覆盖：** FR3.1, FR3.2, FR3.3, FR3.4, FR5.4

**关键特性：**
- 捕获列表视图（查看所有捕获）
- 日历/Todo/笔记三大容器 CRUD
- 跨容器一键转化
- 批量处理模式（审核 AI 分类）
- 菜单栏徽章（可选，默认关闭）

---

### Epic 4: AI 智能分类

**用户价值：** 捕获内容自动分类到正确容器，用户无需手动选择

**FRs 覆盖：** FR2.1, FR2.2, FR2.3

**关键特性：**
- 文本自动分类到三大容器
- 自然语言时间解析（中文友好）
- 优先级自动推荐（重要/普通）
- 离线队列，联网后处理

---

### Epic 5: OCR 与视图增强

**用户价值：** 截图内容可识别分类，获得时间感知和成就感

**FRs 覆盖：** FR2.5, FR3.5, FR5.1, FR5.2, FR5.3

**关键特性：**
- 截图 OCR 识别（Apple Vision）
- 日历三维视图（过去/现在/未来）
- 成就可视化（GitHub 贡献图风格）
- 完整今日概览
- Time Sheet 自动生成

---

### Epic 6: Memory 记忆系统

**用户价值：** AI 分类越用越准确，零配置、无感运行

**FRs 覆盖：** FR4.1, FR4.2, FR4.3, FR4.4, FR2.4

**关键特性：**
- 存储分类偏好规则
- 存储人际关系上下文
- 存储常用信息
- Memory 优化分类准确率
- 智能关联相关内容
- 完全自动，用户无需任何操作

---

## 版本迭代记录

| 版本 | 改动来源 | 关键改动 |
|------|----------|----------|
| v1 | 初始设计 | 基础结构 |
| v2 | User Persona | 截图提前，加今日过滤 |
| v3 | War Room | OCR 移到 Epic 5，徽章替代概览 |
| v3.1 | First Principles | Epic 2 专注捕获，列表移到 Epic 3 |

---

# Stories by Epic

## Epic 1: 项目基础与数据架构

**目标：** 可运行的应用骨架，数据模型就绪，为后续功能提供基础

---

### Story 1.1: 项目初始化与应用启动

**As a** 开发者,
**I want** 一个配置好的 SwiftUI + XcodeGen 项目,
**So that** 后续功能开发有标准化的基础。

**Acceptance Criteria:**

**Given** 开发环境已安装 Xcode 和 XcodeGen
**When** 执行 `xcodegen generate && open AIAssistant.xcodeproj`
**Then** 项目成功打开，无编译错误
**And** 项目结构符合 Architecture 文档定义的 Feature-based + Shared 结构

---

### Story 1.2: 菜单栏应用骨架

**As a** 用户,
**I want** 在 macOS 菜单栏看到应用图标,
**So that** 我知道应用正在运行且随时可用。

**Acceptance Criteria:**

**Given** 应用已启动
**When** 用户查看菜单栏
**Then** 显示应用图标（brain.head.profile）
**And** 点击图标弹出空白窗口
**And** 应用不显示在 Dock 栏（纯菜单栏应用）

---

### Story 1.3: SwiftData 核心数据模型

**As a** 开发者,
**I want** 定义核心数据模型（CaptureItem, CalendarEvent, TodoItem, Note）,
**So that** 后续功能可以持久化存储数据。

**Acceptance Criteria:**

**Given** SwiftData 已配置
**When** 应用启动
**Then** ModelContainer 成功初始化
**And** 可以创建、读取、更新、删除 CaptureItem
**And** 数据在应用重启后仍然存在

---

### Story 1.4: 基础 Service 层骨架

**As a** 开发者,
**I want** LLMService 和 VisionService 的接口定义,
**So that** 后续功能实现时有清晰的服务边界。

**Acceptance Criteria:**

**Given** Service 文件已创建
**When** 编译项目
**Then** LLMService 有 `classify(_ text: String) async throws -> Classification` 方法签名
**And** VisionService 有 `recognizeText(from image: NSImage) async throws -> String` 方法签名
**And** 方法暂时抛出 `.notImplemented` 错误（占位实现）

---

## Epic 2: 快速捕获核心

**目标：** 快捷键 → 粘贴(文本/截图) → 回车 → 反馈，全流程 <3 秒

---

### Story 2.1: 全局快捷键唤起捕获窗口

**As a** 用户,
**I want** 按下全局快捷键时弹出捕获窗口,
**So that** 我可以在任何应用中快速记录想法。

**Acceptance Criteria:**

**Given** 应用在后台运行
**When** 用户按下 ⌘+Shift+Space（默认快捷键）
**Then** 捕获窗口在屏幕中央弹出
**And** 响应时间 < 200ms
**And** 输入框自动获得焦点
**And** 快捷键可在设置中自定义

---

### Story 2.2: Dock 和菜单栏图标唤起

**As a** 用户,
**I want** 点击 Dock 或菜单栏图标打开捕获窗口,
**So that** 我有多种方式触发捕获。

**Acceptance Criteria:**

**Given** 应用已启动
**When** 用户点击 Dock 图标
**Then** 捕获窗口弹出

**Given** 应用已启动
**When** 用户点击菜单栏图标
**Then** 捕获窗口弹出

---

### Story 2.3: 文本粘贴与输入

**As a** 用户,
**I want** 在捕获窗口粘贴或输入文本,
**So that** 我可以快速记录文字内容。

**Acceptance Criteria:**

**Given** 捕获窗口已打开
**When** 用户按 ⌘+V 粘贴文本
**Then** 文本显示在输入框中

**Given** 捕获窗口已打开
**When** 用户直接输入文字
**Then** 文字显示在输入框中
**And** 输入框支持多行文本
**And** 界面保持极简（无多余按钮或选项）

---

### Story 2.4: 截图粘贴支持

**As a** 用户,
**I want** 粘贴截图到捕获窗口,
**So that** 我可以保存视觉信息。

**Acceptance Criteria:**

**Given** 用户已截图（⌘+Shift+4 等）
**When** 在捕获窗口按 ⌘+V
**Then** 截图显示为缩略图预览
**And** 图片保存到本地沙盒目录
**And** 可以同时包含文本和图片

---

### Story 2.5: 回车确认发送

**As a** 用户,
**I want** 按回车键确认并保存捕获内容,
**So that** 我可以用最少的操作完成记录。

**Acceptance Criteria:**

**Given** 输入框有内容（文本或图片）
**When** 用户按 Enter 键
**Then** 内容保存为 CaptureItem
**And** 默认分类为 "待处理"（AI 分类前的临时状态）

**Given** 输入框为空
**When** 用户按 Enter 键
**Then** 不执行任何操作（忽略空提交）

---

### Story 2.6: 捕获反馈与窗口关闭

**As a** 用户,
**I want** 保存成功后看到反馈提示,
**So that** 我确信内容已被记录。

**Acceptance Criteria:**

**Given** 用户按 Enter 确认
**When** 内容保存成功
**Then** 显示 ✅ 成功提示（Toast）
**And** 提示显示 1 秒后自动消失
**And** 捕获窗口自动关闭
**And** 用户可继续之前的工作

**Given** 保存失败（如存储错误）
**When** 发生错误
**Then** 显示错误提示
**And** 内容保留在输入框中（不丢失）

---

## Epic 3: 容器管理与展示

**目标：** 三大容器 CRUD + 批量处理 + 菜单栏徽章

---

### Story 3.1: 捕获列表视图

**As a** 用户,
**I want** 查看所有捕获内容的列表,
**So that** 我知道自己记录了什么。

**Acceptance Criteria:**

**Given** 用户打开主界面
**When** 查看捕获列表
**Then** 显示所有 CaptureItem，按时间倒序
**And** 每条显示：内容摘要、时间、分类状态
**And** 支持"今日"过滤

---

### Story 3.2: 日历容器基础 CRUD

**As a** 用户,
**I want** 查看、编辑、删除日历事件,
**So that** 我可以管理时间承诺。

**Acceptance Criteria:**

**Given** 用户进入日历视图
**When** 查看事件列表
**Then** 显示所有 CalendarEvent
**And** 可编辑标题、时间、时长
**And** 可删除事件

---

### Story 3.3: Todo 容器基础 CRUD

**As a** 用户,
**I want** 查看、编辑、完成、删除待办事项,
**So that** 我可以管理任务。

**Acceptance Criteria:**

**Given** 用户进入 Todo 视图
**When** 查看待办列表
**Then** 显示所有 TodoItem
**And** 可标记完成/未完成
**And** 可编辑标题、优先级
**And** 可删除待办

---

### Story 3.4: 笔记容器基础 CRUD

**As a** 用户,
**I want** 查看、编辑、删除笔记,
**So that** 我可以管理灵感仓库。

**Acceptance Criteria:**

**Given** 用户进入笔记视图
**When** 查看笔记列表
**Then** 显示所有 Note
**And** 可编辑内容
**And** 可删除笔记

---

### Story 3.5: 跨容器一键转化

**As a** 用户,
**I want** 将内容从一个容器转移到另一个,
**So that** 灵感可以升级为任务或日程。

**Acceptance Criteria:**

**Given** 用户查看某条笔记
**When** 选择"转为待办"
**Then** 创建对应 TodoItem
**And** 原笔记标记为已转化

**Given** 用户查看某条待办
**When** 选择"转为日历"
**Then** 弹出时间选择器
**And** 创建 CalendarEvent

---

### Story 3.6: 批量处理模式

**As a** 用户,
**I want** 批量审核和调整 AI 分类结果,
**So that** 我可以高效纠正错误分类。

**Acceptance Criteria:**

**Given** 用户进入批量处理模式
**When** 查看待处理列表
**Then** 显示所有未确认的 CaptureItem
**And** 可快速切换分类（日历/Todo/笔记）
**And** 可批量确认

---

### Story 3.7: 菜单栏徽章（可选）

**As a** 用户,
**I want** 在菜单栏看到待处理数量,
**So that** 我知道有多少内容需要整理。

**Acceptance Criteria:**

**Given** 徽章功能已开启（默认关闭）
**When** 有未处理的 CaptureItem
**Then** 菜单栏图标显示数字徽章
**And** 徽章可在设置中开关

---

## Epic 4: AI 智能分类

**目标：** 文本自动分类到正确容器

---

### Story 4.1: LLMService 实现与配置

**As a** 开发者,
**I want** 实现 LLMService 连接 Dashscope API,
**So that** 应用可以调用 AI 进行分类。

**Acceptance Criteria:**

**Given** API Key 已配置（环境变量或 Keychain）
**When** 调用 `llmService.classify(text)`
**Then** 返回 Classification 结构体
**And** 包含：container, confidence, extractedTime, priority, summary

---

### Story 4.2: 捕获自动分类

**As a** 用户,
**I want** 捕获的文本自动分类到正确容器,
**So that** 我不需要手动选择。

**Acceptance Criteria:**

**Given** 用户提交捕获内容
**When** 内容保存后
**Then** 后台自动调用 AI 分类
**And** 分类结果更新到 CaptureItem
**And** 自动创建对应容器的条目

---

### Story 4.3: 自然语言时间解析

**As a** 用户,
**I want** AI 识别文本中的时间信息,
**So that** 日程自动设置正确时间。

**Acceptance Criteria:**

**Given** 用户输入"明天下午3点开会"
**When** AI 分类处理
**Then** 识别为日历事件
**And** 时间解析为明天 15:00
**And** 支持中文时间表达

---

### Story 4.4: 优先级自动推荐

**As a** 用户,
**I want** AI 自动判断内容优先级,
**So that** 重要事项被标记出来。

**Acceptance Criteria:**

**Given** 用户输入包含"紧急"、"重要"等关键词
**When** AI 分类处理
**Then** 优先级标记为"重要"
**And** 其他内容默认为"普通"

---

### Story 4.5: 离线队列处理

**As a** 用户,
**I want** 离线时捕获的内容在联网后自动分类,
**So that** 离线不影响使用。

**Acceptance Criteria:**

**Given** 网络不可用
**When** 用户提交捕获
**Then** 内容保存为"待分类"状态

**Given** 网络恢复
**When** 应用检测到网络
**Then** 自动处理队列中的待分类项

---

## Epic 5: OCR 与视图增强

**目标：** 截图识别 + 日历视图 + 成就可视化

---

### Story 5.1: VisionService OCR 实现

**As a** 开发者,
**I want** 实现 VisionService 调用 Apple Vision,
**So that** 可以识别截图中的文字。

**Acceptance Criteria:**

**Given** 截图图片已保存
**When** 调用 `visionService.recognizeText(from: image)`
**Then** 返回识别的文字内容
**And** 支持中文识别
**And** 离线可用

---

### Story 5.2: 截图内容自动分类

**As a** 用户,
**I want** 截图中的文字被识别并分类,
**So that** 图片内容也能智能整理。

**Acceptance Criteria:**

**Given** 用户粘贴截图并提交
**When** 系统处理
**Then** 先 OCR 识别文字
**And** 将识别文字送给 AI 分类
**And** 分类结果同时关联图片

---

### Story 5.3: 日历三维视图

**As a** 用户,
**I want** 看到过去、现在、未来的时间视图,
**So that** 我对时间有清晰感知。

**Acceptance Criteria:**

**Given** 用户进入日历视图
**When** 查看三维视图
**Then** 显示：过去（已完成）、现在（今日）、未来（待办）
**And** 过去事项显示为成就记录
**And** 未来事项提供安全感

---

### Story 5.4: 成就可视化

**As a** 用户,
**I want** 看到类似 GitHub 贡献图的成就展示,
**So that** 我感受到自己的进步。

**Acceptance Criteria:**

**Given** 用户查看成就视图
**When** 数据加载完成
**Then** 显示热力图（按日期）
**And** 颜色深浅表示当日捕获/完成数量
**And** 可查看过去 12 个月

---

### Story 5.5: 今日概览

**As a** 用户,
**I want** 早上看到今日概览,
**So that** 我知道今天的安排。

**Acceptance Criteria:**

**Given** 用户早上首次打开应用
**When** 显示今日概览
**Then** 展示：今日日程数、待办数、昨日新增笔记数
**And** 可选择关闭此功能

---

### Story 5.6: Time Sheet 自动生成

**As a** 用户,
**I want** 自动生成基于日历的时间表,
**So that** 我可以回顾时间投入并获得成就感。

**Acceptance Criteria:**

**Given** 用户进入 Time Sheet 视图
**When** 选择时间范围（本周/本月）
**Then** 显示按日期汇总的时间块
**And** 显示每日总时长
**And** 可导出为文本/图片

---

## Epic 6: Memory 记忆系统

**目标：** AI 越用越准，零配置

---

### Story 6.1: MemoryEntry 数据模型

**As a** 开发者,
**I want** 定义 MemoryEntry 模型,
**So that** 系统可以存储学习到的规则。

**Acceptance Criteria:**

**Given** SwiftData 已配置
**When** 创建 MemoryEntry
**Then** 支持类型：preference, person, rule
**And** 记录使用次数
**And** 数据持久化

---

### Story 6.2: 分类偏好学习

**As a** 用户,
**I want** 系统记住我的分类偏好,
**So that** 相似内容自动正确分类。

**Acceptance Criteria:**

**Given** 用户纠正了 AI 分类
**When** 系统检测到纠正行为
**Then** 创建/更新偏好规则
**And** 下次相似内容优先使用学到的规则

---

### Story 6.3: 常用信息存储

**As a** 用户,
**I want** 系统记住我常提到的项目、地点等,
**So that** 上下文理解更准确。

**Acceptance Criteria:**

**Given** 用户多次提到"项目A"
**When** 系统检测到高频词
**Then** 自动存储为常用信息
**And** 后续分类时作为上下文参考

---

### Story 6.4: Memory 优化分类

**As a** 用户,
**I want** AI 分类时参考 Memory,
**So that** 分类越来越准确。

**Acceptance Criteria:**

**Given** Memory 中有偏好规则
**When** AI 分类新内容
**Then** Prompt 包含相关 Memory 条目
**And** 分类准确率随使用提升

---

### Story 6.5: 智能关联

**As a** 用户,
**I want** 相关内容自动关联,
**So that** 我能看到上下文联系。

**Acceptance Criteria:**

**Given** 新捕获内容
**When** AI 分类处理
**Then** 尝试关联相关的已有条目
**And** 关联基于内容相似度和 Memory
**And** 关联失败不影响基本功能

---

# Document Summary

| 指标 | 值 |
|------|-----|
| 总 Epics | 6 |
| 总 Stories | 33 |
| FR 覆盖率 | 25/25 (100%) |
| 状态 | ✅ 可进入开发 |
