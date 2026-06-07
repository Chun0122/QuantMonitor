import Charts
import SwiftUI

// MARK: - 共用日期解析

enum ChartDate {
    static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "Asia/Taipei")
        return f
    }()

    static func parse(_ s: String) -> Date? { formatter.date(from: s) }
}

// MARK: - 權益曲線（PerformanceCard 用）

struct EquityCurveChart: View {
    let points: [EquityPoint]
    var height: CGFloat = 140

    private var parsed: [(date: Date, capital: Double)] {
        points.compactMap { p in
            guard let d = ChartDate.parse(p.date) else { return nil }
            return (d, p.capital)
        }
    }

    var body: some View {
        Group {
            if parsed.count < 2 {
                Text("資料不足，無法繪製權益曲線")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 60)
            } else {
                Chart(parsed, id: \.date) { item in
                    LineMark(
                        x: .value("日期", item.date),
                        y: .value("權益", item.capital)
                    )
                    .foregroundStyle(lineColor)
                    .interpolationMethod(.monotone)

                    AreaMark(
                        x: .value("日期", item.date),
                        y: .value("權益", item.capital)
                    )
                    .foregroundStyle(lineColor.opacity(0.12))
                    .interpolationMethod(.monotone)
                }
                .chartYScale(domain: .automatic(includesZero: false))
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.month().day())
                    }
                }
                .frame(height: height)
            }
        }
    }

    private var lineColor: Color {
        guard let first = parsed.first?.capital, let last = parsed.last?.capital, first != 0 else { return .gray }
        return last >= first ? .green : .red
    }
}

// MARK: - 超額報酬 vs 0050（跨組合多線）

struct AlphaChartView: View {
    let chart: AlphaChart
    var height: CGFloat = 200

    private struct Row: Identifiable {
        let id: String
        let date: Date
        let name: String
        let alpha: Double
    }

    private var rows: [Row] {
        chart.series.compactMap { p in
            guard let alpha = p.alphaCumPct, let d = ChartDate.parse(p.date) else { return nil }
            return Row(id: p.id, date: d, name: p.name, alpha: alpha * 100)
        }
    }

    var body: some View {
        Group {
            if rows.count < 2 {
                Text("尚無足夠 alpha 資料")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 60)
            } else {
                Chart {
                    RuleMark(y: .value("基準", 0))
                        .foregroundStyle(.secondary.opacity(0.4))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))

                    ForEach(rows) { row in
                        LineMark(
                            x: .value("日期", row.date),
                            y: .value("超額%", row.alpha)
                        )
                        .foregroundStyle(by: .value("組合", row.name))
                        .interpolationMethod(.monotone)
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let v = value.as(Double.self) {
                                Text("\(Int(v))%")
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.month().day())
                    }
                }
                .chartLegend(position: .bottom, spacing: 8)
                .frame(height: height)
            }
        }
    }
}
