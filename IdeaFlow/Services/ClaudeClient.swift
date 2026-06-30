import Foundation

enum ClaudeClientError: Error, Sendable {
    case noApiKey
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int, message: String)
    case decodingError(String)
    case networkError(Error)
    case rateLimited
    case serverError(Int)
}

actor ClaudeClient {
    private let baseURL = "https://api.anthropic.com/v1/messages"
    private let model = "claude-haiku-4-5-20251001"
    private let anthropicVersion = "2023-06-01"
    private let maxRetries = 3
    private let initialBackoffSeconds: Double = 1.0

    private let session: URLSession

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 120
        config.timeoutIntervalForResource = 120
        self.session = URLSession(configuration: config)
    }

    func processVoiceNote(_ transcript: String) async throws -> ClaudeProcessedNote {
        guard let apiKey = try KeychainHelper.getApiKey(), !apiKey.isEmpty else {
            IdeaFlowLogger.network.error("No API key found in Keychain")
            throw ClaudeClientError.noApiKey
        }

        let request = try buildRequest(transcript: transcript, apiKey: apiKey)

        var lastError: Error = ClaudeClientError.invalidResponse
        var backoff = initialBackoffSeconds

        for attempt in 1...maxRetries {
            IdeaFlowLogger.network.info("Claude API attempt \(attempt)/\(maxRetries)")
            let startTime = Date()

            do {
                let (data, response) = try await session.data(for: request)

                guard let httpResponse = response as? HTTPURLResponse else {
                    throw ClaudeClientError.invalidResponse
                }

                let duration = Date().timeIntervalSince(startTime)
                IdeaFlowLogger.network.networkResponse(
                    url: baseURL,
                    statusCode: httpResponse.statusCode,
                    duration: duration
                )

                switch httpResponse.statusCode {
                case 200:
                    return try parseResponse(data)
                case 429:
                    IdeaFlowLogger.network.warning("Rate limited, backing off \(backoff)s")
                    lastError = ClaudeClientError.rateLimited
                case 500...599:
                    IdeaFlowLogger.network.warning("Server error \(httpResponse.statusCode), backing off \(backoff)s")
                    lastError = ClaudeClientError.serverError(httpResponse.statusCode)
                default:
                    let message = String(data: data, encoding: .utf8) ?? "Unknown error"
                    IdeaFlowLogger.network.error("HTTP error \(httpResponse.statusCode): \(message)")
                    throw ClaudeClientError.httpError(statusCode: httpResponse.statusCode, message: message)
                }

                if attempt < maxRetries {
                    try await Task.sleep(for: .seconds(backoff))
                    backoff *= 2
                }
            } catch let error as ClaudeClientError {
                throw error
            } catch {
                IdeaFlowLogger.network.networkError(url: baseURL, error: error)
                lastError = ClaudeClientError.networkError(error)

                if attempt < maxRetries {
                    try await Task.sleep(for: .seconds(backoff))
                    backoff *= 2
                }
            }
        }

        throw lastError
    }

    private func buildRequest(transcript: String, apiKey: String) throws -> URLRequest {
        guard let url = URL(string: baseURL) else {
            throw ClaudeClientError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue(anthropicVersion, forHTTPHeaderField: "anthropic-version")

        let systemPrompt = """
            You are a helpful assistant that processes voice note transcripts. \
            Extract a clear title, polish the content into well-written prose, \
            identify relevant tags, and extract any action items mentioned. \
            Respond ONLY with valid JSON in this exact format:
            {"title": "...", "content": "...", "tags": ["..."], "action_items": ["..."]}
            """

        let userMessage = "Process this voice note transcript:\n\n\(transcript)"

        let apiRequest = ClaudeAPIRequest(
            model: model,
            maxTokens: 1024,
            messages: [ClaudeMessage(role: "user", content: userMessage)],
            system: systemPrompt
        )

        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(apiRequest)

        IdeaFlowLogger.network.networkRequest(url: baseURL, method: "POST")

        return request
    }

    private func parseResponse(_ data: Data) throws -> ClaudeProcessedNote {
        let decoder = JSONDecoder()

        let apiResponse: ClaudeAPIResponse
        do {
            apiResponse = try decoder.decode(ClaudeAPIResponse.self, from: data)
        } catch {
            IdeaFlowLogger.processing.error("Failed to decode Claude API response: \(error)")
            throw ClaudeClientError.decodingError("Failed to decode API response: \(error.localizedDescription)")
        }

        guard let textBlock = apiResponse.content.first(where: { $0.type == "text" }),
              let text = textBlock.text else {
            IdeaFlowLogger.processing.error("No text content in Claude response")
            throw ClaudeClientError.decodingError("No text content in response")
        }

        let processedNote: ClaudeProcessedNote
        do {
            guard let jsonData = text.data(using: .utf8) else {
                throw ClaudeClientError.decodingError("Failed to convert text to data")
            }
            processedNote = try decoder.decode(ClaudeProcessedNote.self, from: jsonData)
        } catch {
            IdeaFlowLogger.processing.error("Failed to parse Claude JSON output: \(error)")
            throw ClaudeClientError.decodingError("Failed to parse JSON from Claude: \(error.localizedDescription)")
        }

        IdeaFlowLogger.processing.info("Successfully processed note: \(processedNote.title)")
        return processedNote
    }
}
