import Foundation
import Combine

/// 事件短評本地儲存（UserDefaults，不上傳）。key = strategy event id。
@MainActor
final class EventNoteStore: ObservableObject {

    enum Verdict: String, Codable, CaseIterable, Identifiable {
        case unknown, good, bad, uncertain
        var id: String { rawValue }
        var label: String {
            switch self {
            case .unknown: return "未判定"
            case .good: return "好"
            case .bad: return "壞"
            case .uncertain: return "不確定"
            }
        }
        var color: String {
            switch self {
            case .good: return "green"
            case .bad: return "red"
            case .uncertain: return "yellow"
            case .unknown: return "gray"
            }
        }
    }

    struct Note: Codable, Equatable {
        var verdict: Verdict
        var comment: String
        var updatedAt: Date

        static let empty = Note(verdict: .unknown, comment: "", updatedAt: Date())
    }

    @Published private var notes: [String: Note] = [:]

    private let storeKey = "QuantEventNotes_v1"

    init() {
        load()
    }

    func note(for eventId: String) -> Note {
        notes[eventId] ?? .empty
    }

    func setNote(_ note: Note, for eventId: String) {
        notes[eventId] = note
        persist()
    }

    func setVerdict(_ verdict: Verdict, for eventId: String) {
        var current = notes[eventId] ?? .empty
        current.verdict = verdict
        current.updatedAt = Date()
        notes[eventId] = current
        persist()
    }

    func setComment(_ comment: String, for eventId: String) {
        var current = notes[eventId] ?? .empty
        current.comment = comment
        current.updatedAt = Date()
        notes[eventId] = current
        persist()
    }

    // ─────────────────────────────────────────────────────────────

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storeKey) else { return }
        if let decoded = try? JSONDecoder().decode([String: Note].self, from: data) {
            notes = decoded
        }
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(notes) {
            UserDefaults.standard.set(data, forKey: storeKey)
        }
    }
}
