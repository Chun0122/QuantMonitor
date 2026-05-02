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
