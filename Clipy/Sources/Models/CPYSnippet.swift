//
//  CPYSnippet.swift
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
final class CPYSnippet {

    // MARK: - Properties
    var index: Int = 0
    var enable: Bool = true
    var title: String = ""
    var content: String = ""
    @Attribute(.unique) var identifier: String = UUID().uuidString
    var folder: CPYFolder?

    init() {}

    init(index: Int = 0, enable: Bool = true, title: String = "",
         content: String = "", identifier: String = UUID().uuidString) {
        self.index = index
        self.enable = enable
        self.title = title
        self.content = content
        self.identifier = identifier
    }

}

// MARK: - Equatable
extension CPYSnippet: Equatable {
    static func == (lhs: CPYSnippet, rhs: CPYSnippet) -> Bool {
        return lhs.identifier == rhs.identifier
    }
}

// MARK: - Add Snippet
extension CPYSnippet {
    @MainActor
    func merge() {
        let context = AppEnvironment.current.modelContainer.mainContext
        let snippetId = self.identifier
        var descriptor = FetchDescriptor<CPYSnippet>(predicate: #Predicate { $0.identifier == snippetId })
        descriptor.fetchLimit = 1

        if let existing = try? context.fetch(descriptor).first {
            existing.index = self.index
            existing.enable = self.enable
            existing.title = self.title
            existing.content = self.content
        } else {
            let newSnippet = CPYSnippet(index: index, enable: enable, title: title,
                                        content: content, identifier: identifier)
            context.insert(newSnippet)
        }
        try? context.save()
    }
}

// MARK: - Remove Snippet
extension CPYSnippet {
    @MainActor
    func remove() {
        let context = AppEnvironment.current.modelContainer.mainContext
        let snippetId = self.identifier
        var descriptor = FetchDescriptor<CPYSnippet>(predicate: #Predicate { $0.identifier == snippetId })
        descriptor.fetchLimit = 1

        guard let snippet = try? context.fetch(descriptor).first else { return }
        context.delete(snippet)
        try? context.save()
    }
}
