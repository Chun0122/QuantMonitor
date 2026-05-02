# QuantMonitor

iOS 量化監控 App — 讀取 [taiwan-quant-project](../taiwan-quant-project) 產出的 `daily_dashboard.json`，提供今日狀態 / 持倉 / 事件流三個 Tab。

## 系統需求

- macOS（Apple Silicon 或 Intel 皆可）
- Xcode 15+（**首次開啟 Xcode 26.4 後**會提示下載 iOS Platform 元件，按 Settings → Components 下載 ~5GB 即可）
- iOS 17.0+ 部署目標
- Apple ID（免費 Developer 帳號即可上 Simulator；上實機需個人開發者）

## 首次設定

```bash
# 1. 安裝 xcodegen（用 project.yml 重新產生 .xcodeproj，避免維護脆弱的 pbxproj XML）
brew install xcodegen

# 2. 產生 Xcode 專案
cd ~/Projects/QuantMonitor
xcodegen

# 3. 開啟
open QuantMonitor.xcodeproj
```

**首次開啟 Xcode 提示下載 iOS Platform：**
- Xcode 跳出 "iOS 26.4 is not installed" → 按 `Get` 下載（首次約 5GB，有後台下載 UI）
- 下載完成 Xcode 自動 reload，左上角裝置選單會出現 Simulator

之後若 `project.yml` 或檔案結構有變動，重新跑 `xcodegen` 即可。

## 在 Simulator / 實機跑起來

1. Xcode 開啟後選擇 Target = `QuantMonitor`、Scheme = `QuantMonitor`
2. 上方裝置選單選一台 iPhone Simulator（例 iPhone 15）
3. ⌘R 執行
4. App 會跳出空狀態頁，按「選擇 Dashboard 資料夾」
5. 在檔案選擇器中：
   - **Simulator**：先把 `~/Library/Mobile Documents/com~apple~CloudDocs/QuantDashboard/` 拖進 Simulator 建立可見路徑
   - **實機**：開啟「檔案」App → iCloud Drive → 找到 `QuantDashboard` 資料夾
6. 選擇後 App 會自動讀取 `latest.json` 並渲染三個 Tab

## 資料來源

App 不做任何運算；資料來源：

- **Mac 側**：`python main.py morning-routine` 或 `export-dashboard` 子命令產出 JSON
- **預設 iCloud 路徑**：`~/Library/Mobile Documents/com~apple~CloudDocs/QuantDashboard/`
- **App 端**：用 `UIDocumentPickerViewController` 拿安全範圍書籤，下次啟動自動讀取

詳細 JSON schema 見 `taiwan-quant-project/docs/dashboard_schema.md`。

## 三 Tab 結構

| Tab | 內容 | 資料來源 |
|-----|-----|---------|
| **今日 Today** | Regime 燈號、異常訊號、五模式 Top 5、輪動摘要、AI 摘要 | `regime` / `signals` / `discover` / `rotation` / `ai_summary` |
| **持倉 Positions** | 輪動持倉 + Watch entries | `rotation.holdings` / `watch_entries` |
| **事件 Events** | git commits + settings 變動時間軸 + 短評 | `strategy_events`（讀取） + UserDefaults（短評，本地） |

## 已知限制（v0.1）

- App Icon 是空 placeholder — 之後可加圖
- 事件短評只存本地（UserDefaults），不上傳
- 沒有推播 / Widget / 鎖定畫面 — v2 加
- 「持倉」分頁的歷史走勢圖未實作（schema 中的 close 序列尚未匯出）

## 修改檔案結構後

如果新增 / 刪除 Swift 檔案，重跑 `xcodegen` 讓 `.xcodeproj` 同步：

```bash
cd ~/Projects/QuantMonitor
xcodegen
```

## License

私人專案，未公開發行。
