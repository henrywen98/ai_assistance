import Testing
@testable import AIAssistant

/// AppState 单元测试
/// Story 1.1 占位测试，后续 Story 将扩展
@Suite("AppState Tests")
struct AppStateTests {

    @Test("AppState 初始化状态正确")
    @MainActor
    func testInitialState() async throws {
        let appState = AppState()

        #expect(appState.isCaptureWindowVisible == false)
        #expect(appState.selectedContainer == nil)
        #expect(appState.isProcessing == false)
    }

    @Test("ContainerType 枚举值正确")
    func testContainerTypes() {
        #expect(ContainerType.allCases.count == 3)
        #expect(ContainerType.calendar.rawValue == "calendar")
        #expect(ContainerType.todo.rawValue == "todo")
        #expect(ContainerType.note.rawValue == "note")
    }

    @Test("ContainerType displayName 正确")
    func testContainerDisplayNames() {
        #expect(ContainerType.calendar.displayName == "日历")
        #expect(ContainerType.todo.displayName == "待办")
        #expect(ContainerType.note.displayName == "笔记")
    }
}
