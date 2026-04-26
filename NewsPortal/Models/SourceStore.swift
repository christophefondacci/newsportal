import Foundation
import SwiftUI

@MainActor
class SourceStore: ObservableObject {
    @Published var sources: [Source] = []

    private let fileURL: URL

    var sortedSources: [Source] {
        sources.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }

    init(fileURL: URL? = nil) {
        if let fileURL {
            self.fileURL = fileURL
        } else {
            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            let dir = appSupport.appendingPathComponent("NewsPortal", isDirectory: true)
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            self.fileURL = dir.appendingPathComponent("sources.json")
        }
        load()
    }

    func add(_ source: Source) {
        sources.append(source)
        save()
    }

    func remove(at offsets: IndexSet) {
        let sorted = sortedSources
        let idsToRemove = offsets.map { sorted[$0].id }
        sources.removeAll { idsToRemove.contains($0.id) }
        save()
    }

    func remove(id: UUID) {
        sources.removeAll { $0.id == id }
        save()
    }

    func update(_ source: Source) {
        if let index = sources.firstIndex(where: { $0.id == source.id }) {
            sources[index] = source
            save()
        }
    }

    func markAsRead(id: UUID) {
        if let index = sources.firstIndex(where: { $0.id == id }) {
            sources[index].markAllAsRead()
            save()
        }
    }

    func updateKnownArticles(id: UUID, articleIDs: Set<String>) {
        if let index = sources.firstIndex(where: { $0.id == id }) {
            sources[index].updateKnownArticles(articleIDs)
            save()
        }
    }

    func updateFavicon(id: UUID, data: Data) {
        if let index = sources.firstIndex(where: { $0.id == id }) {
            sources[index].faviconData = data
            save()
        }
    }

    func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        do {
            let data = try Data(contentsOf: fileURL)
            sources = try JSONDecoder().decode([Source].self, from: data)
        } catch {
            print("Failed to load sources: \(error)")
        }
    }

    func save() {
        do {
            let data = try JSONEncoder().encode(sources)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("Failed to save sources: \(error)")
        }
    }
}
