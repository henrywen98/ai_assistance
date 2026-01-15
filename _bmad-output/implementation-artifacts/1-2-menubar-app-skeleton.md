# Story 1.2: 菜单栏应用骨架

Status: in-progress

## Story

**As a** 用户,
**I want** 在 macOS 菜单栏看到应用图标,
**So that** 我知道应用正在运行且随时可用。

## Acceptance Criteria

1. **AC1: 菜单栏图标显示**
   - **Given** 应用已启动
   - **When** 用户查看菜单栏
   - **Then** 显示应用图标（brain.head.profile）

2. **AC2: 点击弹出窗口**
   - **Given** 应用已启动
   - **When** 点击菜单栏图标
   - **Then** 弹出空白窗口

3. **AC3: 纯菜单栏应用**
   - **Given** 应用已启动
   - **Then** 应用不显示在 Dock 栏

## Tasks / Subtasks

- [ ] **Task 1: 配置 LSUIElement** (AC: #3)
  - [ ] 1.1 修改 Info.plist 设置 LSUIElement 为 true

- [ ] **Task 2: 实现 MenuBarExtra** (AC: #1, #2)
  - [ ] 2.1 修改 AIAssistantApp.swift 使用 MenuBarExtra
  - [ ] 2.2 配置图标 brain.head.profile
  - [ ] 2.3 创建弹出窗口内容

- [ ] **Task 3: 更新 AppDelegate** (AC: #3)
  - [ ] 3.1 设置 applicationShouldTerminateAfterLastWindowClosed 返回 false

- [ ] **Task 4: 验证功能**
  - [ ] 4.1 编译运行
  - [ ] 4.2 验证菜单栏图标
  - [ ] 4.3 验证 Dock 栏不显示

## Dev Notes

### 技术实现
- 使用 SwiftUI MenuBarExtra
- LSUIElement=true 隐藏 Dock 图标
- .menuBarExtraStyle(.window) 弹出窗口模式
