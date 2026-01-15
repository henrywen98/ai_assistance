# Story 1.1: 项目初始化与应用启动

Status: done

## Story

**As a** 开发者,
**I want** 一个配置好的 SwiftUI + XcodeGen 项目,
**So that** 后续功能开发有标准化的基础。

## Acceptance Criteria

1. **AC1: 项目生成成功**
   - **Given** 开发环境已安装 Xcode 和 XcodeGen
   - **When** 执行 `xcodegen generate && open AIAssistant.xcodeproj`
   - **Then** 项目成功打开，无编译错误

2. **AC2: 项目结构符合架构规范**
   - **Given** 项目已生成
   - **When** 检查目录结构
   - **Then** 符合 Architecture 文档定义的 Feature-based + Shared 结构

3. **AC3: 依赖正确配置**
   - **Given** project.yml 已创建
   - **When** Xcode 解析项目
   - **Then** KeyboardShortcuts 和 OpenAI SPM 依赖可用

4. **AC4: 应用可启动**
   - **Given** 项目编译成功
   - **When** 运行应用
   - **Then** 应用启动无崩溃（可以是空白窗口）

## Tasks / Subtasks

- [x] **Task 1: 创建项目目录结构** (AC: #2) ✅
  - [x] 1.1 创建 `app/` 根目录
  - [x] 1.2 创建 `app/Sources/App/` 目录
  - [x] 1.3 创建 `app/Sources/Features/` 及子目录 (Capture, Calendar, Todo, Notes, Memory)
  - [x] 1.4 创建 `app/Sources/Shared/` 及子目录 (Models, Services, Components, Extensions)
  - [x] 1.5 创建 `app/Resources/` 目录
  - [x] 1.6 创建 `app/Tests/` 目录

- [x] **Task 2: 创建 XcodeGen 配置** (AC: #1, #3) ✅
  - [x] 2.1 创建 `app/project.yml` 文件
  - [x] 2.2 配置项目名称: AIAssistant
  - [x] 2.3 配置 targets: macOS 14.0+
  - [x] 2.4 配置 SPM 依赖: KeyboardShortcuts, OpenAI
  - [x] 2.5 配置 source 和 resource 路径

- [x] **Task 3: 创建应用入口文件** (AC: #4) ✅
  - [x] 3.1 创建 `AIAssistantApp.swift` - 应用入口
  - [x] 3.2 创建 `AppState.swift` - 全局状态容器（占位）
  - [x] 3.3 创建 `AppDelegate.swift` - 系统事件处理（占位）

- [x] **Task 4: 创建资源文件** (AC: #1) ✅
  - [x] 4.1 创建 `Info.plist`
  - [x] 4.2 创建 `AIAssistant.entitlements`
  - [x] 4.3 创建 `Assets.xcassets` 目录和 AppIcon

- [x] **Task 5: 验证项目** (AC: #1, #4) ✅
  - [x] 5.1 执行 `xcodegen generate`
  - [x] 5.2 打开项目并编译
  - [x] 5.3 运行应用验证启动

## Dev Notes

### 技术栈要求

| 要求 | 值 | 来源 |
|------|-----|------|
| 语言 | Swift 6.0 | [Architecture: 3.1] |
| UI 框架 | SwiftUI | [Architecture: 3.1] |
| 最低版本 | macOS 14.0+ / iOS 17.0+ | [Architecture: 3.1, 3.2] |
| 项目管理 | XcodeGen | [Architecture: 2.4] |
| 架构模式 | Feature-based + Shared (MVVM) | [Architecture: 3.1, 4.2] |

### 依赖配置

```yaml
# project.yml SPM packages 配置
packages:
  KeyboardShortcuts:
    url: https://github.com/sindresorhus/KeyboardShortcuts
    from: "2.0.0"
  OpenAI:
    url: https://github.com/MacPaw/OpenAI
    from: "0.3.0"
```

### XcodeGen 安装

```bash
# 如果未安装 XcodeGen
brew install xcodegen

# 验证安装
xcodegen --version
```

### Project Structure Notes

**必须遵循的目录结构：**
```
app/
├── project.yml                         # XcodeGen 配置
├── Sources/
│   ├── App/
│   │   ├── AIAssistantApp.swift       # 应用入口 + MenuBarExtra
│   │   ├── AppState.swift             # 全局状态 (@Observable)
│   │   └── AppDelegate.swift          # 系统事件处理
│   ├── Features/
│   │   ├── Capture/                   # 占位目录
│   │   ├── Calendar/                  # 占位目录
│   │   ├── Todo/                      # 占位目录
│   │   ├── Notes/                     # 占位目录
│   │   └── Memory/                    # 占位目录
│   └── Shared/
│       ├── Models/                    # 占位目录
│       ├── Services/                  # 占位目录
│       ├── Components/                # 占位目录
│       └── Extensions/                # 占位目录
├── Resources/
│   ├── Info.plist
│   ├── AIAssistant.entitlements
│   └── Assets.xcassets/
└── Tests/
    ├── UnitTests/
    └── UITests/
```

**架构边界规则：**
- Features → Shared: ✅ 允许
- Shared → Features: ❌ 禁止
- Feature → Feature: ❌ 禁止（通过 AppState 通信）

### 代码模板

**AIAssistantApp.swift 基础结构：**
```swift
import SwiftUI

@main
struct AIAssistantApp: App {
    var body: some Scene {
        // 占位：后续 Story 1.2 将添加 MenuBarExtra
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    var body: some View {
        Text("AIAssistant - Story 1.1 Complete")
            .frame(width: 300, height: 200)
    }
}
```

**AppState.swift 占位：**
```swift
import SwiftUI

@Observable
class AppState {
    // 全局状态将在后续 Story 中添加
}
```

### project.yml 完整模板

```yaml
name: AIAssistant
options:
  bundleIdPrefix: com.henry
  deploymentTarget:
    macOS: "14.0"
  xcodeVersion: "15.0"
  generateEmptyDirectories: true

packages:
  KeyboardShortcuts:
    url: https://github.com/sindresorhus/KeyboardShortcuts
    from: "2.0.0"
  OpenAI:
    url: https://github.com/MacPaw/OpenAI
    from: "0.3.0"

targets:
  AIAssistant:
    type: application
    platform: macOS
    sources:
      - path: Sources
    resources:
      - path: Resources
    dependencies:
      - package: KeyboardShortcuts
      - package: OpenAI
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.henry.AIAssistant
        PRODUCT_NAME: AIAssistant
        INFOPLIST_FILE: Resources/Info.plist
        CODE_SIGN_ENTITLEMENTS: Resources/AIAssistant.entitlements
        SWIFT_VERSION: "6.0"
        MACOSX_DEPLOYMENT_TARGET: "14.0"
```

### References

- [Source: architecture.md#2.4] - XcodeGen 选择理由
- [Source: architecture.md#3.1] - 核心技术决策
- [Source: architecture.md#3.5] - 项目结构定义
- [Source: architecture.md#5.1] - 完整目录结构
- [Source: epics.md#Story-1.1] - Story 定义和 AC

## Dev Agent Record

### Agent Model Used

Claude Opus 4.5 (claude-opus-4-5-20251101)

### Debug Log References

- XcodeGen 安装: `brew install xcodegen` (版本 2.44.1)
- 项目生成: `xcodegen generate` - 成功
- 编译: `xcodebuild -project AIAssistant.xcodeproj -scheme AIAssistant` - BUILD SUCCEEDED
- 运行验证: 应用成功启动，进程 ID 35898

### Completion Notes List

1. ✅ 所有 5 个 Task 全部完成
2. ✅ 4 个 Acceptance Criteria 全部满足:
   - AC1: XcodeGen 生成项目成功，无编译错误
   - AC2: 目录结构符合 Feature-based + Shared 架构
   - AC3: KeyboardShortcuts 和 OpenAI SPM 依赖正确配置
   - AC4: 应用启动无崩溃
3. ✅ AppState 增加了 ContainerType 枚举为后续 Story 做准备
4. ✅ 添加了 AccentColor（紫色主题）到 Assets

### File List

**已创建的文件：**
- [x] `app/project.yml`
- [x] `app/Sources/App/AIAssistantApp.swift`
- [x] `app/Sources/App/AppState.swift`
- [x] `app/Sources/App/AppDelegate.swift`
- [x] `app/Resources/Info.plist`
- [x] `app/Resources/AIAssistant.entitlements`
- [x] `app/Resources/Assets.xcassets/Contents.json`
- [x] `app/Resources/Assets.xcassets/AppIcon.appiconset/Contents.json`
- [x] `app/Resources/Assets.xcassets/AccentColor.colorset/Contents.json`
- [x] `app/Tests/UnitTests/AppStateTests.swift` (Code Review 新增)
- [x] `app/AIAssistant.xcodeproj/` (XcodeGen 生成)
- [x] 各 Feature 和 Shared 子目录（占位）

### 完成日期

2026-01-15

---

## Senior Developer Review (AI)

### 审查日期
2026-01-15

### 审查者
Claude Opus 4.5 (Adversarial Code Review)

### 发现问题数
- HIGH: 1
- MEDIUM: 4
- LOW: 3

### 修复的问题

**H1: ContainerType 枚举与 Architecture 不一致** [已修复]
- 将 `notes` (复数) 改为 `note` (单数)，与 Architecture 4.6 节保持一致
- 移除未定义的 `memory` case
- 添加 `Codable` 协议支持

**M1: AppState 未在 AIAssistantApp 中使用** [已修复]
- 添加 `@State private var appState = AppState()`
- 通过 `.environment(appState)` 注入到 ContentView

**M2: 缺少 Sendable 一致性** [已修复]
- 为 AppState 添加 `@MainActor` 注解确保线程安全

**M3: print 语句替换为 os.Logger** [已修复]
- 使用 `Logger(subsystem:category:)` 替换 `print()`

**M4: Tests 目录缺少占位测试文件** [已修复]
- 创建 `AppStateTests.swift` 包含 3 个测试用例
- 添加 `AIAssistantTests` target 到 project.yml

### 未修复的 LOW 问题（留待后续）

- L1: ContentView 应拆分到单独文件
- L2: 注释语言不一致
- L3: Assets 缺少实际图标文件

### 测试验证

```
✔ Test "ContainerType displayName 正确" passed
✔ Test "ContainerType 枚举值正确" passed
✔ Test "AppState 初始化状态正确" passed
✔ Suite "AppState Tests" passed
** TEST SUCCEEDED **
```

### 结论

**APPROVED** - 所有 HIGH 和 MEDIUM 问题已修复，代码符合 Architecture 规范
