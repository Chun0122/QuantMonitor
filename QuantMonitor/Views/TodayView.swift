import SwiftUI

struct TodayView: View {
    let snapshot: DashboardSnapshot
    let loadedAt: Date
    let onPickFolder: () -> Void

    @EnvironmentObject var loader: DashboardLoader
    @State private var showAISummary = false
    @State private var selectedMode: DiscoveryMode = .momentum

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    headerCard
                    if let review = snapshot.portfolioReview {
                        PerformanceCard(review: review)
                    }
                    if !snapshot.signals.isEmpty {
                        signalsSection
                    }
                    discoverSection
                    if let rotation = snapshot.rotation {
                        rotationSummary(rotation)
                    }
                    if let summary = snapshot.aiSummary, !summary.isEmpty {
                        aiSummarySection(summary)
                    }
                    footerNote
                }
                .padding()
            }
            .navigationTitle("今日")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("重新載入", systemImage: "arrow.clockwise") { loader.reload() }
                        Button("更換資料夾", systemImage: "folder", action: onPickFolder)
                        Button("清除書籤", systemImage: "trash", role: .destructive) {
                            loader.clearBookmark()
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .refreshable { loader.reload() }
        }
    }

    // ─────────────────────────────────────────────────────────────

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(snapshot.date)
                    .font(.title2)
                    .bold()
                Spacer()
                RegimeBadge(state: snapshot.regime.state, label: snapshot.regime.displayState)
            }

            Text(snapshot.regime.summary)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 16) {
                if let breadth = snapshot.regime.breadthBelowMa20Pct {
                    metricChip(label: "MA20寬度", value: percent(breadth))
                }
                if let vix = snapshot.regime.usVixVal, vix > 0 {
                    metricChip(label: "US VIX", value: String(format: "%.1f", vix))
                }
                if let ret5d = snapshot.regime.fastReturn5d {
                    metricChip(label: "5日報酬", value: percent(ret5d, signed: true))
                }
            }
        }
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var signalsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("⚠️ 異常訊號（\(snapshot.signals.count)）")
                .font(.headline)
            ForEach(snapshot.signals) { sig in
                SignalRow(signal: sig)
            }
        }
    }

    private var discoverSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("📊 五模式 Top 5")
                    .font(.headline)
                Spacer()
                Picker("Mode", selection: $selectedMode) {
                    ForEach(DiscoveryMode.allCases) { m in
                        Text(m.label).tag(m)
                    }
                }
                .pickerStyle(.menu)
            }

            let items = snapshot.discover.items(for: selectedMode).prefix(5)
            if items.isEmpty {
                Text("此模式今日無推薦（可能尚未跑 morning-routine）")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                ForEach(Array(items)) { item in
                    DiscoveryItemCard(item: item)
                }
            }
        }
    }

    private func rotationSummary(_ rot: RotationBlock) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("🔄 輪動組合：\(rot.name)")
                .font(.headline)

            HStack(spacing: 16) {
                metricChip(label: "資產", value: shortNumber(rot.currentCapital))
                metricChip(label: "報酬", value: percent(rot.totalReturnPct, signed: true),
                           color: rot.totalReturnPct >= 0 ? .green : .red)
                metricChip(label: "持倉", value: "\(rot.holdings.count)/\(rot.maxPositions)")
            }
        }
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func aiSummarySection(_ summary: String) -> some View {
        DisclosureGroup(isExpanded: $showAISummary) {
            Text(summary)
                .font(.body)
                .padding(.top, 8)
        } label: {
            Label("AI 摘要", systemImage: "sparkles")
                .font(.headline)
        }
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var footerNote: some View {
        Text("最後讀取：\(loadedAt.formatted(date: .omitted, time: .standard))")
            .font(.caption)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity)
    }

    // ─────────────────────────────────────────────────────────────

    private func metricChip(label: String, value: String, color: Color = .primary) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.subheadline).bold().foregroundStyle(color)
        }
    }

    private func percent(_ v: Double?, signed: Bool = false) -> String {
        guard let v else { return "—" }
        let pct = v * 100
        return signed ? String(format: "%+.1f%%", pct) : String(format: "%.0f%%", pct)
    }

    private func shortNumber(_ v: Double) -> String {
        if abs(v) >= 1_000_000 {
            return String(format: "%.2fM", v / 1_000_000)
        } else if abs(v) >= 1_000 {
            return String(format: "%.0fK", v / 1_000)
        }
        return String(format: "%.0f", v)
    }
}
