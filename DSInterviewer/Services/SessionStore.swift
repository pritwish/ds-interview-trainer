import Foundation

/// Persists interview sessions to disk using JSON.
@MainActor
final class SessionStore: ObservableObject {
    @Published var sessions: [InterviewSession] = []

    private let fileURL: URL

    init() {
        let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.fileURL = documentsDir.appendingPathComponent("interview_sessions.json")
        load()
    }

    func save(_ session: InterviewSession) {
        if let idx = sessions.firstIndex(where: { $0.id == session.id }) {
            sessions[idx] = session
        } else {
            sessions.insert(session, at: 0)
        }
        persist()
    }

    func delete(_ session: InterviewSession) {
        sessions.removeAll { $0.id == session.id }
        persist()
    }

    func deleteAll() {
        sessions.removeAll()
        persist()
    }

    // MARK: - Persistence

    private func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        do {
            let data = try Data(contentsOf: fileURL)
            sessions = try JSONDecoder().decode([InterviewSession].self, from: data)
        } catch {
            print("Failed to load sessions: \(error)")
        }
    }

    private func persist() {
        do {
            let data = try JSONEncoder().encode(sessions)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("Failed to persist sessions: \(error)")
        }
    }
}
