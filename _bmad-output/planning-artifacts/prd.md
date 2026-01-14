---
stepsCompleted: ['step-01-init', 'step-02-discovery', 'step-03-vision']
inputDocuments: ['_bmad-output/analysis/brainstorming-session-2026-01-14.md']
workflowType: 'prd'
documentCounts:
  brief: 0
  research: 0
  brainstorming: 1
  projectDocs: 0
classification:
  projectType: 'desktop_app'
  domain: 'productivity'
  complexity: 'medium'
  context: 'greenfield'
---

# Product Requirements Document - ai_assistance

**Author:** Henry
**Date:** 2026-01-14

## 1. Product Overview

### 1.1 One-Line Description
为 ADHD 用户设计的 AI 驱动个人助理，通过"零摩擦捕获 + AI 自动整理"帮助用户管理时间和事务。

### 1.2 Core Value Proposition
- 🚀 **快速卸载** - 想到什么立刻丢进去，一身轻松
- 🤖 **AI 代劳** - 分类、时间、归档全自动
- 🧠 **ADHD 友好** - 零决策、零配置、零摩擦

### 1.3 Target Users
**Primary:** ADHD 人群 / 工作记忆短 / 长时间电脑工作者

**User Characteristics:**
- 灵感多但转瞬即逝
- 讨厌需要"细心"的操作
- 没有固定的时间管理习惯
- 时间感知弱（时间盲）
- 没耐心配置复杂功能

## 2. Product Vision

### 2.1 Problem Statement

**ADHD 用户的困境：** 灵感和信息来得快、忘得更快。传统工具要求用户在捕获时做分类决策，但这正是 ADHD 大脑最不擅长的——"在寻找对话框、思考应该分类到哪里"的过程中，信息的紧迫感就消失了。

**具体痛点：**
1. **捕获摩擦** - 现有工具需要太多步骤和决策
2. **灵感二次消逝** - 记下来≠能找回来，信息在系统里"沉底"
3. **时间盲** - 对时间流逝没有感知，不知道"现在在哪"
4. **配置疲劳** - 没耐心设置复杂系统，功能再强也用不起来

### 2.2 Solution Approach

**核心理念：** 捕获与处理分离 + AI 代劳细节工作

```
用户只管：粘贴 → 回车
AI 负责：分类 → 设时间 → 关联 → 归档
```

**三大设计原则：**

| 原则 | 含义 | 体现 |
|------|------|------|
| **零摩擦** | 从想法到记录，步骤最少化 | 快捷键 → 粘贴 → 回车，3步完成 |
| **零决策** | 输入时不做任何分类决策 | AI 自动分类，事后可纠错 |
| **零配置** | 开箱即用，无需设置 | Memory 系统自动学习用户偏好 |

**信任优先原则：** AI 先做决策，用户事后纠错 > 事前确认

