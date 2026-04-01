import Foundation
import Quick
import Nimble
@testable import BoltClip

class DraggedDataSpec: QuickSpec {
    override class func spec() {

        describe("NSCoding") {

            it("Archive data") {
                let draggedData = CPYDraggedData(type: .folder, folderIdentifier: NSUUID().uuidString, snippetIdentifier: nil, index: 10)
                let data = try NSKeyedArchiver.archivedData(withRootObject: draggedData, requiringSecureCoding: false)

                let unarchiver = try NSKeyedUnarchiver(forReadingFrom: data)
                unarchiver.requiresSecureCoding = false
                defer { unarchiver.finishDecoding() }
                let unarchiveData = unarchiver.decodeObject(forKey: NSKeyedArchiveRootObjectKey) as? CPYDraggedData
                expect(unarchiveData).toNot(beNil())
                expect(unarchiveData?.type) == draggedData.type
                expect(unarchiveData?.folderIdentifier) == draggedData.folderIdentifier
                expect(unarchiveData?.snippetIdentifier).to(beNil())
                expect(unarchiveData?.index) == draggedData.index
            }

        }

    }
}
