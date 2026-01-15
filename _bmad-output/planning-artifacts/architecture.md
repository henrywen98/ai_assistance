---
stepsCompleted: ['step-01-init', 'step-02-context', 'step-03-starter', 'step-04-decisions', 'step-05-patterns', 'step-06-structure', 'step-07-validation']
status: 'complete'
inputDocuments: ['_bmad-output/planning-artifacts/prd.md', '_bmad-output/analysis/brainstorming-session-2026-01-14.md']
workflowType: 'architecture'
project_name: 'ai_assistance'
user_name: 'Henry'
date: '2026-01-14'
---

# Architecture Decision Document

_This document builds collaboratively through step-by-step discovery. Sections are appended as we work through each architectural decision together._

## 1. Project Context Analysis

### 1.1 Requirements Overview

**Functional Requirements (25 条，5 个模块)：**

| 模块 | 数量 | 架构影响 |
|------|------|----------|
| FR1: 快速捕获 | 7 | 系统级集成（全局快捷键、Dock、菜单栏） |
| FR2: AI 解析引擎 | 5 | LLM 集成层、OCR、Prompt 管理 |
| FR3: 三大容器 | 5 | 核心数据模型、容器间转换逻辑 |
| FR4: Memory 系统 | 4 | 持久化存储、检索、学习算法 |
| FR5: 视图展示 | 4 | UI 组件、数据聚合、可视化 |

**Non-Functional Requirements (15 条)：**

| 类别 | 关键约束 |
|------|----------|
| 性能 | 快捷键 <200ms、AI 响应 <2s、内存 <200MB |
| 可用性 | 零学习曲线、≤3 步操作、极简界面 |
| 可靠性 | 本地持久化、离线可用、崩溃恢复 |
| 安全 | 数据本地优先、无强制账号 |
| 兼容性 | macOS 13+、Apple Silicon + Intel |

### 1.2 Scale & Complexity

| 指标 | 评估 |
|------|------|
| **项目复杂度** | 中等 (Medium) |
| **技术领域** | macOS 桌面应用 + AI 集成 |
| **预估组件数** | 8-12 个核心组件 |
| **实时特性** | 低（无协作、无实时同步） |
| **数据复杂度** | 中等（5 个实体、跨容器关联） |

### 1.3 Technical Constraints & Dependencies

| 约束 | 说明 |
|------|------|
| **平台锁定** | macOS 原生，需要系统 API 访问 |
| **AI 依赖** | 外部 LLM API（成本、延迟、可用性） |
| **隐私优先** | 数据本地存储，限制云端传输 |
| **离线降级** | 无网络时基础功能可用 |

### 1.4 Cross-Cutting Concerns

1. **错误处理** - AI 调用失败、网络中断、数据冲突
2. **数据持久化** - 所有模块共享存储层
3. **离线/在线切换** - 影响 AI 解析、同步逻辑
4. **用户偏好** - Memory 系统需被多模块访问
5. **反馈机制** - 统一的 Toast/动效/音效系统

### 1.5 Technology Research Summary

**框架对比研究结果：**

| 指标 | Tauri 2.0 | Electron | SwiftUI |
|------|-----------|----------|---------|
| 应用大小 | 8-25 MB | 244 MB+ | 最小 |
| 内存占用 | 30-40 MB | 200-300 MB | 最优 |
| 启动时间 | < 0.5s | 1-2s | 最快 |
| 跨平台 | ✅ 5平台 | ✅ 3平台 | ❌ Apple only |

**LLM 集成选项：**

| 方案 | 特点 |
|------|------|
| Ollama | 本地、隐私、Apple Silicon 加速 |
| OpenAI/Claude API | 云端、稳定、按量付费 |
| 多 Provider 抽象 | 灵活切换，离线降级 |

**初步技术倾向：**
- 框架：Tauri 2.0（性能好、跨平台潜力）
- 存储：SQLite + 本地文件
- LLM：多 Provider 抽象层

**研究来源：**
- [Tauri vs Electron 2025](https://www.raftlabs.com/blog/tauri-vs-electron-pros-cons/)
- [Local LLM Guide](https://medium.com/@rosgluk/local-llm-hosting-complete-2025-guide-ollama-vllm-localai-jan-lm-studio-more-f98136ce7e4a)
- [ADHD App Patterns](https://fluidwave.com/blog/productivity-apps-for-adhd)

## 2. Starter Template Evaluation

### 2.1 Primary Technology Domain

**桌面应用 + 移动端扩展** - macOS 优先，未来支持 iOS，目标 App Store 变现

### 2.2 User Context

- 用户依赖 AI 辅助编程（不直接编写代码）
- 需要 App Store 上架变现
- 未来需要 iOS 支持

### 2.3 Starter Options Evaluated

| 方案 | AI 友好度 | App Store | iOS 支持 | 结论 |
|------|-----------|-----------|----------|------|
| **SwiftUI Multiplatform** | ⭐⭐⭐⭐ | ✅ 原生最佳 | ✅ 代码共享 | **选中** |
| Tauri 2.0 | ⭐⭐⭐⭐⭐ | ⚠️ 有挑战 | ⚠️ 较新 | 备选 |
| Electron | ⭐⭐⭐⭐⭐ | ❌ 体验差 | ❌ 不支持 | 排除 |

### 2.4 Selected Starter: SwiftUI + XcodeGen

**选择理由：**
1. **App Store 变现** - 原生应用审核友好，用户体验好，支持更高定价
2. **iOS 扩展** - SwiftUI Multiplatform 一套代码支持 macOS + iOS
3. **AI 编程验证** - Claude Code 已成功构建 20,000+ 行 SwiftUI 应用
4. **XcodeGen** - 对 AI 编程友好，避免 .xcodeproj 合并冲突

**初始化方式：**
```bash
# 安装 XcodeGen
brew install xcodegen

# 生成项目（在 project.yml 所在目录）
xcodegen generate

# 打开项目
open AIAssistant.xcodeproj
```

### 2.5 Architectural Decisions from Starter

| 决策点 | 值 | 说明 |
|--------|-----|------|
| **语言** | Swift 6 | Apple 最新版本 |
| **UI 框架** | SwiftUI | 声明式 UI，跨平台共享 |
| **最低版本** | macOS 13+ / iOS 16+ | 支持最新 SwiftUI 特性 |
| **架构模式** | MVVM | SwiftUI 推荐模式 |
| **项目管理** | XcodeGen | YAML 定义，AI 友好 |

### 2.6 Research Sources

- [Claude Code SwiftUI Success](https://www.indragie.com/blog/i-shipped-a-macos-app-built-entirely-by-claude-code)
- [XcodeGen for AI Coding](https://twocentstudios.com/2025/08/04/full-stack-swift-technicolor-technical-architecture/)
- [Apple Multiplatform Docs](https://developer.apple.com/documentation/swiftui/food_truck_building_a_swiftui_multiplatform_app)

## 3. Core Architectural Decisions

### 3.1 Decision Summary

| 类别 | 决策 | 版本/说明 | 理由 |
|------|------|-----------|------|
| **语言** | Swift | 6.0 | Apple 最新，SwiftUI 最佳支持 |
| **UI 框架** | SwiftUI | macOS 14+ / iOS 17+ | 声明式，跨平台共享 |
| **数据库** | SwiftData | + CloudKit | 原生集成，iCloud 同步 |
| **文件存储** | 沙盒 + iCloud Drive | - | 图片云同步，App Store 合规 |
| **LLM 集成** | OpenAI SDK | Dashscope 后端 | 阿里云，兼容接口，成本低 |
| **OCR** | Apple Vision | 系统内置 | 免费、离线、中文支持好 |
| **快捷键** | KeyboardShortcuts | 开源库 | SwiftUI 友好，用户可自定义 |
| **菜单栏** | MenuBarExtra | SwiftUI 原生 | 代码简洁 |
| **架构模式** | Feature-based + Shared | MVVM | 模块清晰，易于 AI 编程 |
| **项目管理** | XcodeGen | YAML 配置 | 避免 xcodeproj 冲突 |

### 3.2 Data Architecture

**数据库：SwiftData + CloudKit**

```swift
@Model
class CaptureItem {
    var id: UUID
    var content: String
    var imageURL: URL?
    var container: ContainerType  // calendar, todo, note
    var createdAt: Date
    var aiConfidence: Double
    var userConfirmed: Bool
}
```

**存储策略：**
- 结构化数据 → SwiftData（自动 CloudKit 同步）
- 图片文件 → iCloud Drive 容器（自动同步）
- API Keys → Keychain（安全存储，不同步）

**最低版本调整：** macOS 14+ / iOS 17+（SwiftData 要求）

### 3.3 AI/LLM Integration

**架构：OpenAI SDK 兼容层**

```swift
// 配置 Dashscope (阿里云)
let configuration = OpenAI.Configuration(
    baseURL: URL(string: "https://dashscope.aliyuncs.com/compatible-mode/v1")!,
    apiKey: KeychainService.getDashscopeKey()
)

let openAI = OpenAI(configuration: configuration)
```

**调用流程：**
```
用户输入 → Apple Vision OCR（如有图片）
         → 文字内容 → Dashscope API 分类
         → 返回：container + time + priority
```

**离线处理：**
- OCR 可离线执行
- LLM 分类需联网
- 离线时暂存本地，联网后批量处理

### 3.4 macOS System Integration

**全局快捷键：KeyboardShortcuts**
```swift
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let quickCapture = Self("quickCapture", default: .init(.space, modifiers: [.command, .shift]))
}
```

**菜单栏：MenuBarExtra**
```swift
@main
struct AIAssistantApp: App {
    var body: some Scene {
        MenuBarExtra("AI Assistant", systemImage: "brain.head.profile") {
            QuickCaptureView()
        }
        .menuBarExtraStyle(.window)
    }
}
```

### 3.5 Project Structure

```
AIAssistant/
├── project.yml                    # XcodeGen 配置
├── Sources/
│   ├── App/
│   │   ├── AIAssistantApp.swift   # 应用入口
│   │   └── AppState.swift         # 全局状态
│   ├── Features/
│   │   ├── Capture/               # 快速捕获模块
│   │   │   ├── CaptureView.swift
│   │   │   └── CaptureViewModel.swift
│   │   ├── Calendar/              # 日历模块
│   │   ├── Todo/                  # 待办模块
│   │   ├── Notes/                 # 笔记模块
│   │   └── Memory/                # 记忆系统模块
│   └── Shared/
│       ├── Models/                # SwiftData 模型
│       │   ├── CaptureItem.swift
│       │   ├── CalendarEvent.swift
│       │   ├── TodoItem.swift
│       │   ├── Note.swift
│       │   └── MemoryEntry.swift
│       ├── Services/              # 服务层
│       │   ├── LLMService.swift
│       │   ├── VisionService.swift
│       │   └── KeychainService.swift
│       └── Components/            # 通用 UI 组件
│           ├── FeedbackToast.swift
│           └── AchievementGraph.swift
└── Resources/
    ├── Info.plist
    ├── AIAssistant.entitlements
    └── Assets.xcassets

### 3.6 Dependencies

| 依赖 | 用途 | 安装方式 |
|------|------|----------|
| KeyboardShortcuts | 全局快捷键 | SPM |
| OpenAI (MacPaw) | LLM API 调用 | SPM |

**Swift Package Manager 配置：**
```swift
dependencies: [
    .package(url: "https://github.com/sindresorhus/KeyboardShortcuts", from: "2.0.0"),
    .package(url: "https://github.com/MacPaw/OpenAI", from: "0.3.0")
]
```

## 4. Implementation Patterns & Consistency Rules

### 4.1 命名规范

| 类别 | 规范 | 示例 |
|------|------|------|
| **类型/协议** | PascalCase | `CaptureItem`, `LLMService`, `Classifiable` |
| **变量/属性** | camelCase | `captureItem`, `isProcessing` |
| **函数/方法** | camelCase | `processCapture()`, `classifyContent()` |
| **枚举值** | camelCase | `case calendar, todo, note` |
| **常量** | camelCase | `let maxRetries = 3` |
| **文件名** | PascalCase | `CaptureView.swift`, `LLMService.swift` |

### 4.2 文件组织模式

**Feature 模块结构：**
```
Features/Capture/
├── CaptureView.swift          # 视图
├── CaptureViewModel.swift     # 视图模型
├── CaptureService.swift       # 业务逻辑（可选）
└── Components/                # 模块专属子组件
    └── CaptureInputField.swift
```

**规则：**
- View 和 ViewModel 放同一目录
- 模块专属组件放 Components/ 子目录
- 跨模块共享的放 Shared/

### 4.3 异步处理模式

**统一使用 async/await：**

```swift
// ✅ 正确
func classifyContent(_ text: String) async throws -> Classification {
    let response = try await llmService.complete(prompt: text)
    return response.classification
}

// ❌ 避免回调方式
func classifyContent(_ text: String, completion: @escaping (Result<Classification, Error>) -> Void)
```

### 4.4 错误处理模式

**统一错误枚举：**

```swift
enum AIAssistantError: LocalizedError {
    case networkUnavailable
    case llmServiceError(String)
    case invalidResponse
    case storageError(String)
    case ocrFailed(String)
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .networkUnavailable: return "网络不可用"
        case .llmServiceError(let msg): return "AI 服务错误：\(msg)"
        case .invalidResponse: return "无效响应"
        case .storageError(let msg): return "存储错误：\(msg)"
        case .ocrFailed(let msg): return "图片识别失败：\(msg)"
        case .unknown(let msg): return "未知错误：\(msg)"
        }
    }
}
```

### 4.5 状态管理模式

**使用 @Observable (Swift 5.9+)：**

```swift
// ViewModel 模板
@Observable
class CaptureViewModel {
    // 状态
    var inputText: String = ""
    var isProcessing: Bool = false
    var error: AIAssistantError?
    var classification: Classification?

    // 依赖
    private let llmService: LLMService
    private let visionService: VisionService

    init(llmService: LLMService = .shared, visionService: VisionService = .shared) {
        self.llmService = llmService
        self.visionService = visionService
    }

    // 操作
    func submit() async {
        isProcessing = true
        defer { isProcessing = false }

        do {
            classification = try await llmService.classify(inputText)
        } catch let error as AIAssistantError {
            self.error = error
        } catch {
            self.error = .unknown(error.localizedDescription)
        }
    }
}

// View 中使用
struct CaptureView: View {
    @State private var viewModel = CaptureViewModel()

    var body: some View {
        // ...
    }
}
```

### 4.6 数据格式规范

**LLM 分类响应：**

```swift
struct Classification: Codable {
    let container: ContainerType      // 目标容器
    let confidence: Double            // 置信度 0.0-1.0
    let extractedTime: Date?          // 解析的时间
    let suggestedPriority: Priority   // 建议优先级
    let summary: String               // AI 摘要
}

enum ContainerType: String, Codable, CaseIterable {
    case calendar
    case todo
    case note
}

enum Priority: String, Codable {
    case important
    case normal
}
```

### 4.7 AI 编程强制规则

**所有 AI 生成代码必须遵守：**

1. ✅ 所有 ViewModel 使用 `@Observable` 宏
2. ✅ 所有异步操作使用 `async/await`
3. ✅ 所有错误使用 `AIAssistantError` 枚举
4. ✅ 文件命名：功能名 + 类型（如 `CaptureView.swift`）
5. ✅ 每个 Feature 模块独立，共享代码放 `Shared/`
6. ✅ 日期时间使用 ISO 8601 格式
7. ✅ JSON 字段使用 camelCase

### 4.8 代码模板

**标准 ViewModel：**
```swift
@Observable
class XxxViewModel {
    // MARK: - State
    var isLoading = false
    var error: AIAssistantError?

    // MARK: - Dependencies
    private let service: XxxService

    // MARK: - Init
    init(service: XxxService = .shared) {
        self.service = service
    }

    // MARK: - Actions
    func doSomething() async {
        isLoading = true
        defer { isLoading = false }

        do {
            // 业务逻辑
        } catch let error as AIAssistantError {
            self.error = error
        } catch {
            self.error = .unknown(error.localizedDescription)
        }
    }
}
```

**标准 View：**
```swift
struct XxxView: View {
    @State private var viewModel = XxxViewModel()

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
            } else if let error = viewModel.error {
                ErrorView(error: error)
            } else {
                ContentView(viewModel: viewModel)
            }
        }
        .task {
            await viewModel.load()
        }
    }
}
```

## 5. Project Structure & Boundaries

### 5.1 Complete Directory Structure

```
AIAssistant/
├── project.yml                         # XcodeGen 配置
├── Sources/
│   ├── App/
│   │   ├── AIAssistantApp.swift       # 应用入口 + MenuBarExtra
│   │   ├── AppState.swift             # 全局状态 (@Observable)
│   │   └── AppDelegate.swift          # 系统事件处理
│   │
│   ├── Features/
│   │   ├── Capture/                   # FR1: 快速捕获
│   │   │   ├── CaptureView.swift      # 弹出窗口 UI
│   │   │   ├── CaptureViewModel.swift # 捕获逻辑
│   │   │   └── Components/
│   │   │       ├── InputField.swift   # 文字输入框
│   │   │       └── ImagePreview.swift # 图片预览
│   │   │
│   │   ├── Calendar/                  # FR3.1: 日历容器
│   │   │   ├── CalendarView.swift
│   │   │   ├── CalendarViewModel.swift
│   │   │   └── Components/
│   │   │       └── EventCard.swift
│   │   │
│   │   ├── Todo/                      # FR3.2: 待办容器
│   │   │   ├── TodoView.swift
│   │   │   ├── TodoViewModel.swift
│   │   │   └── Components/
│   │   │       └── TaskRow.swift
│   │   │
│   │   ├── Notes/                     # FR3.3: 笔记容器
│   │   │   ├── NotesView.swift
│   │   │   ├── NotesViewModel.swift
│   │   │   └── Components/
│   │   │       └── NoteCard.swift
│   │   │
│   │   └── Memory/                    # FR4: Memory 系统
│   │       ├── MemoryView.swift       # 可视化视图
│   │       ├── MemoryViewModel.swift
│   │       └── Components/
│   │           └── AchievementGraph.swift
│   │
│   └── Shared/
│       ├── Models/                    # SwiftData 数据模型
│       │   ├── CaptureItem.swift      # 捕获项
│       │   ├── CalendarEvent.swift    # 日历事件
│       │   ├── TodoItem.swift         # 待办事项
│       │   ├── Note.swift             # 笔记
│       │   ├── MemoryEntry.swift      # 记忆条目
│       │   └── Classification.swift   # AI 分类结果
│       │
│       ├── Services/                  # 业务服务层
│       │   ├── LLMService.swift       # FR2: Dashscope API
│       │   ├── VisionService.swift    # FR2: Apple Vision OCR
│       │   ├── KeychainService.swift  # API Key 安全存储
│       │   └── CloudKitService.swift  # iCloud 同步
│       │
│       ├── Components/                # 通用 UI 组件
│       │   ├── FeedbackToast.swift    # 操作反馈
│       │   ├── LoadingIndicator.swift # 加载状态
│       │   └── ErrorView.swift        # 错误展示
│       │
│       └── Extensions/                # Swift 扩展
│           ├── Date+Formatting.swift
│           └── String+Validation.swift
│
├── Resources/
│   ├── Info.plist                     # 应用配置
│   ├── AIAssistant.entitlements       # 权限声明
│   └── Assets.xcassets                # 图标资源
│
└── Tests/
    ├── UnitTests/
    │   ├── LLMServiceTests.swift
    │   └── ClassificationTests.swift
    └── UITests/
        └── CaptureFlowTests.swift
```

### 5.2 Architectural Boundaries

| 边界 | 规则 | 说明 |
|------|------|------|
| **Features → Shared** | ✅ 允许 | Features 可以引用 Shared 中的 Models/Services/Components |
| **Shared → Features** | ❌ 禁止 | Shared 必须保持独立，不依赖任何 Feature |
| **Feature → Feature** | ❌ 禁止 | Features 之间不能直接引用，通过 AppState 通信 |
| **Services → Models** | ✅ 允许 | Services 负责操作 Models |
| **Views → ViewModels** | ✅ 一对一 | 同目录放置，View 持有对应 ViewModel |

### 5.3 Requirements to Structure Mapping

| PRD 功能需求 | 对应目录 | 主要文件 |
|-------------|----------|----------|
| FR1: 快速捕获 | `Features/Capture/` | CaptureView, CaptureViewModel |
| FR2: AI 解析引擎 | `Shared/Services/` | LLMService, VisionService |
| FR3.1: 日历容器 | `Features/Calendar/` | CalendarView, CalendarViewModel |
| FR3.2: 待办容器 | `Features/Todo/` | TodoView, TodoViewModel |
| FR3.3: 笔记容器 | `Features/Notes/` | NotesView, NotesViewModel |
| FR4: Memory 系统 | `Features/Memory/` | MemoryView, MemoryViewModel |
| FR5: 视图展示 | 各 Feature View | + Shared/Components |

### 5.4 Integration Points

| 集成点 | 触发位置 | 目标服务 |
|--------|----------|----------|
| **全局快捷键** | AppDelegate | → CaptureView |
| **AI 分类** | CaptureViewModel | → LLMService |
| **图片 OCR** | CaptureViewModel | → VisionService |
| **数据存储** | 各 ViewModel | → SwiftData ModelContext |
| **iCloud 同步** | SwiftData | → CloudKit (自动) |
| **API Key 读取** | LLMService | → KeychainService |

## 6. Architecture Validation

### 6.1 PRD Requirements Coverage

| PRD 需求 | 架构支持 | 状态 |
|----------|----------|------|
| **FR1.1** 全局快捷键唤起 | KeyboardShortcuts + MenuBarExtra | ✅ |
| **FR1.2** 智能粘贴板 | CaptureViewModel 剪贴板监听 | ✅ |
| **FR1.3** 图片捕获 | VisionService (Apple Vision) | ✅ |
| **FR2.1** 自然语言解析 | LLMService (Dashscope) | ✅ |
| **FR2.2** 时间提取 | Classification.extractedTime | ✅ |
| **FR2.3** 智能分类 | ContainerType enum | ✅ |
| **FR3.x** 三大容器 | Calendar/Todo/Notes Features | ✅ |
| **FR4.x** Memory 系统 | Memory Feature + MemoryEntry | ✅ |
| **FR5.x** 视图展示 | 各 Feature View + Components | ✅ |

### 6.2 NFR Constraints Satisfaction

| NFR 约束 | 架构方案 | 状态 |
|----------|----------|------|
| **快捷键 <200ms** | 原生 SwiftUI + 预加载 | ✅ |
| **AI 响应 <2s** | Dashscope API + 异步处理 | ✅ |
| **内存 <200MB** | SwiftUI 原生，无 WebView | ✅ |
| **离线可用** | SwiftData 本地存储 | ✅ |
| **iCloud 同步** | SwiftData + CloudKit | ✅ |
| **App Store 合规** | 沙盒 + Entitlements | ✅ |
| **macOS 14+ / iOS 17+** | SwiftData 最低要求 | ✅ |

### 6.3 Technical Risk Assessment

| 风险 | 等级 | 缓解措施 |
|------|------|----------|
| Dashscope API 稳定性 | 中 | 错误重试 + 离线队列 |
| SwiftData 新框架 Bug | 低 | macOS 14+ 已稳定 |
| 全局快捷键冲突 | 低 | 用户可自定义 |

### 6.4 Architecture Decision Summary

| 决策类别 | 选择 | 说明 |
|----------|------|------|
| **框架** | SwiftUI Multiplatform | macOS + iOS 代码共享 |
| **数据库** | SwiftData + CloudKit | 原生集成，自动同步 |
| **LLM** | OpenAI SDK → Dashscope | 阿里云，兼容接口 |
| **OCR** | Apple Vision Framework | 免费、离线、中文 |
| **项目管理** | XcodeGen | AI 编程友好 |
| **架构模式** | Feature-based MVVM | 模块清晰 |
| **状态管理** | @Observable + @State | Swift 5.9+ |

---

**文档状态：** ✅ 已完成
**批准日期：** 2026-01-14
**批准人：** Henry

