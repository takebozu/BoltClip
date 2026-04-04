import Foundation
import Quick
import Nimble
import SwiftData
@testable import BoltClip

class SnippetSpec: QuickSpec {
    override class func spec() {

        beforeEach {
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            let container = try! ModelContainer(for: CPYClip.self, CPYFolder.self, CPYSnippet.self,
                                                 configurations: config)
            AppEnvironment.replaceCurrent(environment: Environment(modelContainer: container))
        }

        describe("Sync database") {

            it("Merge snippet") {
                let context = AppEnvironment.current.modelContainer.mainContext

                let snippet = CPYSnippet()
                context.insert(snippet)
                try! context.save()

                let snippet2 = CPYSnippet()
                snippet2.identifier = snippet.identifier
                snippet2.index = 100
                snippet2.title = "title"
                snippet2.content = "content"
                snippet2.merge()
                expect(snippet2.modelContext).to(beNil())

                expect(snippet.index) == snippet2.index
                expect(snippet.title) == snippet2.title
                expect(snippet.content) == snippet2.content
            }

            it("Remove snippet") {
                let context = AppEnvironment.current.modelContainer.mainContext
                let descriptor = FetchDescriptor<CPYSnippet>()
                expect(try! context.fetchCount(descriptor)) == 0

                let snippet = CPYSnippet()
                context.insert(snippet)
                try! context.save()

                expect(try! context.fetchCount(descriptor)) == 1

                let snippet2 = CPYSnippet()
                snippet2.identifier = snippet.identifier
                snippet2.remove()

                expect(try! context.fetchCount(descriptor)) == 0
            }

            afterEach {
                let context = AppEnvironment.current.modelContainer.mainContext
                let snippets = (try? context.fetch(FetchDescriptor<CPYSnippet>())) ?? []
                snippets.forEach { context.delete($0) }
                try! context.delete(model: CPYFolder.self)
                try! context.delete(model: CPYClip.self)
                try! context.save()
            }

        }

    }
}
