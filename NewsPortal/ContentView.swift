import AppKit
import SwiftUI

struct ContentView: View {
    @StateObject private var store = SourceStore()
    @StateObject private var webNavigator = WebViewNavigator()
    @State private var selectedSourceID: UUID?

    // Quiz state
    @State private var isGeneratingQuiz = false
    @State private var quizError: String?
    @State private var activeQuizSession: QuizSession?
    @State private var showingQuiz = false

    private let rssService: RSSFetching = RSSService()
    private let pageFetcher: PageFetching = PageFetcher()
    private let quizService: QuizGenerating = QuizService()

    struct QuizSession {
        let sourceID: UUID
        let quizPageID: UUID
        let questions: [QuizQuestion]
    }

    var body: some View {
        NavigationSplitView {
            SourceListView(
                store: store,
                selectedSourceID: $selectedSourceID,
                onQuizPageSelected: { sourceID, quizPage in
                    let picked = quizPage.randomQuestions(count: 4)
                    activeQuizSession = QuizSession(
                        sourceID: sourceID,
                        quizPageID: quizPage.id,
                        questions: picked
                    )
                    showingQuiz = true
                }
            )
            .frame(minWidth: 220)
        } detail: {
            if let id = selectedSourceID,
               let source = store.sources.first(where: { $0.id == id }) {
                ZStack {
                    WebView(url: source.url, navigator: webNavigator)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                    if isGeneratingQuiz {
                        quizLoadingOverlay
                    }
                }
                .toolbar {
                    ToolbarItemGroup(placement: .primaryAction) {
                        Button(action: { generateQuiz() }) {
                            Label("Quiz me", systemImage: "brain.head.profile")
                        }
                        .disabled(isGeneratingQuiz)
                        .help("Generate a quiz from the current page")

                        Spacer().frame(width: 8)

                        Button(action: { webNavigator.goBack() }) {
                            Label("Back", systemImage: "chevron.left")
                        }
                        .disabled(!webNavigator.canGoBack)
                        .keyboardShortcut("[", modifiers: .command)

                        Button(action: { webNavigator.goForward() }) {
                            Label("Forward", systemImage: "chevron.right")
                        }
                        .disabled(!webNavigator.canGoForward)
                        .keyboardShortcut("]", modifiers: .command)
                    }
                }
            } else {
                Text("Select a source to browse")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onChange(of: selectedSourceID) { _, newValue in
            if let id = newValue {
                store.markAsRead(id: id)
                Task { await fetchFaviconIfNeeded(id: id) }
            }
        }
        .task {
            await refreshAllFeeds()
            await refreshMissingFavicons()
        }
        .sheet(isPresented: $showingQuiz) {
            if let session = activeQuizSession {
                QuizView(
                    questions: session.questions,
                    sourceID: session.sourceID,
                    quizPageID: session.quizPageID,
                    store: store
                )
            }
        }
        .alert("Quiz Error", isPresented: .init(
            get: { quizError != nil },
            set: { if !$0 { quizError = nil } }
        )) {
            Button("OK") { quizError = nil }
        } message: {
            Text(quizError ?? "")
        }
    }

    // MARK: - Quiz loading overlay

    private var quizLoadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                    .progressViewStyle(.circular)
                Text("Generating quiz...")
                    .font(.headline)
                    .foregroundStyle(.white)
                Text("Analyzing page content with AI")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
            }
            .padding(32)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
    }

    // MARK: - Quiz generation

    private func generateQuiz() {
        guard let sourceID = selectedSourceID else { return }

        isGeneratingQuiz = true
        Task {
            do {
                guard let content = await webNavigator.extractPageContent() else {
                    throw QuizError.noContent
                }

                let pageURL = webNavigator.currentURL
                    ?? store.sources.first(where: { $0.id == sourceID })?.url
                    ?? URL(string: "about:blank")!

                let quizPage = try await quizService.generateQuiz(
                    pageContent: content.text,
                    pageTitle: content.title,
                    pageURL: pageURL
                )

                store.addQuizPage(sourceID: sourceID, quizPage: quizPage)

                // Immediately show quiz with 4 random questions
                let picked = quizPage.randomQuestions(count: 4)
                activeQuizSession = QuizSession(
                    sourceID: sourceID,
                    quizPageID: quizPage.id,
                    questions: picked
                )
                isGeneratingQuiz = false
                showingQuiz = true
            } catch {
                isGeneratingQuiz = false
                quizError = error.localizedDescription
            }
        }
    }

    // MARK: - RSS & Favicons

    private func refreshAllFeeds() async {
        for source in store.sources where source.rssURL != nil {
            guard let rssURL = source.rssURL else { continue }
            do {
                let result = try await rssService.fetchFeed(url: rssURL)
                store.updateKnownArticles(id: source.id, articleIDs: result.articleIDs)
            } catch {
                print("RSS fetch failed for \(source.title): \(error)")
            }
        }
    }

    private func refreshMissingFavicons() async {
        for source in store.sources where source.needsFaviconRefresh {
            await fetchFaviconIfNeeded(id: source.id)
        }
    }

    private func fetchFaviconIfNeeded(id: UUID) async {
        guard let source = store.sources.first(where: { $0.id == id }),
              source.needsFaviconRefresh else { return }
        do {
            let metadata = try await pageFetcher.fetch(url: source.url)
            if let data = await pageFetcher.fetchFavicon(for: source.url, faviconURL: metadata.faviconURL) {
                store.updateFavicon(id: id, data: data)
            }
        } catch {
            print("Favicon fetch failed for \(source.title): \(error)")
        }
    }
}
