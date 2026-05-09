import SwiftUI

struct PositionsView: View {
    let snapshot: DashboardSnapshot

    @State private var selectedRotationName: String?

    private var rotations: [RotationBlock] { snapshot.allRotations }

    private var selectedRotation: RotationBlock? {
        guard !rotations.isEmpty else { return nil }
        if let name = selectedRotationName,
           let match = rotations.first(where: { $0.name == name }) {
            return match
        }
        return rotations.first
    }

    var body: some View {
        NavigationStack {
            List {
                if rotations.count > 1 {
                    Section {
                        Picker("組合", selection: Binding(
                            get: { selectedRotation?.name ?? rotations.first!.name },
                            set: { selectedRotationName = $0 }
                        )) {
                            ForEach(rotations, id: \.name) { rot in
                                Text(rot.name).tag(rot.name)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 8, trailing: 0))
                }

                if let rotation = selectedRotation {
                    Section {
                        ForEach(rotation.holdings) { holding in
                            RotationHoldingRow(
                                holding: holding,
                                sparkline: sparklineValues(for: holding.stockId)
                            )
                        }
                    } header: {
                        HStack {
                            Text("輪動組合：\(rotation.name)")
                            Spacer()
                            Text("\(rotation.holdings.count) / \(rotation.maxPositions)")
                                .foregroundStyle(.secondary)
                        }
                    } footer: {
                        Text("總報酬 \(formatPct(rotation.totalReturnPct, signed: true)) | 未實現 \(formatNum(rotation.totalUnrealizedPnl))")
                    }
                }

                if !snapshot.watchEntries.isEmpty {
                    Section("監控持倉（\(snapshot.watchEntries.count)）") {
                        ForEach(snapshot.watchEntries) { entry in
                            WatchEntryRow(
                                entry: entry,
                                sparkline: sparklineValues(for: entry.stockId)
                            )
                        }
                    }
                }

                if rotations.isEmpty && snapshot.watchEntries.isEmpty {
                    ContentUnavailableView(
                        "尚無持倉",
                        systemImage: "tray",
                        description: Text("建立 rotation 組合或新增 watch entry 後會在此顯示。")
                    )
                }
            }
            .navigationTitle("持倉")
        }
    }

    private func sparklineValues(for stockId: String) -> [Double] {
        guard let ts = snapshot.positionTimeseries,
              let series = ts.series[stockId]
        else { return [] }
        return series.close
    }

    private func formatPct(_ v: Double, signed: Bool = false) -> String {
        let pct = v * 100
        return signed ? String(format: "%+.2f%%", pct) : String(format: "%.2f%%", pct)
    }

    private func formatNum(_ v: Double) -> String {
        String(format: "%+,.0f", v)
    }
}

// ─────────────────────────────────────────────────────────────

struct RotationHoldingRow: View {
    let holding: RotationHolding
    var sparkline: [Double] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(holding.stockId)
                    .font(.headline)
                Text(holding.stockName ?? "—")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                if let pct = holding.unrealizedPct {
                    Text(String(format: "%+.2f%%", pct * 100))
                        .font(.subheadline)
                        .bold()
                        .foregroundStyle(pct >= 0 ? .green : .red)
                }
            }

            HStack(spacing: 12) {
                priceChip(label: "進場", value: holding.entryPrice)
                if let cur = holding.currentPrice {
                    priceChip(label: "現價", value: cur)
                }
                priceChip(label: "股數", intValue: holding.shares)
                if let pnl = holding.unrealizedPnl {
                    priceChip(label: "未實現", value: pnl, color: pnl >= 0 ? .green : .red)
                }
                Spacer()
                if !sparkline.isEmpty {
                    SparklineView(values: sparkline)
                }
            }
            .font(.caption)
        }
        .padding(.vertical, 4)
    }

    private func priceChip(label: String, value: Double, color: Color = .primary) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(label).foregroundStyle(.secondary)
            Text(String(format: "%.2f", value)).bold().foregroundStyle(color)
        }
    }

    private func priceChip(label: String, intValue: Int) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(label).foregroundStyle(.secondary)
            Text("\(intValue)").bold()
        }
    }
}

// ─────────────────────────────────────────────────────────────

struct WatchEntryRow: View {
    let entry: WatchEntryItem
    var sparkline: [Double] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(entry.stockId).font(.headline)
                Text(entry.stockName ?? "—").font(.subheadline).foregroundStyle(.secondary)
                Spacer()
                StatusBadge(status: entry.status)
            }
            HStack(spacing: 12) {
                Text("進場 \(String(format: "%.2f", entry.entryPrice))")
                if let sl = entry.stopLoss {
                    Text("止損 \(String(format: "%.2f", sl))").foregroundStyle(.red)
                }
                if let tp = entry.takeProfit {
                    Text("止利 \(String(format: "%.2f", tp))").foregroundStyle(.green)
                }
                if let qty = entry.quantity {
                    Text("\(qty) 股").foregroundStyle(.secondary)
                }
                Spacer()
                if !sparkline.isEmpty {
                    SparklineView(values: sparkline)
                }
            }
            .font(.caption)

            if let trigger = entry.entryTrigger, !trigger.isEmpty {
                Text(trigger)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct StatusBadge: View {
    let status: String
    var body: some View {
        Text(label)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(color.opacity(0.2))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
    private var label: String {
        switch status {
        case "active": return "持倉中"
        case "stopped_loss": return "已止損"
        case "taken_profit": return "已止利"
        case "expired": return "已過期"
        case "closed": return "已平倉"
        default: return status
        }
    }
    private var color: Color {
        switch status {
        case "active": return .blue
        case "stopped_loss": return .red
        case "taken_profit": return .green
        case "expired": return .orange
        default: return .gray
        }
    }
}
