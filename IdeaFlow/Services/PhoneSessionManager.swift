import Foundation
import WatchConnectivity

@Observable
final class PhoneSessionManager: NSObject, WCSessionDelegate {
    private(set) var receivedNotesCount: Int = 0
    private(set) var lastReceivedTimestamp: Date?

    private let session: WCSession
    private var onNoteReceived: ((VoiceNote) -> Void)?

    override init() {
        self.session = WCSession.default
        super.init()

        if WCSession.isSupported() {
            session.delegate = self
            session.activate()
            IdeaFlowLogger.sync.info("PhoneSessionManager initialized, activating session")
        } else {
            IdeaFlowLogger.sync.warning("WCSession not supported on this device")
        }
    }

    func setNoteReceivedHandler(_ handler: @escaping (VoiceNote) -> Void) {
        onNoteReceived = handler
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            IdeaFlowLogger.sync.error("Session activation failed: \(error.localizedDescription)")
            return
        }
        IdeaFlowLogger.sync.info("Session activated with state: \(activationState.rawValue)")
    }

    func sessionDidBecomeInactive(_ session: WCSession) {
        IdeaFlowLogger.sync.info("Session became inactive")
    }

    func sessionDidDeactivate(_ session: WCSession) {
        IdeaFlowLogger.sync.info("Session deactivated, reactivating")
        session.activate()
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
        guard let idString = userInfo["id"] as? String,
              let id = UUID(uuidString: idString),
              let transcript = userInfo["transcript"] as? String,
              let timestamp = userInfo["timestamp"] as? TimeInterval else {
            IdeaFlowLogger.sync.error("Invalid userInfo received: \(userInfo)")
            return
        }

        let note = VoiceNote(
            id: id,
            transcript: transcript,
            timestamp: Date(timeIntervalSince1970: timestamp)
        )

        IdeaFlowLogger.sync.info("Received note from Watch: \(id.uuidString)")

        DispatchQueue.main.async { [weak self] in
            self?.receivedNotesCount += 1
            self?.lastReceivedTimestamp = Date()
            self?.onNoteReceived?(note)
        }
    }
}
