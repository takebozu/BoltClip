//
//  CPYSnippetsEditorWindowController.swift
//
//  Clipstream
//  GitHub: https://github.com/clipy
//  HP: https://clipy-app.com
//
//  Created by Econa77 on 2016/05/18.
//
//  Copyright © 2015-2018 Clipstream Project.
//

import Cocoa
import RealmSwift
import KeyHolder
import UniformTypeIdentifiers
import Magnet
import AEXML

final class CPYSnippetsEditorWindowController: NSWindowController {

    // MARK: - Properties
    static let sharedController = CPYSnippetsEditorWindowController(windowNibName: "CPYSnippetsEditorWindowController")
    @IBOutlet private weak var splitView: CPYSplitView!
    @IBOutlet private weak var folderSettingView: NSView!
    @IBOutlet private weak var folderTitleTextField: NSTextField!
    @IBOutlet private weak var folderShortcutRecordView: RecordView! {
        didSet {
            folderShortcutRecordView.delegate = self
        }
    }
    @IBOutlet private var textView: CPYPlaceHolderTextView! {
        didSet {
            textView.font = NSFont.systemFont(ofSize: 14)
            textView.isAutomaticQuoteSubstitutionEnabled = false
            textView.enabledTextCheckingTypes = 0
            textView.isRichText = false
            textView.placeHolderText = NSLocalizedString("Please fill in the contents of the snippet", comment: "")
        }
    }
    @IBOutlet private weak var outlineView: NSOutlineView! {
        didSet {
            // Enable Drag and Drop
            outlineView.registerForDraggedTypes([NSPasteboard.PasteboardType(rawValue: Constants.Common.draggedDataType)])
        }
    }

    var folders = [CPYFolder]()
    private var selectedSnippet: CPYSnippet? {
        guard let snippet = outlineView.item(atRow: outlineView.selectedRow) as? CPYSnippet else { return nil }
        return snippet
    }
    private var selectedFolder: CPYFolder? {
        guard let item = outlineView.item(atRow: outlineView.selectedRow) else { return nil }
        if let folder = outlineView.parent(forItem: item) as? CPYFolder {
            return folder
        } else if let folder = item as? CPYFolder {
            return folder
        }
        return nil
    }

    // MARK: - Window Life Cycle
    override func windowDidLoad() {
        super.windowDidLoad()
        self.window?.collectionBehavior = NSWindow.CollectionBehavior.canJoinAllSpaces

        setupToolbar()
        applyModernAppearance()

        // HACK: Copy as an object that does not put under Realm management.
        // https://github.com/realm/realm-cocoa/issues/1734
        let realm = try! Realm()
        folders = realm.objects(CPYFolder.self)
                    .sorted(byKeyPath: #keyPath(CPYFolder.index), ascending: true)
                    .map { $0.deepCopy() }
        outlineView.reloadData()
        // Select first folder
        if let folder = folders.first {
            outlineView.selectRowIndexes(IndexSet(integer: outlineView.row(forItem: folder)), byExtendingSelection: false)
            changeItemFocus()
        }
    }

    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)
        window?.makeKeyAndOrderFront(self)
    }
}

// MARK: - Toolbar Setup
private extension CPYSnippetsEditorWindowController {
    func setupToolbar() {
        let toolbar = NSToolbar(identifier: "SnippetsEditorToolbar")
        toolbar.delegate = self
        toolbar.displayMode = .iconAndLabel
        window?.toolbar = toolbar
        window?.toolbarStyle = .unified
    }

    func applyModernAppearance() {
        outlineView?.backgroundColor = .controlBackgroundColor
        textView?.backgroundColor = .textBackgroundColor

        // Update folder icon in settings panel to use SF Symbol
        if let container = folderSettingView?.subviews.first {
            if let imageView = container.subviews.first(where: { $0 is NSImageView }) as? NSImageView {
                let config = NSImage.SymbolConfiguration(pointSize: 16, weight: .regular)
                    .applying(NSImage.SymbolConfiguration(paletteColors: [.systemBlue]))
                imageView.image = NSImage(systemSymbolName: "folder.fill", accessibilityDescription: "Folder")?
                    .withSymbolConfiguration(config)
            }
        }

        // Use system background for folder settings view
        if let designableView = folderSettingView as? CPYDesignableView {
            designableView.backgroundColor = .controlBackgroundColor
        }
    }
}

// MARK: - NSToolbar Delegate
extension CPYSnippetsEditorWindowController: NSToolbarDelegate {
    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        [.addSnippet, .addFolder, .deleteItem, .toggleEnable, .flexibleSpace, .importSnippets, .exportSnippets]
    }

    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        [.addSnippet, .addFolder, .deleteItem, .toggleEnable, .importSnippets, .exportSnippets, .flexibleSpace, .space]
    }

    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        let item = NSToolbarItem(itemIdentifier: itemIdentifier)
        let symbolConfig = NSImage.SymbolConfiguration(pointSize: 15, weight: .medium)

        switch itemIdentifier {
        case .addSnippet:
            item.label = NSLocalizedString("Add Snippet", comment: "")
            item.toolTip = NSLocalizedString("Add Snippet", comment: "")
            item.image = NSImage(systemSymbolName: "doc.badge.plus", accessibilityDescription: "Add Snippet")?
                .withSymbolConfiguration(symbolConfig)
            item.action = #selector(addSnippetButtonTapped(_:))
            item.target = self
        case .addFolder:
            item.label = NSLocalizedString("Add Folder", comment: "")
            item.toolTip = NSLocalizedString("Add Folder", comment: "")
            item.image = NSImage(systemSymbolName: "folder.badge.plus", accessibilityDescription: "Add Folder")?
                .withSymbolConfiguration(symbolConfig)
            item.action = #selector(addFolderButtonTapped(_:))
            item.target = self
        case .deleteItem:
            item.label = NSLocalizedString("Delete", comment: "")
            item.toolTip = NSLocalizedString("Delete", comment: "")
            item.image = NSImage(systemSymbolName: "trash", accessibilityDescription: "Delete")?
                .withSymbolConfiguration(symbolConfig)
            item.action = #selector(deleteButtonTapped(_:))
            item.target = self
        case .toggleEnable:
            item.label = NSLocalizedString("Enable/Disable", comment: "")
            item.toolTip = NSLocalizedString("Enable/Disable", comment: "")
            item.image = NSImage(systemSymbolName: "checkmark.circle", accessibilityDescription: "Enable/Disable")?
                .withSymbolConfiguration(symbolConfig)
            item.action = #selector(changeStatusButtonTapped(_:))
            item.target = self
        case .importSnippets:
            item.label = NSLocalizedString("Import", comment: "")
            item.toolTip = NSLocalizedString("Import", comment: "")
            item.image = NSImage(systemSymbolName: "square.and.arrow.down", accessibilityDescription: "Import")?
                .withSymbolConfiguration(symbolConfig)
            item.action = #selector(importSnippetButtonTapped(_:))
            item.target = self
        case .exportSnippets:
            item.label = NSLocalizedString("Export", comment: "")
            item.toolTip = NSLocalizedString("Export", comment: "")
            item.image = NSImage(systemSymbolName: "square.and.arrow.up", accessibilityDescription: "Export")?
                .withSymbolConfiguration(symbolConfig)
            item.action = #selector(exportSnippetButtonTapped(_:))
            item.target = self
        default:
            return nil
        }

        item.isBordered = true
        return item
    }
}

// MARK: - Toolbar Item Identifiers
private extension NSToolbarItem.Identifier {
    static let addSnippet = NSToolbarItem.Identifier("AddSnippet")
    static let addFolder = NSToolbarItem.Identifier("AddFolder")
    static let deleteItem = NSToolbarItem.Identifier("DeleteItem")
    static let toggleEnable = NSToolbarItem.Identifier("ToggleEnable")
    static let importSnippets = NSToolbarItem.Identifier("ImportSnippets")
    static let exportSnippets = NSToolbarItem.Identifier("ExportSnippets")
}

// MARK: - IBActions
extension CPYSnippetsEditorWindowController {
    @IBAction private func addSnippetButtonTapped(_ sender: AnyObject) {
        guard let folder = selectedFolder else {
            NSSound.beep()
            return
        }
        let snippet = folder.createSnippet()
        folder.snippets.append(snippet)
        folder.mergeSnippet(snippet)
        outlineView.reloadData()
        outlineView.expandItem(folder)
        outlineView.selectRowIndexes(IndexSet(integer: outlineView.row(forItem: snippet)), byExtendingSelection: false)
        changeItemFocus()
    }

    @IBAction private func addFolderButtonTapped(_ sender: AnyObject) {
        let folder = CPYFolder.create()
        folders.append(folder)
        folder.merge()
        outlineView.reloadData()
        outlineView.selectRowIndexes(IndexSet(integer: outlineView.row(forItem: folder)), byExtendingSelection: false)
        changeItemFocus()
    }

    @IBAction private func deleteButtonTapped(_ sender: AnyObject) {
        guard let item = outlineView.item(atRow: outlineView.selectedRow) else {
            NSSound.beep()
            return
        }

        let alert = NSAlert()
        alert.messageText = NSLocalizedString("Delete Item", comment: "")
        alert.informativeText = NSLocalizedString("Are you sure want to delete this item?", comment: "")
        alert.addButton(withTitle: NSLocalizedString("Delete Item", comment: ""))
        alert.addButton(withTitle: NSLocalizedString("Cancel", comment: ""))
        NSApp.activate(ignoringOtherApps: true)
        let result = alert.runModal()
        if result != NSApplication.ModalResponse.alertFirstButtonReturn { return }

        if let folder = item as? CPYFolder {
            folders.removeObject(folder)
            folder.remove()
            AppEnvironment.current.hotKeyService.unregisterSnippetHotKey(with: folder.identifier)
        } else if let snippet = item as? CPYSnippet, let folder = outlineView.parent(forItem: item) as? CPYFolder, let index = folder.snippets.index(of: snippet) {
            folder.snippets.remove(at: index)
            snippet.remove()
        }
        outlineView.reloadData()
        changeItemFocus()
    }

    @IBAction private func changeStatusButtonTapped(_ sender: AnyObject) {
        guard let item = outlineView.item(atRow: outlineView.selectedRow) else {
            NSSound.beep()
            return
        }
        if let folder = item as? CPYFolder {
            folder.enable = !folder.enable
            folder.merge()
        } else if let snippet = item as? CPYSnippet {
            snippet.enable = !snippet.enable
            snippet.merge()
        }
        outlineView.reloadData()
        changeItemFocus()
    }

    @IBAction private func importSnippetButtonTapped(_ sender: AnyObject) {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.directoryURL = URL(fileURLWithPath: NSHomeDirectory())
        panel.allowedContentTypes = [.xml]
        let returnCode = panel.runModal()

        if returnCode != NSApplication.ModalResponse.OK { return }

        let fileURLs = panel.urls
        guard let url = fileURLs.first else { return }
        guard let data = try? Data(contentsOf: url) else { return }

        do {
            let realm = try! Realm()
            let lastFolder = realm.objects(CPYFolder.self).sorted(byKeyPath: #keyPath(CPYFolder.index), ascending: true).last
            var folderIndex = (lastFolder?.index ?? -1) + 1
            // Create Document
            var options = AEXMLOptions()
            options.parserSettings.shouldTrimWhitespace = false
            let xmlDocument = try AEXMLDocument(xml: data, options: options)
            xmlDocument[Constants.Xml.rootElement]
                .children
                .forEach { folderElement in
                    let folder = CPYFolder()
                    // Title
                    folder.title = folderElement[Constants.Xml.titleElement].value ?? "untitled folder"
                    // Index
                    folder.index = folderIndex
                    // Sync DB
                    realm.transaction { realm.add(folder) }
                    // Snippet
                    var snippetIndex = 0
                    folderElement[Constants.Xml.snippetsElement][Constants.Xml.snippetElement]
                        .all?
                        .forEach { snippetElement in
                            let snippet = CPYSnippet()
                            snippet.title = snippetElement[Constants.Xml.titleElement].value ?? "untitled snippet"
                            snippet.content = snippetElement[Constants.Xml.contentElement].value ?? ""
                            snippet.index = snippetIndex
                            realm.transaction { folder.snippets.append(snippet) }
                            // Increment snippet index
                            snippetIndex += 1
                        }
                    // Increment folder index
                    folderIndex += 1
                    // Add folder
                    let copyFolder = folder.deepCopy()
                    folders.append(copyFolder)
                }
            outlineView.reloadData()
        } catch {
            NSSound.beep()
        }
    }

    @IBAction private func exportSnippetButtonTapped(_ sender: AnyObject) {
        let xmlDocument = AEXMLDocument()
        let rootElement = xmlDocument.addChild(name: Constants.Xml.rootElement)

        let realm = try! Realm()
        let folders = realm.objects(CPYFolder.self).sorted(byKeyPath: #keyPath(CPYFolder.index), ascending: true)
        folders.forEach { folder in
            let folderElement = rootElement.addChild(name: Constants.Xml.folderElement)

            folderElement.addChild(name: Constants.Xml.titleElement, value: folder.title)

            let snippetsElement = folderElement.addChild(name: Constants.Xml.snippetsElement)
            folder.snippets
                .sorted(byKeyPath: #keyPath(CPYSnippet.index), ascending: true)
                .forEach { snippet in
                    let snippetElement = snippetsElement.addChild(name: Constants.Xml.snippetElement)
                    snippetElement.addChild(name: Constants.Xml.titleElement, value: snippet.title)
                    snippetElement.addChild(name: Constants.Xml.contentElement, value: snippet.content)
                }
        }

        let panel = NSSavePanel()
        panel.accessoryView = nil
        panel.canSelectHiddenExtension = true
        panel.allowedContentTypes = [.xml]
        panel.directoryURL = URL(fileURLWithPath: NSHomeDirectory())
        panel.nameFieldStringValue = "snippets"
        let returnCode = panel.runModal()

        if returnCode != NSApplication.ModalResponse.OK { return }

        guard let data = xmlDocument.xml.data(using: String.Encoding.utf8) else { return }
        guard let url = panel.url else { return }

        do {
            try data.write(to: url, options: .atomic)
        } catch {
            NSSound.beep()
        }
    }
}

// MARK: - Item Selected
extension CPYSnippetsEditorWindowController {
    func changeItemFocus() {
        // Reset TextView Undo/Redo history
        textView.undoManager?.removeAllActions()
        guard let item = outlineView.item(atRow: outlineView.selectedRow) else {
            folderSettingView.isHidden = true
            textView.isHidden = true
            folderShortcutRecordView.keyCombo = nil
            folderTitleTextField.stringValue = ""
            return
        }
        if let folder = item as? CPYFolder {
            textView.string = ""
            folderTitleTextField.stringValue = folder.title
            folderShortcutRecordView.keyCombo = AppEnvironment.current.hotKeyService.snippetKeyCombo(forIdentifier: folder.identifier)
            folderSettingView.isHidden = false
            textView.isHidden = true
        } else if let snippet = item as? CPYSnippet {
            textView.string = snippet.content
            folderTitleTextField.stringValue = ""
            folderShortcutRecordView.keyCombo = nil
            folderSettingView.isHidden = true
            textView.isHidden = false
        }
    }
}

// MARK: - NSSplitView Delegate
extension CPYSnippetsEditorWindowController: NSSplitViewDelegate {
    func splitView(_ splitView: NSSplitView, constrainMinCoordinate proposedMinimumPosition: CGFloat, ofSubviewAt dividerIndex: Int) -> CGFloat {
        return proposedMinimumPosition + 150
    }

    func splitView(_ splitView: NSSplitView, constrainMaxCoordinate proposedMaximumPosition: CGFloat, ofSubviewAt dividerIndex: Int) -> CGFloat {
        return proposedMaximumPosition / 2
    }
}

// MARK: - NSOutlineView Delegate
extension CPYSnippetsEditorWindowController: NSOutlineViewDelegate {
    func outlineView(_ outlineView: NSOutlineView, willDisplayCell cell: Any, for tableColumn: NSTableColumn?, item: Any) {
        guard let cell = cell as? CPYSnippetsEditorCell else { return }
        if let folder = item as? CPYFolder {
            cell.iconType = .folder
            cell.isItemEnabled = folder.enable
        } else if let snippet = item as? CPYSnippet {
            cell.iconType = .none
            cell.isItemEnabled = snippet.enable
        }
    }

    func outlineViewSelectionDidChange(_ notification: Notification) {
        changeItemFocus()
    }

    func control(_ control: NSControl, textShouldEndEditing fieldEditor: NSText) -> Bool {
        let text = fieldEditor.string
        guard !text.isEmpty else { return false }
        guard let outlineView = control as? NSOutlineView else { return false }
        guard let item = outlineView.item(atRow: outlineView.selectedRow) else { return false }
        if let folder = item as? CPYFolder {
            folder.title = text
            folder.merge()
        } else if let snippet = item as? CPYSnippet {
            snippet.title = text
            snippet.merge()
        }
        changeItemFocus()
        return true
    }
}

// MARK: - NSTextView Delegate
extension CPYSnippetsEditorWindowController: NSTextViewDelegate {
    func textView(_ textView: NSTextView, shouldChangeTextIn affectedCharRange: NSRange, replacementString: String?) -> Bool {
        guard let replacementString = replacementString else { return false }
        let text = textView.string
        guard let snippet = selectedSnippet else { return false }
        let string = (text as NSString).replacingCharacters(in: affectedCharRange, with: replacementString)
        snippet.content = string
        snippet.merge()
        return true
    }
}

// MARK: - RecordView Delegate
extension CPYSnippetsEditorWindowController: RecordViewDelegate {
    func recordViewShouldBeginRecording(_ recordView: RecordView) -> Bool {
        guard selectedFolder != nil else { return false }
        return true
    }

    func recordView(_ recordView: RecordView, canRecordKeyCombo keyCombo: KeyCombo) -> Bool {
        guard selectedFolder != nil else { return false }
        return true
    }

    func recordView(_ recordView: RecordView, didChangeKeyCombo keyCombo: KeyCombo?) {
        guard let selectedFolder = selectedFolder else { return }
        guard let keyCombo = keyCombo else {
            AppEnvironment.current.hotKeyService.unregisterSnippetHotKey(with: selectedFolder.identifier)
            return
        }
        AppEnvironment.current.hotKeyService.registerSnippetHotKey(with: selectedFolder.identifier, keyCombo: keyCombo)
    }

    func recordViewDidEndRecording(_ recordView: RecordView) {}
}
