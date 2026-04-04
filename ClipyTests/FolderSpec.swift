import Quick
import Foundation
import Nimble
import SwiftData
@testable import BoltClip

// swiftlint:disable function_body_length
class FolderSpec: QuickSpec {
    override class func spec() {

        beforeEach {
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            let container = try! ModelContainer(for: CPYClip.self, CPYFolder.self, CPYSnippet.self,
                                                 configurations: config)
            AppEnvironment.replaceCurrent(environment: Environment(modelContainer: container))
        }

        describe("Create new") {

            it("deep copy object") {
                let context = AppEnvironment.current.modelContainer.mainContext

                // Save Value
                let savedFolder = CPYFolder()
                savedFolder.index = 100
                savedFolder.title = "saved folder"

                let savedSnippet = CPYSnippet()
                savedSnippet.index = 10
                savedSnippet.title = "saved snippet"
                savedSnippet.content = "content"
                savedFolder.snippets.append(savedSnippet)

                context.insert(savedFolder)
                try! context.save()

                // Saved in SwiftData
                expect(savedFolder.modelContext).toNot(beNil())
                expect(savedSnippet.modelContext).toNot(beNil())

                // Deep copy
                let folder = savedFolder.deepCopy()
                expect(folder.modelContext).to(beNil())
                expect(folder.index) == savedFolder.index
                expect(folder.enable) == savedFolder.enable
                expect(folder.title) == savedFolder.title
                expect(folder.identifier) == savedFolder.identifier
                expect(folder.snippets.count) == 1

                let snippet = folder.snippets.first!
                expect(snippet.modelContext).to(beNil())
                expect(snippet.index) == savedSnippet.index
                expect(snippet.enable) == savedSnippet.enable
                expect(snippet.title) == savedSnippet.title
                expect(snippet.content) == savedSnippet.content
                expect(snippet.identifier) == savedSnippet.identifier
            }

            it("Create folder") {
                let context = AppEnvironment.current.modelContainer.mainContext

                let folder = CPYFolder.create()
                expect(folder.title) == "untitled folder"
                expect(folder.index) == 0

                context.insert(folder)
                try! context.save()

                let folder2 = CPYFolder.create()
                expect(folder2.index) == 1
            }

            it("Create snippet") {
                let folder = CPYFolder()
                let snippet = folder.createSnippet()

                expect(snippet.title) == "untitled snippet"
                expect(snippet.index) == 0

                folder.snippets.append(snippet)

                let snippet2 = folder.createSnippet()
                expect(snippet2.index) == 1
            }

            afterEach {
                let context = AppEnvironment.current.modelContainer.mainContext
                try! context.delete(model: CPYFolder.self)
                try! context.delete(model: CPYClip.self)
                try! context.save()
            }

        }

        describe("Sync database") {

            it("Merge snippet") {
                let context = AppEnvironment.current.modelContainer.mainContext

                let folder = CPYFolder()
                context.insert(folder)
                try! context.save()
                let copyFolder = folder.deepCopy()

                let snippet = CPYSnippet()
                let snippet2 = CPYSnippet()
                copyFolder.mergeSnippet(snippet)
                copyFolder.mergeSnippet(snippet2)

                expect(snippet.modelContext).to(beNil())
                expect(snippet2.modelContext).to(beNil())
                expect(folder.snippets.count) == 2

                let identifiers = Set(folder.snippets.map { $0.identifier })
                expect(identifiers).to(contain(snippet.identifier))
                expect(identifiers).to(contain(snippet2.identifier))
            }

            it("Insert snippet") {
                let context = AppEnvironment.current.modelContainer.mainContext

                let folder = CPYFolder()
                context.insert(folder)
                try! context.save()
                let copyFolder = folder.deepCopy()

                let snippet = CPYSnippet()
                // Don't insert non saved snippet
                copyFolder.insertSnippet(snippet, index: 0)
                expect(folder.snippets.count) == 0

                context.insert(snippet)
                try! context.save()

                // Can insert saved snippet
                copyFolder.insertSnippet(snippet, index: 0)
                expect(folder.snippets.count) == 1
            }

            it("Remove snippet") {
                let context = AppEnvironment.current.modelContainer.mainContext

                let folder = CPYFolder()
                let snippet = CPYSnippet()
                folder.snippets.append(snippet)
                context.insert(folder)
                try! context.save()

                expect(folder.snippets.count) == 1

                let copyFolder = folder.deepCopy()
                copyFolder.removeSnippet(snippet)

                expect(folder.snippets.count) == 0
            }

            it("Merge folder") {
                let context = AppEnvironment.current.modelContainer.mainContext
                let descriptor = FetchDescriptor<CPYFolder>()
                expect(try! context.fetchCount(descriptor)) == 0

                let folder = CPYFolder()
                folder.index = 100
                folder.title = "title"
                folder.enable = false
                folder.merge()
                expect(folder.modelContext).to(beNil())
                expect(try! context.fetchCount(descriptor)) == 1

                let folderId = folder.identifier
                var findDescriptor = FetchDescriptor<CPYFolder>(predicate: #Predicate { $0.identifier == folderId })
                findDescriptor.fetchLimit = 1
                let savedFolder = try? context.fetch(findDescriptor).first
                expect(savedFolder).toNot(beNil())
                expect(savedFolder?.index) == folder.index
                expect(savedFolder?.title) == folder.title
                expect(savedFolder?.enable) == folder.enable

                folder.index = 1
                folder.title = "change title"
                folder.enable = true
                folder.merge()
                expect(try! context.fetchCount(descriptor)) == 1

                expect(savedFolder?.index) == folder.index
                expect(savedFolder?.title) == folder.title
                expect(savedFolder?.enable) == folder.enable
            }

            it("Remove folder") {
                let context = AppEnvironment.current.modelContainer.mainContext

                let folder = CPYFolder()
                let snippet = CPYSnippet()
                folder.snippets.append(snippet)
                context.insert(folder)
                try! context.save()

                let folderDescriptor = FetchDescriptor<CPYFolder>()
                let snippetDescriptor = FetchDescriptor<CPYSnippet>()
                expect(try! context.fetchCount(folderDescriptor)) == 1
                expect(try! context.fetchCount(snippetDescriptor)) == 1

                let copyFolder = folder.deepCopy()
                expect(copyFolder.modelContext).to(beNil())
                copyFolder.remove()

                expect(try! context.fetchCount(folderDescriptor)) == 0
                expect(try! context.fetchCount(snippetDescriptor)) == 0
            }

            afterEach {
                let context = AppEnvironment.current.modelContainer.mainContext
                try! context.delete(model: CPYFolder.self)
                try! context.delete(model: CPYClip.self)
                try! context.save()
            }

        }

        describe("Move snippet within same folder") {

            it("moves snippet forward (lower index to higher)") {
                let folder = CPYFolder(index: 0, enable: true, title: "F", identifier: "f1")
                let snp1 = CPYSnippet(index: 0, enable: true, title: "S1", content: "", identifier: "s1")
                let snp2 = CPYSnippet(index: 1, enable: true, title: "S2", content: "", identifier: "s2")
                let snp3 = CPYSnippet(index: 2, enable: true, title: "S3", content: "", identifier: "s3")
                folder.snippets = [snp1, snp2, snp3]

                // Move S1 (index 0) to position 2 (between S2 and S3)
                let draggedIndex = 0
                let dropIndex = 2
                folder.snippets.remove(at: draggedIndex)
                let adjusted = min((dropIndex > draggedIndex) ? dropIndex - 1 : dropIndex,
                                    folder.snippets.count)
                folder.snippets.insert(snp1, at: adjusted)

                expect(folder.snippets.map { $0.title }) == ["S2", "S1", "S3"]
            }

            it("moves snippet backward (higher index to lower)") {
                let folder = CPYFolder(index: 0, enable: true, title: "F", identifier: "f1")
                let snp1 = CPYSnippet(index: 0, enable: true, title: "S1", content: "", identifier: "s1")
                let snp2 = CPYSnippet(index: 1, enable: true, title: "S2", content: "", identifier: "s2")
                let snp3 = CPYSnippet(index: 2, enable: true, title: "S3", content: "", identifier: "s3")
                folder.snippets = [snp1, snp2, snp3]

                // Move S3 (index 2) to position 0 (beginning)
                let draggedIndex = 2
                let dropIndex = 0
                folder.snippets.remove(at: draggedIndex)
                let adjusted = min((dropIndex > draggedIndex) ? dropIndex - 1 : dropIndex,
                                    folder.snippets.count)
                folder.snippets.insert(snp3, at: adjusted)

                expect(folder.snippets.map { $0.title }) == ["S3", "S1", "S2"]
            }

            it("moves snippet to the end") {
                let folder = CPYFolder(index: 0, enable: true, title: "F", identifier: "f1")
                let snp1 = CPYSnippet(index: 0, enable: true, title: "S1", content: "", identifier: "s1")
                let snp2 = CPYSnippet(index: 1, enable: true, title: "S2", content: "", identifier: "s2")
                let snp3 = CPYSnippet(index: 2, enable: true, title: "S3", content: "", identifier: "s3")
                folder.snippets = [snp1, snp2, snp3]

                // Move S1 (index 0) to position 3 (end)
                let draggedIndex = 0
                let dropIndex = 3
                folder.snippets.remove(at: draggedIndex)
                let adjusted = min((dropIndex > draggedIndex) ? dropIndex - 1 : dropIndex,
                                    folder.snippets.count)
                folder.snippets.insert(snp1, at: adjusted)

                expect(folder.snippets.map { $0.title }) == ["S2", "S3", "S1"]
            }

            it("moves middle snippet to adjacent position") {
                let folder = CPYFolder(index: 0, enable: true, title: "F", identifier: "f1")
                let snp1 = CPYSnippet(index: 0, enable: true, title: "S1", content: "", identifier: "s1")
                let snp2 = CPYSnippet(index: 1, enable: true, title: "S2", content: "", identifier: "s2")
                let snp3 = CPYSnippet(index: 2, enable: true, title: "S3", content: "", identifier: "s3")
                folder.snippets = [snp1, snp2, snp3]

                // Move S2 (index 1) to position 0
                let draggedIndex = 1
                let dropIndex = 0
                folder.snippets.remove(at: draggedIndex)
                let adjusted = min((dropIndex > draggedIndex) ? dropIndex - 1 : dropIndex,
                                    folder.snippets.count)
                folder.snippets.insert(snp2, at: adjusted)

                expect(folder.snippets.map { $0.title }) == ["S2", "S1", "S3"]
            }

            it("preserves inverse relationship after same-folder move") {
                let folder = CPYFolder(index: 0, enable: true, title: "F", identifier: "f1")
                let snp1 = CPYSnippet(index: 0, enable: true, title: "S1", content: "", identifier: "s1")
                let snp2 = CPYSnippet(index: 1, enable: true, title: "S2", content: "", identifier: "s2")
                folder.snippets = [snp1, snp2]

                folder.snippets.remove(at: 1)
                folder.snippets.insert(snp2, at: 0)

                expect(snp1.folder?.identifier) == folder.identifier
                expect(snp2.folder?.identifier) == folder.identifier
                expect(folder.snippets.count) == 2
            }
        }

        describe("Move snippet to different folder") {

            it("moves snippet between folders") {
                let folderA = CPYFolder(index: 0, enable: true, title: "A", identifier: "fa")
                let folderB = CPYFolder(index: 1, enable: true, title: "B", identifier: "fb")
                let snp1 = CPYSnippet(index: 0, enable: true, title: "S1", content: "", identifier: "s1")
                let snp2 = CPYSnippet(index: 1, enable: true, title: "S2", content: "", identifier: "s2")
                let snp3 = CPYSnippet(index: 0, enable: true, title: "S3", content: "", identifier: "s3")
                folderA.snippets = [snp1, snp2]
                folderB.snippets = [snp3]

                // Move S2 from A to B at position 0
                let snippet = snp2
                let insertIndex = 0
                folderA.snippets.removeAll(where: { $0.identifier == snippet.identifier })
                folderB.snippets.insert(snippet, at: min(insertIndex, folderB.snippets.count))

                expect(folderA.snippets.map { $0.title }) == ["S1"]
                expect(folderB.snippets.map { $0.title }) == ["S2", "S3"]
                expect(snippet.folder?.identifier) == folderB.identifier
            }

            it("moves snippet to empty folder") {
                let folderA = CPYFolder(index: 0, enable: true, title: "A", identifier: "fa")
                let folderB = CPYFolder(index: 1, enable: true, title: "B", identifier: "fb")
                let snp1 = CPYSnippet(index: 0, enable: true, title: "S1", content: "", identifier: "s1")
                folderA.snippets = [snp1]
                folderB.snippets = []

                let insertIndex = max(0, -1) // drop "on" folder → childIndex -1
                folderA.snippets.removeAll(where: { $0.identifier == snp1.identifier })
                folderB.snippets.insert(snp1, at: min(insertIndex, folderB.snippets.count))

                expect(folderA.snippets).to(beEmpty())
                expect(folderB.snippets.map { $0.title }) == ["S1"]
                expect(snp1.folder?.identifier) == folderB.identifier
            }

            it("moves snippet and moves it back") {
                let folderA = CPYFolder(index: 0, enable: true, title: "A", identifier: "fa")
                let folderB = CPYFolder(index: 1, enable: true, title: "B", identifier: "fb")
                let snp1 = CPYSnippet(index: 0, enable: true, title: "S1", content: "", identifier: "s1")
                let snp2 = CPYSnippet(index: 1, enable: true, title: "S2", content: "", identifier: "s2")
                folderA.snippets = [snp1, snp2]
                folderB.snippets = []

                // Move S2 from A to B
                folderA.snippets.removeAll(where: { $0.identifier == snp2.identifier })
                folderB.snippets.insert(snp2, at: min(0, folderB.snippets.count))

                expect(folderA.snippets.count) == 1
                expect(folderB.snippets.count) == 1

                // Move S2 back from B to A at position 1
                folderB.snippets.removeAll(where: { $0.identifier == snp2.identifier })
                folderA.snippets.insert(snp2, at: min(1, folderA.snippets.count))

                expect(folderA.snippets.map { $0.title }) == ["S1", "S2"]
                expect(folderB.snippets).to(beEmpty())
                expect(snp2.folder?.identifier) == folderA.identifier
            }

            it("moves last snippet from a folder") {
                let folderA = CPYFolder(index: 0, enable: true, title: "A", identifier: "fa")
                let folderB = CPYFolder(index: 1, enable: true, title: "B", identifier: "fb")
                let snp1 = CPYSnippet(index: 0, enable: true, title: "S1", content: "", identifier: "s1")
                folderA.snippets = [snp1]
                folderB.snippets = []

                folderA.snippets.removeAll(where: { $0.identifier == snp1.identifier })
                folderB.snippets.insert(snp1, at: min(0, folderB.snippets.count))

                expect(folderA.snippets).to(beEmpty())
                expect(folderB.snippets.count) == 1
                expect(snp1.folder?.identifier) == folderB.identifier
            }

            it("moves snippet at last index without crash") {
                let folderA = CPYFolder(index: 0, enable: true, title: "A", identifier: "fa")
                let folderB = CPYFolder(index: 1, enable: true, title: "B", identifier: "fb")
                let snp1 = CPYSnippet(index: 0, enable: true, title: "S1", content: "", identifier: "s1")
                let snp2 = CPYSnippet(index: 1, enable: true, title: "S2", content: "", identifier: "s2")
                let snp3 = CPYSnippet(index: 2, enable: true, title: "S3", content: "", identifier: "s3")
                folderA.snippets = [snp1, snp2, snp3]
                folderB.snippets = []

                // Move S3 (last, index 2) — this was the original crash case
                folderA.snippets.removeAll(where: { $0.identifier == snp3.identifier })
                folderB.snippets.insert(snp3, at: min(0, folderB.snippets.count))

                expect(folderA.snippets.map { $0.title }) == ["S1", "S2"]
                expect(folderB.snippets.map { $0.title }) == ["S3"]
            }

            it("moves multiple snippets between folders sequentially") {
                let folderA = CPYFolder(index: 0, enable: true, title: "A", identifier: "fa")
                let folderB = CPYFolder(index: 1, enable: true, title: "B", identifier: "fb")
                let snp1 = CPYSnippet(index: 0, enable: true, title: "S1", content: "", identifier: "s1")
                let snp2 = CPYSnippet(index: 1, enable: true, title: "S2", content: "", identifier: "s2")
                let snp3 = CPYSnippet(index: 2, enable: true, title: "S3", content: "", identifier: "s3")
                folderA.snippets = [snp1, snp2, snp3]
                folderB.snippets = []

                // Move S1 to B
                folderA.snippets.removeAll(where: { $0.identifier == snp1.identifier })
                folderB.snippets.insert(snp1, at: min(0, folderB.snippets.count))

                // Move S3 to B at end
                let insertIdx = folderB.snippets.count
                folderA.snippets.removeAll(where: { $0.identifier == snp3.identifier })
                folderB.snippets.insert(snp3, at: min(insertIdx, folderB.snippets.count))

                expect(folderA.snippets.map { $0.title }) == ["S2"]
                expect(folderB.snippets.map { $0.title }) == ["S1", "S3"]
            }
        }

        describe("Rearrange Index") {

            it("Rearrange folder index") {
                let context = AppEnvironment.current.modelContainer.mainContext

                let folder = CPYFolder()
                folder.index = 100
                let folder2 = CPYFolder()
                folder2.index = 10

                context.insert(folder)
                context.insert(folder2)
                try! context.save()

                let copyFolder = folder.deepCopy()
                let copyFolder2 = folder2.deepCopy()

                CPYFolder.rearrangesIndex([copyFolder, copyFolder2])

                expect(copyFolder.index) == 0
                expect(copyFolder2.index) == 1
                expect(folder.index) == 0
                expect(folder2.index) == 1
            }

            it("Rearrange snippet index") {
                let context = AppEnvironment.current.modelContainer.mainContext

                let folder = CPYFolder()
                let snippet = CPYSnippet()
                snippet.index = 10
                let snippet2 = CPYSnippet()
                snippet2.index = 100
                folder.snippets.append(snippet)
                folder.snippets.append(snippet2)
                context.insert(folder)
                try! context.save()

                let copyFolder = folder.deepCopy()
                copyFolder.rearrangesSnippetIndex()

                let copySnippet = copyFolder.snippets.first!
                let copySnippet2 = copyFolder.snippets[1]
                expect(copySnippet.index) == 0
                expect(copySnippet2.index) == 1
                expect(snippet.index) == 0
                expect(snippet2.index) == 1
            }

            afterEach {
                let context = AppEnvironment.current.modelContainer.mainContext
                try! context.delete(model: CPYFolder.self)
                try! context.delete(model: CPYClip.self)
                try! context.save()
            }

        }

    }
}
