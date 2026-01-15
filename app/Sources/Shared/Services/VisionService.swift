import Foundation
import Vision
import AppKit

/// Vision 服务 - 负责 OCR 图片识别
@MainActor
final class VisionService {
    /// 单例
    static let shared = VisionService()

    private init() {}

    /// 识别图片中的文字
    func recognizeText(from image: NSImage) async throws -> String {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw AIAssistantError.ocrFailed("无法转换图片格式")
        }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: AIAssistantError.ocrFailed(error.localizedDescription))
                    return
                }

                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: "")
                    return
                }

                let recognizedStrings = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }

                continuation.resume(returning: recognizedStrings.joined(separator: "\n"))
            }

            // 配置识别选项
            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["zh-Hans", "zh-Hant", "en-US"]
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: AIAssistantError.ocrFailed(error.localizedDescription))
            }
        }
    }

    /// 从 URL 加载图片并识别
    func recognizeText(from url: URL) async throws -> String {
        guard let image = NSImage(contentsOf: url) else {
            throw AIAssistantError.ocrFailed("无法加载图片")
        }
        return try await recognizeText(from: image)
    }
}
