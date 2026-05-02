import Foundation
import Combine

@MainActor
final class DashboardLoader: ObservableObject {

    enum LoadState: Equatable {
        case idle
        case loading
        case loaded(DashboardSnapshot, fromPath: String, loadedAt: Date)
        case error(String)
    }

    @Published var state: LoadState = .idle

    private let bookmarkKey = "QuantDashboardFolderBookmark"
    private let dashboardFileName = "latest.json"

    // ─────────────────────────────────────────────────────────────
    // 公開 API
    // ─────────────────────────────────────────────────────────────

    var hasBookmark: Bool {
        UserDefaults.standard.data(forKey: bookmarkKey) != nil
    }

    func saveBookmark(for url: URL) {
        do {
            let bookmark = try url.bookmarkData(
                options: .minimalBookmark,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            UserDefaults.standard.set(bookmark, forKey: bookmarkKey)
        } catch {
            state = .error("書籤儲存失敗：\(error.localizedDescription)")
        }
    }

    func clearBookmark() {
        UserDefaults.standard.removeObject(forKey: bookmarkKey)
        state = .idle
    }

    func reload() {
        state = .loading
        Task { await loadFromBookmark() }
    }

    // ─────────────────────────────────────────────────────────────
    // 內部
    // ─────────────────────────────────────────────────────────────

    private func loadFromBookmark() async {
        guard let bookmark = UserDefaults.standard.data(forKey: bookmarkKey) else {
            state = .error("尚未選擇 Dashboard 資料夾")
            return
        }

        var stale = false
        let folderURL: URL
        do {
            folderURL = try URL(
                resolvingBookmarkData: bookmark,
                options: [],
                relativeTo: nil,
                bookmarkDataIsStale: &stale
            )
        } catch {
            state = .error("無法解析資料夾書籤：\(error.localizedDescription)")
            return
        }

        guard folderURL.startAccessingSecurityScopedResource() else {
            state = .error("無法存取資料夾（權限被撤銷？請重選資料夾）")
            return
        }
        defer { folderURL.stopAccessingSecurityScopedResource() }

        let fileURL = folderURL.appendingPathComponent(dashboardFileName)

        do {
            // 強制刷新檔案（iCloud 可能還沒下載）
            try? FileManager.default.startDownloadingUbiquitousItem(at: fileURL)
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let snapshot = try decoder.decode(DashboardSnapshot.self, from: data)
            state = .loaded(snapshot, fromPath: fileURL.path, loadedAt: Date())

            if stale {
                // 書籤過期則重新存
                saveBookmark(for: folderURL)
            }
        } catch {
            state = .error("讀取或解析失敗：\(error.localizedDescription)")
        }
    }
}
