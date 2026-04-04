//
//  CPYFolder.swift
//
//  BoltClip
//  GitHub: https://github.com/takebozu/BoltClip
//
//  Created by Econa77 on 2015/06/21.
//
//  Copyright © 2015-2018 Clipy Project.
//

import Cocoa
import SwiftData

@Model
final class CPYFolder {

    // MARK: - Properties
    var index: Int = 0
    var enable: Bool = true
    var title: String = ""
    @Attribute(.unique) var identifier: String = UUID().uuidString
    @Relationship(deleteRule: .cascade, inverse: \CPYSnippet.folder)
    var snippets: [CPYSnippet] = []

    init() {}

    init(index: Int = 0, enable: Bool = true, title: String = "", identifier: String = UUID().uuidString) {
        self.index = index
        self.enable = enable
        self.title = title
        self.identifier = identifier
    }

}

// MARK: - Equatable
extension CPYFolder: Equatable {
    static func == (lhs: CPYFolder, rhs: CPYFolder) -> Bool {
        return lhs.identifier == rhs.identifier
    }
}

// MARK: - Copy
extension CPYFolder {
    func deepCopy() -> CPYFolder {
        let folder = CPYFolder()
        folder.index = self.index
        folder.enable = self.enable
        folder.title = self.title
        folder.identifier = self.identifier

        let sortedSnippets = self.snippets.sorted { $0.index < $1.index }
        folder.snippets = sortedSnippets.map { original in
            let copy = CPYSnippet()
            copy.index = original.index
            copy.enable = original.enable
            copy.title = original.title
            copy.content = original.content
            copy.identifier = original.identifier
            return copy
        }
        return folder
    }
}

// MARK: - Add Snippet
extension CPYFolder {
    func createSnippet() -> CPYSnippet {
        let snippet = CPYSnippet()
        snippet.title = "untitled snippet"
        snippet.index = snippets.count
        return snippet
    }

    @MainActor
    func mergeSnippet(_ snippet: CPYSnippet) {
        let context = AppEnvironment.current.modelContainer.mainContext
        let folderId = self.identifier
        var descriptor = FetchDescriptor<CPYFolder>(predicate: #Predicate { $0.identifier == folderId })
        descriptor.fetchLimit = 1
        guard let folder = try? context.fetch(descriptor).first else { return }
        let copySnippet = CPYSnippet(index: snippet.index,
                                     enable: snippet.enable,
                                     title: snippet.title,
                                     content: snippet.content,
                                     identifier: snippet.identifier)
        folder.snippets.append(copySnippet)
        try? context.save()
    }

    @MainActor
    func insertSnippet(_ snippet: CPYSnippet, index: Int) {
        let context = AppEnvironment.current.modelContainer.mainContext
        let folderId = self.identifier
        var folderDescriptor = FetchDescriptor<CPYFolder>(predicate: #Predicate { $0.identifier == folderId })
        folderDescriptor.fetchLimit = 1
        guard let folder = try? context.fetch(folderDescriptor).first else { return }

        let snippetId = snippet.identifier
        var snippetDescriptor = FetchDescriptor<CPYSnippet>(predicate: #Predicate { $0.identifier == snippetId })
        snippetDescriptor.fetchLimit = 1
        guard let savedSnippet = try? context.fetch(snippetDescriptor).first else { return }

        folder.snippets.insert(savedSnippet, at: min(index, folder.snippets.count))
        try? context.save()
        folder.rearrangesSnippetIndex()
    }

    @MainActor
    func removeSnippet(_ snippet: CPYSnippet) {
        let context = AppEnvironment.current.modelContainer.mainContext
        let folderId = self.identifier
        var folderDescriptor = FetchDescriptor<CPYFolder>(predicate: #Predicate { $0.identifier == folderId })
        folderDescriptor.fetchLimit = 1
        guard let folder = try? context.fetch(folderDescriptor).first else { return }

        let snippetId = snippet.identifier
        guard let index = folder.snippets.firstIndex(where: { $0.identifier == snippetId }) else { return }
        folder.snippets.remove(at: index)
        try? context.save()
        folder.rearrangesSnippetIndex()
    }
}

// MARK: - Add Folder
extension CPYFolder {
    @MainActor
    static func create() -> CPYFolder {
        let context = AppEnvironment.current.modelContainer.mainContext
        let descriptor = FetchDescriptor<CPYFolder>(sortBy: [SortDescriptor(\.index, order: .forward)])
        let allFolders = (try? context.fetch(descriptor)) ?? []
        let lastIndex = allFolders.last?.index ?? -1

        let folder = CPYFolder()
        folder.title = "untitled folder"
        folder.index = lastIndex + 1
        return folder
    }

    @MainActor
    func merge() {
        let context = AppEnvironment.current.modelContainer.mainContext
        let folderId = self.identifier
        var descriptor = FetchDescriptor<CPYFolder>(predicate: #Predicate { $0.identifier == folderId })
        descriptor.fetchLimit = 1

        if let existing = try? context.fetch(descriptor).first {
            existing.index = self.index
            existing.enable = self.enable
            existing.title = self.title
        } else {
            let newFolder = CPYFolder(index: index, enable: enable, title: title, identifier: identifier)
            context.insert(newFolder)
        }
        try? context.save()
    }
}

// MARK: - Remove Folder
extension CPYFolder {
    @MainActor
    func remove() {
        let context = AppEnvironment.current.modelContainer.mainContext
        let folderId = self.identifier
        var descriptor = FetchDescriptor<CPYFolder>(predicate: #Predicate { $0.identifier == folderId })
        descriptor.fetchLimit = 1

        guard let folder = try? context.fetch(descriptor).first else { return }
        // cascade delete rule will handle snippets
        context.delete(folder)
        try? context.save()
    }
}

// MARK: - Migrate Index
extension CPYFolder {
    @MainActor
    static func rearrangesIndex(_ folders: [CPYFolder]) {
        let context = AppEnvironment.current.modelContainer.mainContext
        for (idx, folder) in folders.enumerated() {
            folder.index = idx
            let folderId = folder.identifier
            var descriptor = FetchDescriptor<CPYFolder>(predicate: #Predicate { $0.identifier == folderId })
            descriptor.fetchLimit = 1
            if let saved = try? context.fetch(descriptor).first {
                saved.index = idx
            }
        }
        try? context.save()
    }

    @MainActor
    func rearrangesSnippetIndex() {
        let context = AppEnvironment.current.modelContainer.mainContext
        for (idx, snippet) in snippets.enumerated() {
            snippet.index = idx
            let snippetId = snippet.identifier
            var descriptor = FetchDescriptor<CPYSnippet>(predicate: #Predicate { $0.identifier == snippetId })
            descriptor.fetchLimit = 1
            if let saved = try? context.fetch(descriptor).first {
                saved.index = idx
            }
        }
        try? context.save()
    }
}
