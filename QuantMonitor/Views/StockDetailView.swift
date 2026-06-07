import SwiftUI

// MARK: - entry_breakdown 取值 helper（值已被 convertFromSnakeCase 轉 camelCase）

private extension Dictionary where Key == String, Value == AnyCodable {
    func double(_ key: String) -> Double? {
        switch self[key]?.value {
        case let d as Double: return d
        case let i as Int: return Double(i)
        default: return nil
        }
    }

    func int(_ key: String) -> Int? {
        switch self[key]?.value {
        case let i as Int: return i
        case let d as Double: return Int(d)
        default: return nil
        }
    }

    func string(_ key: String) -> String? { self[key]?.value as? String }

    /// 巢狀 scores 字典（decode 後為 [String: Any]）。
    func nestedScores() -> [String: Double] {
        guard let raw = self["scores"]?.value as? [String: Any] else { return [:] }
        var out: [String: Double] = [:]
        for (k, v) in raw {
            if let d = v as? Double { out[k] = d }
            else if let i = v as? Int { out[k] = Double(i) }
        }
        return out
    }
}

// MARK: - 個股詳細頁

struct StockDetailView: View {
    let stockId: String
    let stockName: String?
    var contextLabel: String?            // 「輪動組合：X」或「推薦 #N」
    var entryPrice: Double?
    var currentPrice: Double?
    var stopLoss: Double?
    var takeProfit: Double?
    var unrealizedPnl: Double?
    var unrealizedPct: Double?
    var entryRank: Int?
    var entryDate: String?
    var discoveryScores: ScoreBreakdown?     // discovery 直接帶
    var entryBreakdown: [String: AnyCodable]?  // holding 凍結理由
    var todayAction: RotationAction?
    var sparkline: [Double] = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                if let action = todayAction {
                    todayActionCard(action)
                }
                priceCard
                if !sparkline.isEmpty {
                    sparkCard
                }
                scoreCard
            }
            .padding()
        }
        .navigationTitle(stockId)
        .navigationBarTitleDisplayMode(.inline)
    }

    // ── header ──
    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Text(stockId).font(.title2).bold()
                Text(stockName ?? "—").font(.title3).foregroundStyle(.secondary)
                Spacer()
                if let pct = unrealizedPct {
                    Text(String(format: "%+.2f%%", pct * 100))
                        .font(.title3).bold()
                        .foregroundStyle(pct >= 0 ? .green : .red)
                }
            }
            if let ctx = contextLabel {
                Text(ctx).font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    // ── 今日操作 ──
    private func todayActionCard(_ action: RotationAction) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("今日操作").font(.headline)
            RotationActionRow(action: action)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // ── 價格 ──
    private var priceCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("價格").font(.headline)
            HStack(spacing: 16) {
                priceCell("進場", entryPrice, .blue)
                priceCell("現價", currentPrice, .primary)
                priceCell("止損", stopLoss, .red)
                priceCell("止利", takeProfit, .green)
            }
            HStack(spacing: 16) {
                if let pnl = unrealizedPnl {
                    metaCell("未實現", String(format: "%+,.0f", pnl), pnl >= 0 ? .green : .red)
                }
                if let rank = entryRank {
                    metaCell("進場排名", "#\(rank)", .primary)
                }
                if let d = entryDate {
                    metaCell("進場日", d, .secondary)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var sparkCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("近期走勢").font(.headline)
            SparklineView(values: sparkline, height: 120, width: 320)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // ── 評分（為什麼選這檔）──
    @ViewBuilder private var scoreCard: some View {
        let pairs = scorePairs
        if !pairs.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("選股評分").font(.headline)
                HStack(spacing: 12) {
                    ForEach(pairs, id: \.0) { pair in
                        ScoreBar(label: pair.0, value: pair.1)
                    }
                }
                if let meta = breakdownMeta {
                    Text(meta).font(.caption).foregroundStyle(.secondary)
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    private var scorePairs: [(String, Double?)] {
        if let s = discoveryScores {
            return [("技", s.technical), ("籌", s.chip), ("基", s.fundamental), ("消", s.news)]
        }
        if let b = entryBreakdown {
            let s = b.nestedScores()
            if !s.isEmpty {
                return [("技", s["technical"]), ("籌", s["chip"]), ("基", s["fundamental"]), ("消", s["news"])]
            }
        }
        return []
    }

    private var breakdownMeta: String? {
        guard let b = entryBreakdown else { return nil }
        var parts: [String] = []
        if let comp = b.double("compositeScore") { parts.append(String(format: "綜合 %.2f", comp)) }
        if let mode = b.string("mode") { parts.append("模式 \(mode)") }
        if let regime = b.string("regime") { parts.append("在 \(regime) 時發現") }
        if let tier = b.string("chipTier") { parts.append("籌碼 \(tier)") }
        if let scan = b.string("scanDate") { parts.append(scan) }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    // ── cells ──
    private func priceCell(_ label: String, _ value: Double?, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.caption).foregroundStyle(.secondary)
            Text(value.map { String(format: "%.2f", $0) } ?? "—").bold().foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func metaCell(_ label: String, _ value: String, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.subheadline).bold().foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - 便利建構

extension StockDetailView {
    /// 由輪動持倉建立。
    init(holding: RotationHolding, rotationName: String, action: RotationAction?, sparkline: [Double]) {
        self.init(
            stockId: holding.stockId,
            stockName: holding.stockName,
            contextLabel: "輪動組合：\(rotationName)",
            entryPrice: holding.entryPrice,
            currentPrice: holding.currentPrice,
            stopLoss: nil,
            takeProfit: nil,
            unrealizedPnl: holding.unrealizedPnl,
            unrealizedPct: holding.unrealizedPct,
            entryRank: holding.entryRank,
            entryDate: holding.entryDate,
            discoveryScores: nil,
            entryBreakdown: holding.entryBreakdown,
            todayAction: action,
            sparkline: sparkline
        )
    }

    /// 由 discover 推薦建立。
    init(discovery item: DiscoveryItem, sparkline: [Double]) {
        self.init(
            stockId: item.stockId,
            stockName: item.stockName,
            contextLabel: "推薦 #\(item.rank)",
            entryPrice: item.entry,
            currentPrice: item.close,
            stopLoss: item.stopLoss,
            takeProfit: item.takeProfit,
            unrealizedPnl: nil,
            unrealizedPct: nil,
            entryRank: item.rank,
            entryDate: nil,
            discoveryScores: item.scores,
            entryBreakdown: nil,
            todayAction: nil,
            sparkline: sparkline
        )
    }
}
