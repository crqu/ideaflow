import Foundation
import WatchConnectivity
import WatchKit

@Observable
final class WatchSessionManager: NSObject, WCSessionDelegate {
    private(set) var pendingTransferCount: Int = 0
    private(set) var isReachable: Bool = false
    private(set) var isPaired: Bool = false
    private(set) var isCompanionAppInstalled: Bool = false
    private(set) var lastSyncTimestamp: Date?
    private(set) var lastSentNoteId: UUID?

    private let session: WCSession

    override init() {
        self.session = WCSession.default
        super.init()

        if WCSession.isSupported() {
            session.delegate = self
            session.activate()
            IdeaFlowLogger.sync.info("WatchSessionManager initialized, activating session")
        } else {
            IdeaFlowLogger.sync.warning("WCSession not supported on this device")
        }
    }

    func sendVoiceNote(_ transcript: String) {
        guard !transcript.isEmpty else {
            IdeaFlowLogger.sync.warning("Attempted to send empty transcript")
            return
        }

        let noteId = UUID()
        let timestamp = Date().timeIntervalSince1970

        let userInfo: [String: Any] = [
            "id": noteId.uuidString,
            "transcript": transcript,
            "timestamp": timestamp
        ]

        session.transferUserInfo(userInfo)
        pendingTransferCount += 1
        lastSentNoteId = noteId

        IdeaFlowLogger.sync.info("Queued note for transfer: \(noteId.uuidString)")

        WKInterfaceDevice.current().play(.success)
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            IdeaFlowLogger.sync.error("Session activation failed: \(error.localizedDescription)")
            return
        }

        DispatchQueue.main.async { [weak self] in
            self?.updateConnectionStatus()
        }

        IdeaFlowLogger.sync.info("Session activated with state: \(activationState.rawValue)")
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async { [weak self] in
            self?.updateConnectionStatus()
        }
        IdeaFlowLogger.sync.info("Reachability changed: \(session.isReachable)")
    }

    func session(_ session: WCSession, didFinish userInfoTransfer: WCSessionUserInfoTransfer, error: Error?) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            if let error = error {
                IdeaFlowLogger.sync.error("Transfer failed: \(error.localizedDescription)")
            } else {
                self.pendingTransferCount = max(0, self.pendingTransferCount - 1)
                self.lastSyncTimestamp = Date()
                IdeaFlowLogger.sync.info("Transfer completed successfully")
            }
        }
    }

    private func updateConnectionStatus() {
        isReachable = session.isReachable
        isPaired = session.isPaired
        isCompanionAppInstalled = session.isCompanionAppInstalled
        pendingTransferCount = session.outstandingUserInfoTransfers.count
    }
}
