import SwiftUI

struct StatusView: View {
    @Environment(WatchSessionManager.self) private var sessionManager

    var body: some View {
        List {
            Section("Connection") {
                HStack {
                    Image(systemName: connectionIcon)
                        .foregroundStyle(connectionColor)
                    Text(connectionStatus)
                }
            }

            Section("Sync") {
                HStack {
                    Text("Pending")
                    Spacer()
                    Text("\(sessionManager.pendingTransferCount)")
                        .foregroundStyle(.secondary)
                }

                if let lastSync = sessionManager.lastSyncTimestamp {
                    HStack {
                        Text("Last sync")
                        Spacer()
                        Text(lastSync, style: .relative)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Status")
    }

    private var connectionIcon: String {
        if sessionManager.isReachable {
            return "iphone.radiowaves.left.and.right"
        } else if sessionManager.isPaired {
            return "iphone"
        } else {
            return "iphone.slash"
        }
    }

    private var connectionColor: Color {
        if sessionManager.isReachable {
            return .green
        } else if sessionManager.isPaired {
            return .orange
        } else {
            return .red
        }
    }

    private var connectionStatus: String {
        if sessionManager.isReachable {
            return "Connected"
        } else if sessionManager.isPaired && sessionManager.isCompanionAppInstalled {
            return "iPhone not active"
        } else if sessionManager.isPaired {
            return "App not installed"
        } else {
            return "Not paired"
        }
    }
}

#Preview {
    NavigationStack {
        StatusView()
            .environment(WatchSessionManager())
    }
}
