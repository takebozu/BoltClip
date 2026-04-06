//
//  CPYSnippetsEditorWindowController+DataSource.swift
//
//  BoltClip
//  GitHub: https://github.com/takebozu/BoltClip
//
//  Copyright © 2015-2018 Clipy Project.
//  Copyright © 2026 Satoshi Takezawa
//

import Cocoa

// MARK: - NSOutlineView DataSource
extension CPYSnippetsEditorWindowController: NSOutlineViewDataSource {
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if item == nil {
            return Int(folders.count)
        } else if let folder = item as? CPYFolder {
            return Int(folder.snippets.count)
        }
        return 0
    }

    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        if let folder = item as? CPYFolder {
            return !folder.snippets.isEmpty
        }
        return false
    }

    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if item == nil {
            return folders[index]
        } else if let folder = item as? CPYFolder {
            return folder.snippets[index]
        }
        return ""
    }

    func outlineView(_ outlineView: NSOutlineView, objectValueFor tableColumn: NSTableColumn?, byItem item: Any?) -> Any? {
        if let folder = item as? CPYFolder {
            return folder.title
        } else if let snippet = item as? CPYSnippet {
            return snippet.title
        }
        return ""
    }

    // MARK: - Drag and Drop
    func outlineView(_ outlineView: NSOutlineView, pasteboardWriterForItem item: Any) -> NSPasteboardWriting? {
        let pasteboardItem = NSPasteboardItem()
        if let folder = item as? CPYFolder, let index = folders.firstIndex(of: folder) {
            let draggedData = CPYDraggedData(type: .folder, folderIdentifier: folder.identifier, snippetIdentifier: nil, index: index)
            guard let data = try? NSKeyedArchiver.archivedData(withRootObject: draggedData, requiringSecureCoding: false) else { return nil }
            pasteboardItem.setData(data, forType: NSPasteboard.PasteboardType(rawValue: Constants.Common.draggedDataType))
        } else if let snippet = item as? CPYSnippet, let folder = outlineView.parent(forItem: snippet) as? CPYFolder {
            guard let index = folder.snippets.firstIndex(of: snippet) else { return nil }
            let draggedData = CPYDraggedData(type: .snippet, folderIdentifier: folder.identifier, snippetIdentifier: snippet.identifier, index: Int(index))
            guard let data = try? NSKeyedArchiver.archivedData(withRootObject: draggedData, requiringSecureCoding: false) else { return nil }
            pasteboardItem.setData(data, forType: NSPasteboard.PasteboardType(rawValue: Constants.Common.draggedDataType))
        } else {
            return nil
        }
        return pasteboardItem
    }

    func outlineView(_ outlineView: NSOutlineView, validateDrop info: NSDraggingInfo, proposedItem item: Any?, proposedChildIndex index: Int) -> NSDragOperation {
        let pasteboard = info.draggingPasteboard
        guard let data = pasteboard.data(forType: NSPasteboard.PasteboardType(rawValue: Constants.Common.draggedDataType)) else { return NSDragOperation() }
        guard let unarchiver = try? NSKeyedUnarchiver(forReadingFrom: data) else { return NSDragOperation() }
        unarchiver.requiresSecureCoding = false
        defer { unarchiver.finishDecoding() }
        guard let draggedData = unarchiver.decodeObject(forKey: NSKeyedArchiveRootObjectKey) as? CPYDraggedData else { return NSDragOperation() }

        switch draggedData.type {
        case .folder where item == nil:
            return .move
        case .snippet where item is CPYFolder:
            return .move
        default:
            return NSDragOperation()
        }
    }

    func outlineView(_ outlineView: NSOutlineView, acceptDrop info: NSDraggingInfo, item: Any?, childIndex index: Int) -> Bool {
        let pasteboard = info.draggingPasteboard
        guard let data = pasteboard.data(forType: NSPasteboard.PasteboardType(rawValue: Constants.Common.draggedDataType)) else { return false }
        guard let unarchiver = try? NSKeyedUnarchiver(forReadingFrom: data) else { return false }
        unarchiver.requiresSecureCoding = false
        defer { unarchiver.finishDecoding() }
        guard let draggedData = unarchiver.decodeObject(forKey: NSKeyedArchiveRootObjectKey) as? CPYDraggedData else { return false }

        switch draggedData.type {
        case .folder where index != draggedData.index:
            guard index >= 0 else { return false }
            guard let folder = folders.first(where: { $0.identifier == draggedData.folderIdentifier }) else { return false }
            folders.insert(folder, at: index)
            let removedIndex = (index < draggedData.index) ? draggedData.index + 1 : draggedData.index
            folders.remove(at: removedIndex)
            outlineView.reloadData()
            outlineView.selectRowIndexes(IndexSet(integer: outlineView.row(forItem: folder)), byExtendingSelection: false)
            CPYFolder.rearrangesIndex(folders)
            changeItemFocus()
            return true
        case .snippet:
            guard let fromFolder = folders.first(where: { $0.identifier == draggedData.folderIdentifier }) else { return false }
            guard let toFolder = item as? CPYFolder else { return false }
            guard let snippet = fromFolder.snippets.first(where: { $0.identifier == draggedData.snippetIdentifier }) else { return false }

            if fromFolder.identifier == toFolder.identifier {
                guard index >= 0 else { return false }
                if index == draggedData.index { return false }
                // Move within same folder — remove first, then insert at adjusted position
                // (@Model inverse relationships auto-remove from the old position on insert,
                //  so the old insert-then-remove pattern caused index-out-of-range crashes)
                fromFolder.snippets.remove(at: draggedData.index)
                let adjustedIndex = min((index > draggedData.index) ? index - 1 : index,
                                        fromFolder.snippets.count)
                fromFolder.snippets.insert(snippet, at: adjustedIndex)
                outlineView.reloadData()
                outlineView.selectRowIndexes(NSIndexSet(index: outlineView.row(forItem: snippet)) as IndexSet, byExtendingSelection: false)
                fromFolder.rearrangesSnippetIndex()
                changeItemFocus()
                return true
            } else {
                // Move to other folder — remove from source first, then insert into target
                let insertIndex = max(0, index)
                fromFolder.snippets.removeAll(where: { $0.identifier == snippet.identifier })
                toFolder.snippets.insert(snippet, at: min(insertIndex, toFolder.snippets.count))
                outlineView.reloadData()
                outlineView.expandItem(toFolder)
                outlineView.selectRowIndexes(NSIndexSet(index: outlineView.row(forItem: snippet)) as IndexSet, byExtendingSelection: false)
                fromFolder.removeSnippet(snippet)
                toFolder.insertSnippet(snippet, index: insertIndex)
                changeItemFocus()
                return true
            }
        default: return false
        }
    }
}
