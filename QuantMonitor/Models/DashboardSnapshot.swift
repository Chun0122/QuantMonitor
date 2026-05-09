import Foundation

// MARK: - Top-level

struct DashboardSnapshot: Codable, Equatable {
    let version: Int
    let generatedAt: String
    let date: String
    let regime: RegimeBlock
    let discover: DiscoverBlock
    let rotation: RotationBlock?
    // v2 新增（多組 active 輪動陣列；舊版日報無此鍵時為 nil）
    let rotations: [RotationBlock]?
    let watchEntries: [WatchEntryItem]
    let signals: [SignalItem]
    let strategyEvents: [StrategyEventItem]
    let aiSummary: String?
    // v1.1 新增（向下相容；舊版日報無此鍵時為 nil）
    let portfolioReview: PortfolioReview?
    let positionTimeseries: PositionTimeseries?
    let errors: [String]

    /// v2 統一存取點：優先用 rotations 陣列，舊 JSON 退回 [rotation]。
    /// 永遠回傳 array（可能為空）。
    var allRotations: [RotationBlock] {
        if let rs = rotations, !rs.isEmpty {
            return rs
        }
        if let r = rotation {
            return [r]
        }
        return []
    }
}

// MARK: - Regime

struct RegimeBlock: Codable, Equatable {
    let state: String?
    let crisisTriggered: Bool
    let breadthDowngraded: Bool
    let breadthBelowMa20Pct: Double?
    let taiexClose: Double?
    let fastReturn5d: Double?
    let consecDeclineDays: Int?
    let volRatio: Double?
    let vixVal: Double?
    let usVixVal: Double?
    let summary: String

    var displayState: String {
        switch state {
        case "bull": return "多頭"
        case "bear": return "空頭"
        case "sideways": return "盤整"
        case "crisis": return "崩盤"
        default: return "未知"
        }
    }

    var stateColor: String {
        switch state {
        case "bull": return "green"
        case "bear", "crisis": return "red"
        case "sideways": return "yellow"
        default: return "gray"
        }
    }
}

// MARK: - Discover

struct DiscoverBlock: Codable, Equatable {
    let momentum: [DiscoveryItem]
    let swing: [DiscoveryItem]
    let value: [DiscoveryItem]
    let dividend: [DiscoveryItem]
    let growth: [DiscoveryItem]

    func items(for mode: DiscoveryMode) -> [DiscoveryItem] {
        switch mode {
        case .momentum: return momentum
        case .swing: return swing
        case .value: return value
        case .dividend: return dividend
        case .growth: return growth
        }
    }
}

enum DiscoveryMode: String, CaseIterable, Identifiable {
    case momentum, swing, value, dividend, growth
    var id: String { rawValue }
    var label: String {
        switch self {
        case .momentum: return "動能"
        case .swing: return "波段"
        case .value: return "價值"
        case .dividend: return "高息"
        case .growth: return "成長"
        }
    }
}

struct DiscoveryItem: Codable, Equatable, Identifiable {
    let rank: Int
    let stockId: String
    let stockName: String?
    let close: Double?
    let compositeScore: Double?
    let scores: ScoreBreakdown
    let entry: Double?
    let stopLoss: Double?
    let takeProfit: Double?
    let industry: String?
    let regime: String?
    let validUntil: String?
    let chipTier: String?
    let chipTierChange: String?
    let conceptBonus: Double?
    let daytradePenalty: Double?
    let entryTrigger: String?

    var id: String { "\(stockId)-\(rank)" }
}

struct ScoreBreakdown: Codable, Equatable {
    let technical: Double?
    let chip: Double?
    let fundamental: Double?
    let news: Double?
}

// MARK: - Rotation

struct RotationBlock: Codable, Equatable {
    let name: String
    let mode: String
    let maxPositions: Int
    let holdingDays: Int
    let allowRenewal: Bool
    let initialCapital: Double
    let currentCapital: Double
    let currentCash: Double
    let totalMarketValue: Double
    let totalUnrealizedPnl: Double
    let totalReturnPct: Double
    let status: String
    let updatedAt: String?
    let holdings: [RotationHolding]
}

struct RotationHolding: Codable, Equatable, Identifiable {
    let stockId: String
    let stockName: String?
    let entryDate: String?
    let entryPrice: Double
    let currentPrice: Double?
    let shares: Int
    let marketValue: Double?
    let unrealizedPnl: Double?
    let unrealizedPct: Double?
    let entryRank: Int?

    var id: String { stockId }

    var distanceColor: String {
        guard let pct = unrealizedPct else { return "gray" }
        return pct >= 0 ? "green" : "red"
    }
}

// MARK: - Watch

struct WatchEntryItem: Codable, Equatable, Identifiable {
    let id: Int
    let stockId: String
    let stockName: String?
    let entryDate: String?
    let entryPrice: Double
    let stopLoss: Double?
    let takeProfit: Double?
    let quantity: Int?
    let source: String
    let mode: String?
    let status: String
    let trailingStopEnabled: Bool
    let highestPriceSinceEntry: Double?
    let validUntil: String?
    let entryTrigger: String?
    let notes: String?
}

// MARK: - Signals

struct SignalItem: Codable, Equatable, Identifiable {
    let type: String
    let severity: String
    let message: String
    let target: String?

    var id: String { "\(type)-\(target ?? "")-\(message.prefix(40))" }

    var severityColor: String {
        switch severity {
        case "critical": return "red"
        case "warning": return "yellow"
        default: return "gray"
        }
    }

    var icon: String {
        switch type {
        case "crisis": return "exclamationmark.triangle.fill"
        case "bear_market": return "arrow.down.right.circle"
        case "breadth_downgrade": return "chart.line.downtrend.xyaxis"
        case "ic_decay": return "wand.and.rays"
        case "ic_failure": return "questionmark.diamond"
        case "data_stale": return "clock.badge.exclamationmark"
        case "kill_switch": return "stop.circle.fill"
        default: return "info.circle"
        }
    }
}

// MARK: - Strategy Events

struct StrategyEventItem: Codable, Equatable, Hashable, Identifiable {
    let date: String
    let type: String
    let summary: String
    let ref: String?
    let details: [String: AnyCodable]?

    var id: String { "\(type)-\(ref ?? date)" }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: StrategyEventItem, rhs: StrategyEventItem) -> Bool {
        lhs.id == rhs.id && lhs.summary == rhs.summary && lhs.date == rhs.date
    }

    var icon: String {
        switch type {
        case "git_commit": return "checkmark.seal"
        case "settings_diff": return "slider.horizontal.3"
        case "ic_auto_adjust": return "wand.and.stars"
        case "kill_switch": return "stop.circle.fill"
        default: return "doc.text"
        }
    }
}

// MARK: - Portfolio Review (v1.1)

struct PortfolioReview: Codable, Equatable {
    let todayPnlPct: Double?
    let wtdReturnPct: Double?
    let mtdReturnPct: Double?
    let totalReturnPct: Double?
    let sharpeRatio: Double?
    let maxDrawdownPct: Double?
    let winRatePct: Double?
    let snapshotsCount: Int
    let equityCurve: [EquityPoint]?
}

struct EquityPoint: Codable, Equatable, Identifiable {
    let date: String
    let capital: Double
    var id: String { date }
}

// MARK: - Position Timeseries (v1.1)

struct PositionTimeseries: Codable, Equatable {
    let tradingDays: [String]
    let series: [String: PositionSeries]

    /// 取出某檔股票的對齊（日期, 收盤）序列；找不到時為 nil。
    func points(for stockId: String) -> [(date: String, close: Double)]? {
        guard let s = series[stockId], !s.close.isEmpty else { return nil }
        let dates = Array(tradingDays.dropFirst(s.firstIdx))
        guard dates.count == s.close.count else {
            // first_idx 與長度不一致時取較短者
            let n = min(dates.count, s.close.count)
            return zip(dates.prefix(n), s.close.prefix(n)).map { ($0, $1) }
        }
        return zip(dates, s.close).map { ($0, $1) }
    }
}

struct PositionSeries: Codable, Equatable {
    let close: [Double]
    let firstIdx: Int
}

// MARK: - AnyCodable (for `details` heterogeneous values)

struct AnyCodable: Codable, Equatable {
    let value: Any

    init(_ value: Any) { self.value = value }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self.value = NSNull()
        } else if let v = try? container.decode(Bool.self) {
            self.value = v
        } else if let v = try? container.decode(Int.self) {
            self.value = v
        } else if let v = try? container.decode(Double.self) {
            self.value = v
        } else if let v = try? container.decode(String.self) {
            self.value = v
        } else if let v = try? container.decode([AnyCodable].self) {
            self.value = v.map { $0.value }
        } else if let v = try? container.decode([String: AnyCodable].self) {
            self.value = v.mapValues { $0.value }
        } else {
            self.value = NSNull()
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case is NSNull:
            try container.encodeNil()
        case let v as Bool:
            try container.encode(v)
        case let v as Int:
            try container.encode(v)
        case let v as Double:
            try container.encode(v)
        case let v as String:
            try container.encode(v)
        default:
            try container.encodeNil()
        }
    }

    static func == (lhs: AnyCodable, rhs: AnyCodable) -> Bool {
        // 結構性比較略——僅型別與字串值相等視為相等
        String(describing: lhs.value) == String(describing: rhs.value)
    }
}
