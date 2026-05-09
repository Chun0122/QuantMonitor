import Charts
import SwiftUI

// MARK: - Regime Badge

struct RegimeBadge: View {
    let state: String?
    let label: String

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            Text(label)
                .font(.subheadline)
                .bold()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(color.opacity(0.15))
        .clipShape(Capsule())
    }

    private var color: Color {
        switch state {
        case "bull": return .green
        case "bear", "crisis": return .red
        case "sideways": return .yellow
        default: return .gray
        }
    }
}

// MARK: - Signal Row

struct SignalRow: View {
    let signal: SignalItem

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: signal.icon)
                .foregroundStyle(severityColor)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 4) {
                Text(signal.message)
                    .font(.subheadline)
                if let target = signal.target {
                    Text(target)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
        .padding()
        .background(severityColor.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var severityColor: Color {
        switch signal.severity {
        case "critical": return .red
        case "warning": return .orange
        default: return .gray
        }
    }
}

// MARK: - Discovery Item Card

struct DiscoveryItemCard: View {
    let item: DiscoveryItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("#\(item.rank)")
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.accentColor.opacity(0.2))
                    .clipShape(Capsule())
                Text(item.stockId).font(.subheadline).bold()
                Text(item.stockName ?? "—").font(.subheadline).foregroundStyle(.secondary)
                Spacer()
                if let score = item.compositeScore {
                    Text(String(format: "%.2f", score))
                        .font(.subheadline).bold()
                        .foregroundStyle(.tint)
                }
            }

            HStack(spacing: 8) {
                ScoreBar(label: "技", value: item.scores.technical)
                ScoreBar(label: "籌", value: item.scores.chip)
                ScoreBar(label: "基", value: item.scores.fundamental)
                ScoreBar(label: "消", value: item.scores.news)
            }

            HStack(spacing: 12) {
                if let entry = item.entry {
                    priceRow(label: "進場", value: entry, color: .blue)
                }
                if let sl = item.stopLoss {
                    priceRow(label: "止損", value: sl, color: .red)
                }
                if let tp = item.takeProfit {
                    priceRow(label: "止利", value: tp, color: .green)
                }
            }
            .font(.caption)

            if let industry = item.industry, !industry.isEmpty {
                HStack(spacing: 6) {
                    Text(industry)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(Capsule())
                    if let chip = item.chipTier {
                        Text(chip)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.purple.opacity(0.15))
                            .foregroundStyle(.purple)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func priceRow(label: String, value: Double, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).foregroundStyle(.secondary)
            Text(String(format: "%.2f", value)).bold().foregroundStyle(color)
        }
    }
}

// MARK: - Score Bar

struct ScoreBar: View {
    let label: String
    let value: Double?

    var body: some View {
        VStack(spacing: 2) {
            Text(label).font(.caption2).foregroundStyle(.secondary)
            ZStack(alignment: .bottom) {
                Rectangle()
                    .fill(Color(.tertiarySystemFill))
                    .frame(height: 30)
                if let v = value, v > 0 {
                    Rectangle()
                        .fill(barColor(v))
                        .frame(height: max(2, 30 * CGFloat(min(max(v, 0), 1))))
                }
            }
            .frame(width: 18)
            .clipShape(RoundedRectangle(cornerRadius: 2))
            Text(value.map { String(format: "%.2f", $0) } ?? "—")
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(.secondary)
        }
    }

    private func barColor(_ v: Double) -> Color {
        if v >= 0.7 { return .green }
        if v >= 0.4 { return .blue }
        return .gray
    }
}

// MARK: - Sparkline (持倉/Watch 列尾迷你走勢圖)

struct SparklineView: View {
    let values: [Double]
    var height: CGFloat = 28
    var width: CGFloat = 80

    var body: some View {
        Group {
            if values.count < 2 {
                Text("—")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(width: width, height: height, alignment: .trailing)
            } else {
                Chart {
                    ForEach(Array(values.enumerated()), id: \.offset) { idx, v in
                        LineMark(
                            x: .value("idx", idx),
                            y: .value("close", v)
                        )
                        .foregroundStyle(lineColor)
                        .lineStyle(StrokeStyle(lineWidth: 1.5))
                        .interpolationMethod(.linear)
                    }
                }
                .chartXAxis(.hidden)
                .chartYAxis(.hidden)
                .chartPlotStyle { plot in
                    plot.background(Color.clear)
                }
                .frame(width: width, height: height)
            }
        }
    }

    private var lineColor: Color {
        guard let first = values.first, let last = values.last, first != 0 else { return .gray }
        return last >= first ? .green : .red
    }
}

// MARK: - Performance Card (Today 分頁績效摘要)

struct PerformanceCard: View {
    let review: PortfolioReview

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("績效摘要", systemImage: "chart.line.uptrend.xyaxis")
                    .font(.headline)
                Spacer()
                if review.snapshotsCount > 0 {
                    Text("\(review.snapshotsCount) 日")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // 第一列：今日 / 本週 / 本月 / 累計
            HStack(spacing: 14) {
                metricCell(label: "今日", pct: review.todayPnlPct)
                metricCell(label: "本週", pct: review.wtdReturnPct)
                metricCell(label: "本月", pct: review.mtdReturnPct)
                metricCell(label: "累計", pct: review.totalReturnPct)
            }

            Divider()

            // 第二列：Sharpe / MDD / 勝率
            HStack(spacing: 14) {
                ratioCell(label: "Sharpe", value: review.sharpeRatio, format: "%.2f")
                ratioCell(label: "最大回撤", value: review.maxDrawdownPct.map { -$0 }, format: "%.1f%%", colorize: false, mutedNegative: true)
                ratioCell(label: "勝率", value: review.winRatePct, format: "%.0f%%", colorize: false)
            }
        }
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func metricCell(label: String, pct: Double?) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.caption).foregroundStyle(.secondary)
            if let p = pct {
                Text(String(format: "%+.2f%%", p * 100))
                    .font(.subheadline).bold()
                    .foregroundStyle(p >= 0 ? .green : .red)
            } else {
                Text("—")
                    .font(.subheadline).bold()
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func ratioCell(
        label: String,
        value: Double?,
        format: String,
        colorize: Bool = true,
        mutedNegative: Bool = false
    ) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.caption).foregroundStyle(.secondary)
            if let v = value {
                Text(String(format: format, v))
                    .font(.subheadline).bold()
                    .foregroundStyle(color(for: v, colorize: colorize, mutedNegative: mutedNegative))
            } else {
                Text("—")
                    .font(.subheadline).bold()
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func color(for v: Double, colorize: Bool, mutedNegative: Bool) -> Color {
        if mutedNegative { return .orange }
        if !colorize { return .primary }
        return v >= 0 ? .green : .red
    }
}
