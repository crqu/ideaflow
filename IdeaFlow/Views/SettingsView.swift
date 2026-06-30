import SwiftUI

struct SettingsView: View {
    @State private var apiKeyInput = ""
    @State private var hasApiKey = false
    @State private var vaultPath: String = ""
    @State private var showingFilePicker = false
    @State private var showingAlert = false
    @State private var alertMessage = ""

    private let obsidianWriter = ObsidianWriter()

    var body: some View {
        NavigationStack {
            List {
                apiKeySection
                vaultSection
            }
            .navigationTitle("Settings")
            .task {
                await loadSettings()
            }
            .fileImporter(
                isPresented: $showingFilePicker,
                allowedContentTypes: [.folder],
                allowsMultipleSelection: false
            ) { result in
                handleFolderSelection(result)
            }
            .alert("Settings", isPresented: $showingAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
        }
    }

    private var apiKeySection: some View {
        Section {
            if hasApiKey {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("API key saved")
                    Spacer()
                    Button("Delete", role: .destructive) {
                        deleteApiKey()
                    }
                    .buttonStyle(.borderless)
                }
            } else {
                SecureField("Enter Claude API key", text: $apiKeyInput)
                    .textContentType(.password)
                    .autocorrectionDisabled()

                Button("Save API Key") {
                    saveApiKey()
                }
                .disabled(apiKeyInput.isEmpty)
            }
        } header: {
            Text("Claude API")
        } footer: {
            Text("Get your API key from console.anthropic.com")
        }
    }

    private var vaultSection: some View {
        Section {
            if !vaultPath.isEmpty {
                HStack {
                    Image(systemName: "folder.fill")
                        .foregroundStyle(.blue)
                    Text(vaultPath)
                        .lineLimit(2)
                        .font(.caption)
                }

                Button("Change Vault") {
                    showingFilePicker = true
                }

                Button("Remove Vault", role: .destructive) {
                    Task {
                        await clearVault()
                    }
                }
            } else {
                Button {
                    showingFilePicker = true
                } label: {
                    HStack {
                        Image(systemName: "folder.badge.plus")
                        Text("Select Obsidian Vault")
                    }
                }
            }
        } header: {
            Text("Obsidian Vault")
        } footer: {
            Text("Notes will be saved to the 'voice-notes' folder in your vault")
        }
    }

    private func loadSettings() async {
        hasApiKey = (try? KeychainHelper.getApiKey()) != nil

        if let url = await obsidianWriter.vaultURL {
            vaultPath = url.path
        }
    }

    private func saveApiKey() {
        guard !apiKeyInput.isEmpty else { return }

        do {
            try KeychainHelper.saveApiKey(apiKeyInput)
            hasApiKey = true
            apiKeyInput = ""
            alertMessage = "API key saved successfully"
            showingAlert = true
        } catch {
            alertMessage = "Failed to save API key: \(error.localizedDescription)"
            showingAlert = true
        }
    }

    private func deleteApiKey() {
        do {
            try KeychainHelper.deleteApiKey()
            hasApiKey = false
            alertMessage = "API key deleted"
            showingAlert = true
        } catch {
            alertMessage = "Failed to delete API key: \(error.localizedDescription)"
            showingAlert = true
        }
    }

    private func handleFolderSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }

            guard url.startAccessingSecurityScopedResource() else {
                alertMessage = "Unable to access selected folder"
                showingAlert = true
                return
            }

            defer { url.stopAccessingSecurityScopedResource() }

            Task {
                await obsidianWriter.setVaultURL(url)
                vaultPath = url.path
                alertMessage = "Vault folder set successfully"
                showingAlert = true
            }

        case .failure(let error):
            alertMessage = "Failed to select folder: \(error.localizedDescription)"
            showingAlert = true
        }
    }

    private func clearVault() async {
        await obsidianWriter.clearVaultURL()
        vaultPath = ""
    }
}

#Preview {
    SettingsView()
}
