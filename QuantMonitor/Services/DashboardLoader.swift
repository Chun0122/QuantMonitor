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
        // 從 fileImporter 拿到的 URL 是 security-scoped；
        // 建 bookmark 之前必須先 start，否則之後 resolve 拿不到存取權。
        let didStart = url.startAccessingSecurityScopedResource()
        defer {
            if didStart { url.stopAccessingSecurityScopedResource() }
        }
        do {
            let bookmark = try url.bookmarkData(
                options: [],
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
            state = .error("無法存取資料夾（可能 bookmark 失效或權限被撤銷）\n路徑：\(folderURL.path)\n→ 請按右上角「⋯」→「更換資料夾」重選")
            return
        }
        defer { folderURL.stopAccessingSecurityScopedResource() }

        let fileURL = folderURL.appendingPathComponent(dashboardFileName)

        // 預檢：檔案存在性 + 列出資料夾內容（協助診斷）
        let fm = FileManager.default
        if !fm.fileExists(atPath: fileURL.path) {
            let contents = (try? fm.contentsOfDirectory(atPath: folderURL.path)) ?? []
            let listing = contents.isEmpty ? "（空資料夾）" : contents.joined(separator: ", ")
            state = .error("找不到 latest.json\n資料夾：\(folderURL.lastPathComponent)\n內含：\(listing)\n→ 確認 Mac 端有跑 export-dashboard")
            return
        }

        do {
            // iCloud 檔案可能尚未下載到本機，先觸發下載
            try? fm.startDownloadingUbiquitousItem(at: fileURL)
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let snapshot = try decoder.decode(DashboardSnapshot.self, from: data)
            state = .loaded(snapshot, fromPath: fileURL.path, loadedAt: Date())

            if stale {
                // 書籤過期則重新存
                saveBookmark(for: folderURL)
            }
        } catch let DecodingError.keyNotFound(key, context) {
            state = .error("JSON 缺少必要欄位：\(key.stringValue)\n位置：\(context.codingPath.map(\.stringValue).joined(separator: "."))")
        } catch let DecodingError.typeMismatch(type, context) {
            state = .error("JSON 型別不符：\(type) 於 \(context.codingPath.map(\.stringValue).joined(separator: "."))\n→ Schema 版本可能不一致")
        } catch let DecodingError.valueNotFound(type, context) {
            state = .error("JSON 欄位值為 null：\(type) 於 \(context.codingPath.map(\.stringValue).joined(separator: "."))")
        } catch let DecodingError.dataCorrupted(context) {
            state = .error("JSON 格式錯誤：\(context.debugDescription)")
        } catch {
            state = .error("讀取失敗：\(error.localizedDescription)\n檔案：\(fileURL.path)")
        }
    }
}
