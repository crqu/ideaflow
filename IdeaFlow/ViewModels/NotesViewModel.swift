import Foundation

@Observable
final class NotesViewModel {
    private(set) var notes: [VoiceNote] = []
    private(set) var isProcessing = false

    private let noteProcessor: NoteProcessor
    private static let storageKey = "savedVoiceNotes"

    var pendingNotes: [VoiceNote] {
        notes.filter { $0.status == .pending }
    }

    var processingNotes: [VoiceNote] {
        notes.filter { $0.status == .processing }
    }

    var completedNotes: [VoiceNote] {
        notes.filter { $0.status == .completed }
    }

    var failedNotes: [VoiceNote] {
        notes.filter { $0.status == .failed }
    }

    var sortedNotes: [VoiceNote] {
        notes.sorted { $0.timestamp > $1.timestamp }
    }

    init(noteProcessor: NoteProcessor = NoteProcessor()) {
        self.noteProcessor = noteProcessor
        loadNotes()
    }

    func addNote(transcript: String) {
        let note = VoiceNote(transcript: transcript)
        notes.append(note)
        saveNotes()
        IdeaFlowLogger.storage.info("Added new note: \(note.id)")
    }

    func processNote(_ note: VoiceNote) async {
        guard let index = notes.firstIndex(where: { $0.id == note.id }) else {
            IdeaFlowLogger.storage.warning("Note not found for processing: \(note.id)")
            return
        }

        isProcessing = true
        notes[index].status = .processing
        saveNotes()

        let processedNote = await noteProcessor.process(note)

        if let updatedIndex = notes.firstIndex(where: { $0.id == processedNote.id }) {
            notes[updatedIndex] = processedNote
            saveNotes()
        }

        isProcessing = false
    }

    func processPendingNotes() async {
        let pending = pendingNotes
        for note in pending {
            await processNote(note)
        }
    }

    func deleteNote(_ note: VoiceNote) {
        notes.removeAll { $0.id == note.id }
        saveNotes()
        IdeaFlowLogger.storage.info("Deleted note: \(note.id)")
    }

    func deleteNotes(at offsets: IndexSet) {
        let sortedList = sortedNotes
        for index in offsets {
            let noteToDelete = sortedList[index]
            deleteNote(noteToDelete)
        }
    }

    func retryFailedNote(_ note: VoiceNote) async {
        guard note.status == .failed,
              let index = notes.firstIndex(where: { $0.id == note.id }) else {
            return
        }

        notes[index].status = .pending
        saveNotes()
        await processNote(notes[index])
    }

    private func loadNotes() {
        guard let data = UserDefaults.standard.data(forKey: Self.storageKey) else {
            IdeaFlowLogger.storage.info("No saved notes found")
            return
        }

        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            notes = try decoder.decode([VoiceNote].self, from: data)
            IdeaFlowLogger.storage.info("Loaded \(notes.count) notes")
        } catch {
            IdeaFlowLogger.storage.error("Failed to load notes: \(error)")
            notes = []
        }
    }

    private func saveNotes() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(notes)
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        } catch {
            IdeaFlowLogger.storage.error("Failed to save notes: \(error)")
        }
    }
}
