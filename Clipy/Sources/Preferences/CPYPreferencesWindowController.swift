//
//  CPYPreferencesWindowController.swift
//
//  BoltClip
//  GitHub: https://github.com/takebozu/BoltClip
//
//  Created by Econa77 on 2016/02/25.
//
//  Copyright © 2015-2018 Clipy Project.
//  Copyright © 2026 Satoshi Takezawa
//

import Cocoa

final class CPYPreferencesWindowController: NSWindowController {

    // MARK: - Properties
    static let sharedController: CPYPreferencesWindowController = {
        let window = NSWindow(
            contentRect: NSRect(x: 196, y: 240, width: 480, height: 374),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: true
        )
        window.title = String(localized: "BoltClip - Setting")
        window.isReleasedWhenClosed = false
        window.collectionBehavior = .canJoinAllSpaces

        let controller = CPYPreferencesWindowController(window: window)
        window.delegate = controller
        controller.setupToolbar()
        controller.switchView(Tab.general.rawValue)
        return controller
    }()

    private let viewControllers: [NSViewController] = [
        NSViewController(nibName: "CPYGeneralPreferenceViewController", bundle: nil),
        NSViewController(nibName: "CPYMenuPreferenceViewController", bundle: nil),
        CPYTypePreferenceViewController(nibName: "CPYTypePreferenceViewController", bundle: nil),
        CPYExcludeAppPreferenceViewController(nibName: "CPYExcludeAppPreferenceViewController", bundle: nil),
        CPYShortcutsPreferenceViewController(nibName: "CPYShortcutsPreferenceViewController", bundle: nil),
        CPYUpdatesPreferenceViewController(),
        CPYBetaPreferenceViewController(nibName: "CPYBetaPreferenceViewController", bundle: nil)
    ]

    private enum Tab: Int, CaseIterable {
        case general, menu, type, exclude, shortcuts, updates, beta

        var identifier: NSToolbarItem.Identifier {
            switch self {
            case .general:   return .init("general")
            case .menu:      return .init("menu")
            case .type:      return .init("type")
            case .exclude:   return .init("exclude")
            case .shortcuts: return .init("shortcuts")
            case .updates:   return .init("updates")
            case .beta:      return .init("beta")
            }
        }

        var label: String {
            switch self {
            case .general:   return String(localized: "General")
            case .menu:      return String(localized: "Menu")
            case .type:      return String(localized: "Type")
            case .exclude:   return String(localized: "Exclude")
            case .shortcuts: return String(localized: "Shortcuts")
            case .updates:   return String(localized: "Updates")
            case .beta:      return String(localized: "Beta")
            }
        }

        var symbolName: String {
            switch self {
            case .general:   return "gearshape"
            case .menu:      return "list.bullet"
            case .type:      return "doc.on.clipboard"
            case .exclude:   return "minus.circle"
            case .shortcuts: return "command"
            case .updates:   return "arrow.triangle.2.circlepath"
            case .beta:      return "flask"
            }
        }
    }

    // MARK: - Setup
    private func setupToolbar() {
        let toolbar = NSToolbar(identifier: "PreferencesToolbar")
        toolbar.delegate = self
        toolbar.displayMode = .iconAndLabel
        toolbar.allowsUserCustomization = false
        toolbar.selectedItemIdentifier = Tab.general.identifier
        window?.toolbar = toolbar
        window?.toolbarStyle = .preference
    }

    // MARK: - Window Life Cycle
    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)
        window?.makeKeyAndOrderFront(self)
    }
}

// MARK: - NSToolbarDelegate
extension CPYPreferencesWindowController: NSToolbarDelegate {
    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        guard let tab = Tab.allCases.first(where: { $0.identifier == itemIdentifier }) else { return nil }
        let item = NSToolbarItem(itemIdentifier: itemIdentifier)
        item.label = tab.label
        item.image = NSImage(systemSymbolName: tab.symbolName, accessibilityDescription: tab.label)
        item.target = self
        item.action = #selector(toolbarItemTapped(_:))
        item.tag = tab.rawValue
        return item
    }

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        Tab.allCases.map(\.identifier)
    }

    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        Tab.allCases.map(\.identifier)
    }

    func toolbarSelectableItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        Tab.allCases.map(\.identifier)
    }
}

// MARK: - Actions
extension CPYPreferencesWindowController {
    @objc private func toolbarItemTapped(_ sender: NSToolbarItem) {
        switchView(sender.tag)
    }
}

// MARK: - NSWindowDelegate
extension CPYPreferencesWindowController: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        if let typeVC = viewControllers[2] as? CPYTypePreferenceViewController {
            AppEnvironment.current.defaults.set(typeVC.storeTypes, forKey: Constants.UserDefaults.storeTypes)
            AppEnvironment.current.defaults.synchronize()
        }
        if let window = window, !window.makeFirstResponder(window) {
            window.endEditing(for: nil)
        }
        NSApp.deactivate()
    }
}

// MARK: - Layout
private extension CPYPreferencesWindowController {
    func switchView(_ index: Int) {
        let newView = viewControllers[index].view
        window?.contentView?.subviews.forEach { $0.removeFromSuperview() }

        let frame = window!.frame
        var newFrame = window!.frameRect(forContentRect: newView.frame)
        newFrame.origin = frame.origin
        newFrame.origin.y += frame.height - newFrame.height
        window?.setFrame(newFrame, display: true)
        window?.contentView?.addSubview(newView)
    }
}
