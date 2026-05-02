import SwiftUI

struct EventsView: View {
    let events: [StrategyEventItem]
    @EnvironmentObject var noteStore: EventNoteStore
    @State private var filter: EventFilter = .all

    enum EventFilter: String, CaseIterable, Identifiable {
        case all, gitCommit = "git_commit", settingsDiff = "settings_diff"
        var id: String { rawValue }
        var label: String {
            switch self {
            case .all: return "全部"
            case .gitCommit: return "Commits"
            case .settingsDiff: return "設定變動"
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Filter", selection: $filter) {
                    ForEach(EventFilter.allCases) { f in Text(f.label).tag(f) }
                }
                .pickerStyle(.segmented)
                .padding()

                if filteredEvents.isEmpty {
                    Spacer()
                    ContentUnavailableView(
                        "近期無事件",
                        systemImage: "clock",
                        description: Text("最近 30 天無 commits 或設定變動。")
                    )
                    Spacer()
                } else {
                    List {
                        ForEach(filteredEvents) { event in
                            NavigationLink(value: event) {
                                EventRow(event: event)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("事件流")
            .navigationDestination(for: StrategyEventItem.self) { event in
                EventDetailView(event: event)
            }
        }
    }

    private var filteredEvents: [StrategyEventItem] {
        guard filter != .all else { return events }
        return events.filter { $0.type == filter.rawValue }
    }
}

// ─────────────────────────────────────────────────────────────

struct EventRow: View {
    let event: StrategyEventItem
    @EnvironmentObject var noteStore: EventNoteStore

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: event.icon)
                .foregroundStyle(.tint)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(event.summary)
                    .font(.subheadline)
                    .lineLimit(2)
                HStack(spacing: 8) {
                    Text(event.date).font(.caption).foregroundStyle(.secondary)
                    if let ref = event.ref {
                        Text(ref)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                    let verdict = noteStore.note(for: event.id).verdict
                    if verdict != .unknown {
                        VerdictBadge(verdict: verdict)
                    }
                }
            }
        }
        .padding(.vertical, 2)
    }
}

// ─────────────────────────────────────────────────────────────

struct EventDetailView: View {
    let event: StrategyEventItem
    @EnvironmentObject var noteStore: EventNoteStore
    @State private var comment: String = ""

    var body: some View {
        Form {
            Section("摘要") {
                HStack(alignment: .top) {
                    Image(systemName: event.icon).foregroundStyle(.tint)
                    Text(event.summary).font(.body)
                }
                if let ref = event.ref {
                    LabeledContent("Ref") {
                        Text(ref).font(.system(.body, design: .monospaced))
                    }
                }
                LabeledContent("日期", value: event.date)
                LabeledContent("類型", value: event.type)
            }

            Section("結果判定") {
                Picker("判定", selection: Binding(
                    get: { noteStore.note(for: event.id).verdict },
                    set: { noteStore.setVerdict($0, for: event.id) }
                )) {
                    ForEach(EventNoteStore.Verdict.allCases) { v in
                        Text(v.label).tag(v)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("短評") {
                TextEditor(text: $comment)
                    .frame(minHeight: 120)
                    .onAppear {
                        comment = noteStore.note(for: event.id).comment
                    }
                    .onChange(of: comment) { _, newValue in
                        noteStore.setComment(newValue, for: event.id)
                    }
            }
        }
        .navigationTitle("事件詳情")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// ─────────────────────────────────────────────────────────────

struct VerdictBadge: View {
    let verdict: EventNoteStore.Verdict
    var body: some View {
        Text(verdict.label)
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.2))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
    private var color: Color {
        switch verdict {
        case .good: return .green
        case .bad: return .red
        case .uncertain: return .yellow
        case .unknown: return .gray
        }
    }
}
