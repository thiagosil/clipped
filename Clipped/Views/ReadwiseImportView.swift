import SwiftUI

struct ReadwiseImportView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var apiKeyInput = ""
    @State private var isValidating = false
    @State private var validationResult: ValidationResult?
    @State private var isImporting = false
    @State private var importProgress: ReadwiseImportProgress?
    @State private var importTask: Task<Void, Never>?
    @State private var selectedLocation: ReadwiseLocation = .later

    enum ValidationResult {
        case success
        case failure(String)
    }

    enum ReadwiseLocation: String, CaseIterable {
        case new = "new"
        case later = "later"
        case shortlist = "shortlist"
        case archive = "archive"

        var displayName: String {
            switch self {
            case .new: return "Inbox"
            case .later: return "Later"
            case .shortlist: return "Shortlist"
            case .archive: return "Archive"
            }
        }

        var description: String {
            switch self {
            case .new: return "Unseen articles"
            case .later: return "Saved for later"
            case .shortlist: return "Priority reading"
            case .archive: return "Already read"
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Import from Readwise")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Theme.listText)

                Spacer()

                Button(action: {
                    importTask?.cancel()
                    dismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(Theme.listSecondaryText)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 12)

            Divider()
                .background(Theme.sidebarDivider)

            // Content
            VStack(alignment: .leading, spacing: 16) {
                if isImporting {
                    importProgressView
                } else {
                    apiKeyInputView
                }
            }
            .padding(20)
        }
        .frame(width: 420, height: 360)
        .background(Theme.listBackground)
        .onAppear {
            if let savedKey = appState.readwiseSettings.apiKey {
                apiKeyInput = savedKey
                // Automatically validate saved key
                testConnection()
            }
        }
        .onDisappear {
            importTask?.cancel()
        }
    }

    // MARK: - API Key Input View

    private var apiKeyInputView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Enter your Readwise Reader API key to import articles.")
                .font(.system(size: 12))
                .foregroundColor(Theme.listSecondaryText)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 6) {
                Text("API Key")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Theme.listSecondaryText)

                SecureField("Enter your API key", text: $apiKeyInput)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .foregroundColor(Theme.listText)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(Theme.searchBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Theme.searchBorder, lineWidth: 1)
                    )
            }

            Link(destination: URL(string: "https://readwise.io/access_token")!) {
                HStack(spacing: 4) {
                    Text("Get your API key")
                        .font(.system(size: 11))
                    Image(systemName: "arrow.up.right.square")
                        .font(.system(size: 10))
                }
                .foregroundColor(Theme.accent)
            }

            if validationResult?.isSuccess == true {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Import from")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Theme.listSecondaryText)

                    HStack(spacing: 8) {
                        ForEach(ReadwiseLocation.allCases, id: \.self) { location in
                            Button(action: {
                                selectedLocation = location
                            }) {
                                VStack(spacing: 2) {
                                    Text(location.displayName)
                                        .font(.system(size: 11, weight: .medium))
                                    Text(location.description)
                                        .font(.system(size: 9))
                                        .foregroundColor(selectedLocation == location ? .white.opacity(0.8) : Theme.listTertiaryText)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .frame(maxWidth: .infinity)
                                .background(selectedLocation == location ? Theme.accent : Theme.searchBackground)
                                .foregroundColor(selectedLocation == location ? .white : Theme.listText)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    if let lastImport = appState.readwiseSettings.lastImportDate(for: selectedLocation.rawValue) {
                        HStack(spacing: 4) {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: 10))
                            Text("Last import: \(lastImport, style: .relative) ago")
                                .font(.system(size: 10))
                            Text("• Only new articles will be fetched")
                                .font(.system(size: 10))
                                .foregroundColor(Theme.listTertiaryText)
                        }
                        .foregroundColor(Theme.listSecondaryText)
                    }
                }
            }

            if let result = validationResult {
                statusView(for: result)
            }

            Spacer()

            HStack(spacing: 12) {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.plain)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Theme.listSecondaryText)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Theme.searchBackground)
                .clipShape(RoundedRectangle(cornerRadius: 6))

                Spacer()

                if validationResult?.isSuccess == true {
                    Button(action: startImport) {
                        Text("Import from \(selectedLocation.displayName)")
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Theme.progressComplete)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }

                Button(action: testConnection) {
                    HStack(spacing: 6) {
                        if isValidating {
                            ProgressView()
                                .scaleEffect(0.7)
                                .frame(width: 12, height: 12)
                        }
                        Text(isValidating ? "Testing..." : "Test Connection")
                    }
                }
                .buttonStyle(.plain)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(apiKeyInput.isEmpty ? Theme.accent.opacity(0.5) : Theme.accent)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .disabled(apiKeyInput.isEmpty || isValidating)
            }
        }
    }

    // MARK: - Import Progress View

    private var importProgressView: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Importing Articles")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Theme.listText)

                if let progress = importProgress {
                    Text(progress.statusText)
                        .font(.system(size: 12))
                        .foregroundColor(Theme.listSecondaryText)

                    if let percentage = progress.progressPercentage {
                        ProgressView(value: percentage, total: 100)
                            .progressViewStyle(LinearProgressViewStyle(tint: Theme.accent))

                        HStack {
                            Text("\(progress.fetchedCount) articles")
                                .font(.system(size: 11))
                                .foregroundColor(Theme.listTertiaryText)

                            Spacer()

                            Text("\(Int(percentage))%")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(Theme.listSecondaryText)
                        }
                    } else {
                        ProgressView()
                            .progressViewStyle(LinearProgressViewStyle(tint: Theme.accent))
                    }

                    if case .rateLimited(let seconds) = progress.status {
                        HStack(spacing: 6) {
                            Image(systemName: "clock.fill")
                                .font(.system(size: 12))
                            Text("Rate limited. Waiting \(seconds) seconds...")
                                .font(.system(size: 12))
                        }
                        .foregroundColor(.orange)
                        .padding(.top, 8)
                    }

                    if case .completed = progress.status {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 14))
                                Text("Import completed!")
                                    .font(.system(size: 13, weight: .medium))
                            }
                            .foregroundColor(Theme.progressComplete)

                            if progress.newCount > 0 || progress.skippedCount > 0 {
                                HStack(spacing: 12) {
                                    if progress.newCount > 0 {
                                        Label("\(progress.newCount) new", systemImage: "plus.circle.fill")
                                            .font(.system(size: 11))
                                            .foregroundColor(Theme.progressComplete)
                                    }
                                    if progress.skippedCount > 0 {
                                        Label("\(progress.skippedCount) existed", systemImage: "arrow.right.circle.fill")
                                            .font(.system(size: 11))
                                            .foregroundColor(Theme.listSecondaryText)
                                    }
                                }
                            } else if progress.fetchedCount == 0 {
                                Text("No new articles since last import")
                                    .font(.system(size: 11))
                                    .foregroundColor(Theme.listSecondaryText)
                            }
                        }
                        .padding(.top, 8)
                    }

                    if case .failed(let message) = progress.status {
                        HStack(spacing: 6) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 14))
                            Text(message)
                                .font(.system(size: 12))
                        }
                        .foregroundColor(Theme.accent)
                        .padding(.top, 8)
                    }
                } else {
                    ProgressView()
                        .progressViewStyle(LinearProgressViewStyle(tint: Theme.accent))
                    Text("Starting import...")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.listSecondaryText)
                }
            }

            Spacer()

            HStack {
                Spacer()

                if importProgress?.status.isCompleted == true {
                    Button("Done") {
                        dismiss()
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(Theme.progressComplete)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                } else {
                    Button("Cancel") {
                        importTask?.cancel()
                        isImporting = false
                        importProgress = nil
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Theme.listSecondaryText)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Theme.searchBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
        }
    }

    @ViewBuilder
    private func statusView(for result: ValidationResult) -> some View {
        HStack(spacing: 8) {
            switch result {
            case .success:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(Theme.progressComplete)
                Text("Connection successful")
                    .foregroundColor(Theme.progressComplete)
            case .failure(let message):
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(Theme.accent)
                Text(message)
                    .foregroundColor(Theme.accent)
            }
        }
        .font(.system(size: 12))
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            result.isSuccess ? Theme.progressComplete.opacity(0.1) : Theme.accent.opacity(0.1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    // MARK: - Actions

    private func testConnection() {
        isValidating = true
        validationResult = nil

        Task {
            do {
                let service = ReadwiseService()
                let isValid = try await service.validateAPIKey(apiKeyInput)
                await MainActor.run {
                    isValidating = false
                    if isValid {
                        validationResult = .success
                        appState.readwiseSettings.apiKey = apiKeyInput
                    }
                }
            } catch {
                await MainActor.run {
                    isValidating = false
                    validationResult = .failure(error.localizedDescription)
                }
            }
        }
    }

    private func startImport() {
        guard !apiKeyInput.isEmpty else { return }
        guard let folderPath = appState.folderSettings.folderPath else {
            importProgress = ReadwiseImportProgress(
                totalCount: nil,
                fetchedCount: 0,
                currentPage: 0,
                status: .failed("No folder selected. Please select a folder first.")
            )
            return
        }

        isImporting = true
        importProgress = nil

        // Record the start time before fetching
        let importStartTime = Date()
        let lastImportDate = appState.readwiseSettings.lastImportDate(for: selectedLocation.rawValue)

        importTask = Task {
            do {
                let service = ReadwiseService()
                let documents = try await service.fetchAllDocuments(
                    apiKey: apiKeyInput,
                    category: "article",
                    location: selectedLocation.rawValue,
                    updatedAfter: lastImportDate
                ) { progress in
                    Task { @MainActor in
                        self.importProgress = progress
                    }
                }

                // Convert and save documents
                var newCount = 0
                var skippedCount = 0
                var processedCount = 0

                for document in documents {
                    if Task.isCancelled { break }

                    await MainActor.run {
                        self.importProgress = ReadwiseImportProgress(
                            totalCount: documents.count,
                            fetchedCount: processedCount,
                            currentPage: 0,
                            status: .converting(articleTitle: document.title ?? "Untitled"),
                            newCount: newCount,
                            skippedCount: skippedCount
                        )
                    }

                    if let markdown = await service.convertToMarkdown(document: document) {
                        let title = document.title ?? "Untitled-\(document.id)"
                        let filename = service.sanitizeFilename(title) + ".md"
                        let fileURL = URL(fileURLWithPath: folderPath).appendingPathComponent(filename)

                        // Skip if file already exists
                        if !FileManager.default.fileExists(atPath: fileURL.path) {
                            do {
                                try markdown.write(to: fileURL, atomically: true, encoding: .utf8)
                                newCount += 1
                            } catch {
                                print("Failed to write file: \(error)")
                            }
                        } else {
                            skippedCount += 1
                        }
                    }
                    processedCount += 1
                }

                await MainActor.run {
                    self.importProgress = ReadwiseImportProgress(
                        totalCount: documents.count,
                        fetchedCount: processedCount,
                        currentPage: 0,
                        status: .completed,
                        newCount: newCount,
                        skippedCount: skippedCount
                    )

                    // Save the import timestamp for incremental imports
                    appState.readwiseSettings.setLastImportDate(importStartTime, for: selectedLocation.rawValue)

                    // Refresh the article list
                    Task {
                        await appState.loadArticles()
                    }
                }
            } catch {
                if !Task.isCancelled {
                    await MainActor.run {
                        self.importProgress = ReadwiseImportProgress(
                            totalCount: nil,
                            fetchedCount: 0,
                            currentPage: 0,
                            status: .failed(error.localizedDescription)
                        )
                    }
                }
            }
        }
    }
}

extension ReadwiseImportView.ValidationResult {
    var isSuccess: Bool {
        if case .success = self { return true }
        return false
    }
}

extension ReadwiseImportProgress.Status {
    var isCompleted: Bool {
        if case .completed = self { return true }
        return false
    }
}
