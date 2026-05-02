import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @EnvironmentObject var loader: DashboardLoader
    @State private var showingFolderPicker = false

    var body: some View {
        Group {
            switch loader.state {
            case .loaded(let snapshot, let path, let loadedAt):
                MainTabView(
                    snapshot: snapshot,
                    sourcePath: path,
                    loadedAt: loadedAt,
                    onPickFolder: { showingFolderPicker = true }
                )
            default:
                StatusView(onPickFolder: { showingFolderPicker = true })
            }
        }
        .fileImporter(
            isPresented: $showingFolderPicker,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    loader.saveBookmark(for: url)
                    loader.reload()
                }
            case .failure(let err):
                print("選擇失敗：\(err)")
            }
        }
    }
}

// ─────────────────────────────────────────────────────────────
// 主分頁（已載入時顯示）
// ─────────────────────────────────────────────────────────────

struct MainTabView: View {
    let snapshot: DashboardSnapshot
    let sourcePath: String
    let loadedAt: Date
    let onPickFolder: () -> Void

    var body: some View {
        TabView {
            TodayView(snapshot: snapshot, loadedAt: loadedAt, onPickFolder: onPickFolder)
                .tabItem { Label("今日", systemImage: "sun.max") }

            PositionsView(snapshot: snapshot)
                .tabItem { Label("持倉", systemImage: "chart.pie") }

            EventsView(events: snapshot.strategyEvents)
                .tabItem { Label("事件", systemImage: "clock.arrow.circlepath") }
        }
    }
}

// ─────────────────────────────────────────────────────────────
// 狀態畫面（idle / loading / error）
// ─────────────────────────────────────────────────────────────

struct StatusView: View {
    @EnvironmentObject var loader: DashboardLoader
    let onPickFolder: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: stateIcon)
                .font(.system(size: 64))
                .foregroundStyle(.tint)

            Text(stateTitle)
                .font(.title2)
                .bold()

            ScrollView {
                Text(stateDescription)
                    .font(.callout)
                    .foregroundStyle(isError ? .red : .secondary)
                    .multilineTextAlignment(.leading)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
            }
            .frame(maxHeight: 240)

            Spacer()

            Button {
                onPickFolder()
            } label: {
                Label("選擇 Dashboard 資料夾", systemImage: "folder.badge.plus")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.borderedProminent)

            if loader.hasBookmark {
                Button("重新載入") {
                    loader.reload()
                }
                .buttonStyle(.bordered)
            }

            Spacer()
        }
        .padding()
    }

    private var isError: Bool {
        if case .error = loader.state { return true }
        return false
    }

    private var stateIcon: String {
        switch loader.state {
        case .loading: return "arrow.triangle.2.circlepath"
        case .error: return "exclamationmark.triangle"
        default: return "icloud.and.arrow.down"
        }
    }

    private var stateTitle: String {
        switch loader.state {
        case .loading: return "載入中…"
        case .error: return "載入失敗"
        case .idle: return loader.hasBookmark ? "尚未載入" : "歡迎使用量化監控"
        case .loaded: return ""
        }
    }

    private var stateDescription: String {
        switch loader.state {
        case .error(let msg): return msg
        default:
            return "首次使用請選擇 iCloud Drive 中的「QuantDashboard」資料夾。" +
                   "App 會讀取資料夾內的 latest.json。"
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(DashboardLoader())
        .environmentObject(EventNoteStore())
}
