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

    /// 键盘事件监听器
    @State private var eventMonitor: Any?

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
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
        .shadow(color: .black.opacity(0.15), radius: 12, y: 4)
        .onAppear {
            isInputFocused = true
            setupKeyboardMonitor()
        }
        .onDisappear {
            removeKeyboardMonitor()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didResignKeyNotification)) { _ in
            // 失去焦点时，如果内容为空则自动关闭
            if viewModel.inputText.isEmpty && viewModel.capturedImage == nil {
                closeWindow()
            }
        }
    }

    // MARK: - 统一关闭入口
    private func closeWindow() {
        CaptureWindowController.shared.hideWindow()
    }

    /// 设置键盘监听器（ESC 关闭 + Cmd+V 粘贴）
    private func setupKeyboardMonitor() {
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [self] event in
            // ESC 键关闭窗口
            if event.keyCode == 53 {
                closeWindow()
                return nil
            }
            // Cmd+V 粘贴图片
            if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers == "v" {
                if handleImagePaste() {
                    return nil
                }
            }
            return event
        }
    }

    /// 移除键盘监听器
    private func removeKeyboardMonitor() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }

    // MARK: - 输入区域
    private var inputArea: some View {
        TextField("输入想法，或按 ⌘+V 粘贴...", text: $viewModel.inputText, axis: .vertical)
            .textFieldStyle(.plain)
            .font(.body)
            .lineLimit(1...10)
            .frame(minHeight: 80)
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .focused($isInputFocused)
            .onSubmit {
                // Enter 提交
                if canSubmit && !viewModel.isProcessing {
                    Task {
                        await submitCapture()
                    }
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
                Text("⌘V 粘贴")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            // 提交按钮
            Button {
                Task {
                    await submitCapture()
                }
            } label: {
                HStack(spacing: 4) {
                    Text("发送")
                    Image(systemName: "arrow.up.circle.fill")
                }
                .font(.caption)
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(canSubmit ? Color.accentColor : Color.gray)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .disabled(!canSubmit)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
    }

    private var canSubmit: Bool {
        !viewModel.inputText.isEmpty || viewModel.capturedImage != nil
    }

    /// 处理剪贴板图片粘贴
    private func handleImagePaste() -> Bool {
        let pasteboard = NSPasteboard.general
        guard let types = pasteboard.types else { return false }

        // 尝试从文件 URL 读取图片
        if types.contains(.fileURL),
           let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL],
           let url = urls.first,
           let image = NSImage(contentsOf: url) {
            viewModel.capturedImage = image
            return true
        }

        // 尝试从直接的图片数据读取
        for type in [NSPasteboard.PasteboardType.tiff, .png] where types.contains(type) {
            if let data = pasteboard.data(forType: type),
               let image = NSImage(data: data) {
                viewModel.capturedImage = image
                return true
            }
        }

        return false
    }

    // MARK: - 提交捕获
    @MainActor
    private func submitCapture() async {
        guard canSubmit else { return }

        viewModel.isProcessing = true
        defer { viewModel.isProcessing = false }

        do {
            var contentText = viewModel.inputText
            var imageURL: URL?

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
