import SwiftUI
import SwiftData
import Combine
import UniformTypeIdentifiers

/// 快速捕获视图
struct CaptureView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel = CaptureViewModel()
    @FocusState private var isInputFocused: Bool

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // 输入区域
                inputArea

                // 图片预览（如有）
                if let image = viewModel.capturedImage {
                    imagePreview(image)
                }

                // 状态栏
                statusBar
            }

            // 成功反馈遮罩
            if viewModel.showSuccess {
                successOverlay
            }
        }
        .frame(width: 400)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.2), radius: 20)
        .onKeyPress(.return, phases: .down) { event in
            // 检查是否有修饰键（Shift 用于换行）
            if event.modifiers.contains(.shift) {
                return .ignored // 让系统处理换行
            }
            // 按 Enter 提交
            Task {
                await submitCapture()
            }
            return .handled
        }
        .onExitCommand {
            dismiss()
        }
        .onAppear {
            isInputFocused = true
            // 自动粘贴剪贴板内容（如果为空且剪贴板有文本）
            if viewModel.inputText.isEmpty {
                checkAndPasteClipboard()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.willBecomeActiveNotification)) { _ in
            // 应用激活时检查剪贴板
            if viewModel.inputText.isEmpty {
                checkAndPasteClipboard()
            }
        }
        .onPasteCommand(of: [.image, .tiff, .png]) { providers in
            // 处理图片粘贴
            for provider in providers {
                provider.loadDataRepresentation(forTypeIdentifier: "public.image") { data, _ in
                    if let data = data, let image = NSImage(data: data) {
                        Task { @MainActor in
                            viewModel.capturedImage = image
                        }
                    }
                }
            }
        }
    }

    /// 检查并粘贴剪贴板内容（文本或图片）
    private func checkAndPasteClipboard() {
        let pasteboard = NSPasteboard.general

        // 优先检查图片
        if let imageData = pasteboard.data(forType: .tiff) ?? pasteboard.data(forType: .png),
           let image = NSImage(data: imageData) {
            viewModel.capturedImage = image
            return
        }

        // 检查文本
        if let text = pasteboard.string(forType: .string), !text.isEmpty {
            // 只自动粘贴较短的文本（避免粘贴大段代码等）
            if text.count <= 500 {
                viewModel.inputText = text
            }
        }
    }

    // MARK: - 输入区域
    private var inputArea: some View {
        VStack(spacing: 0) {
            TextEditor(text: $viewModel.inputText)
                .font(.body)
                .scrollContentBackground(.hidden)
                .background(.clear)
                .frame(minHeight: 80, maxHeight: 200)
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .focused($isInputFocused)

            if viewModel.inputText.isEmpty {
                Text("输入想法，或按 ⌘+V 粘贴...")
                    .font(.body)
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .allowsHitTesting(false)
                    .offset(y: -60)
            }
        }
    }

    // MARK: - 图片预览
    private func imagePreview(_ image: NSImage) -> some View {
        HStack {
            Image(nsImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxHeight: 100)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            Button {
                viewModel.capturedImage = nil
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    // MARK: - 成功反馈遮罩
    private var successOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)

            VStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.green)
                    .symbolEffect(.bounce, value: viewModel.showSuccess)

                Text("已捕获")
                    .font(.headline)
                    .foregroundStyle(.white)
            }
        }
        .transition(.opacity.combined(with: .scale))
    }

    // MARK: - 状态栏
    private var statusBar: some View {
        HStack {
            if viewModel.isProcessing {
                ProgressView()
                    .scaleEffect(0.7)
                Text("处理中...")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("Enter 发送 · ⇧Enter 换行")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            Text("⌘V 粘贴")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
    }

    // MARK: - 提交捕获
    private func submitCapture() async {
        guard !viewModel.inputText.isEmpty || viewModel.capturedImage != nil else {
            return
        }

        viewModel.isProcessing = true
        defer { viewModel.isProcessing = false }

        do {
            var contentText = viewModel.inputText
            var imageURL: URL? = nil

            // 如果有图片，执行 OCR
            if let image = viewModel.capturedImage {
                // 保存图片到沙盒
                imageURL = try await saveImageToSandbox(image)

                // OCR 识别图片中的文字
                let ocrText = try await VisionService.shared.recognizeText(from: image)
                if !ocrText.isEmpty {
                    if contentText.isEmpty {
                        contentText = ocrText
                    } else {
                        contentText += "\n\n[图片文字识别]\n\(ocrText)"
                    }
                }
            }

            // 创建捕获项
            let capture = CaptureItem(
                content: contentText,
                imageURL: imageURL,
                status: .pending
            )

            modelContext.insert(capture)
            try modelContext.save()

            // 异步触发 AI 分类（不阻塞 UI）
            let captureId = capture.id
            let context = modelContext
            Task { @MainActor in
                await Self.classifyCapture(captureId: captureId, in: context)
            }

            // 显示成功反馈（带动画）
            withAnimation(.spring(duration: 0.3)) {
                viewModel.showSuccess = true
            }

            // 清空输入
            viewModel.inputText = ""
            viewModel.capturedImage = nil

            // 延迟关闭
            try await Task.sleep(for: .seconds(0.6))
            CaptureWindowController.shared.hideWindow()

            // 重置状态以便下次打开
            viewModel.showSuccess = false

        } catch {
            viewModel.error = AIAssistantError.storageError(error.localizedDescription)
        }
    }

    /// 保存图片到沙盒
    private func saveImageToSandbox(_ image: NSImage) async throws -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let capturesFolder = documentsPath.appendingPathComponent("Captures", isDirectory: true)

        // 创建目录（如果不存在）
        try FileManager.default.createDirectory(at: capturesFolder, withIntermediateDirectories: true)

        // 生成唯一文件名
        let fileName = "\(UUID().uuidString).png"
        let fileURL = capturesFolder.appendingPathComponent(fileName)

        // 转换并保存图片
        guard let tiffData = image.tiffRepresentation,
              let bitmapRep = NSBitmapImageRep(data: tiffData),
              let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
            throw AIAssistantError.storageError("无法转换图片格式")
        }

        try pngData.write(to: fileURL)
        return fileURL
    }

    /// 异步分类捕获项
    @MainActor
    private static func classifyCapture(captureId: UUID, in context: ModelContext) async {
        guard LLMService.shared.isConfigured else {
            return // AI 未配置，跳过分类
        }

        // 通过 ID 查找捕获项
        let descriptor = FetchDescriptor<CaptureItem>(
            predicate: #Predicate { $0.id == captureId }
        )

        guard let capture = try? context.fetch(descriptor).first else {
            return
        }

        do {
            // 使用带 Memory 上下文的分类
            let classification = try await LLMService.shared.classifyWithMemory(
                capture.content,
                in: context
            )

            // 使用转换服务应用分类结果
            ContainerConversionService.shared.autoConvert(
                capture,
                classification: classification,
                in: context
            )

            try context.save()
        } catch {
            capture.status = .failed
            try? context.save()
        }
    }
}

// MARK: - ViewModel
@Observable
@MainActor
class CaptureViewModel {
    var inputText: String = ""
    var capturedImage: NSImage?
    var isProcessing: Bool = false
    var showSuccess: Bool = false
    var error: AIAssistantError?
}

#Preview {
    CaptureView()
        .environment(AppState())
        .modelContainer(DataContainer.previewContainer)
}
