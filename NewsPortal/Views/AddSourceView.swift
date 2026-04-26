import SwiftUI

struct AddSourceView: View {
    @ObservedObject var store: SourceStore
    @Environment(\.dismiss) private var dismiss

    @State private var urlString = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    private let pageFetcher: PageFetching

    init(store: SourceStore, pageFetcher: PageFetching = PageFetcher()) {
        self.store = store
        self.pageFetcher = pageFetcher
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("Add News Source")
                .font(.headline)

            TextField("https://example.com", text: $urlString)
                .textFieldStyle(.roundedBorder)
                .onSubmit { addSource() }

            if let errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .font(.caption)
            }

            HStack {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Add") { addSource() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(urlString.isEmpty || isLoading)
            }

            if isLoading {
                ProgressView()
                    .controlSize(.small)
            }
        }
        .padding(20)
        .frame(width: 400)
    }

    private func addSource() {
        var normalized = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        if !normalized.contains("://") {
            normalized = "https://\(normalized)"
        }
        guard let url = URL(string: normalized) else {
            errorMessage = "Invalid URL"
            return
        }

        errorMessage = nil
        isLoading = true

        Task {
            do {
                let metadata = try await pageFetcher.fetch(url: url)
                let source = Source(url: url, title: metadata.title, rssURL: metadata.rssURL)
                store.add(source)
                dismiss()
            } catch {
                errorMessage = "Could not fetch page: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
}
