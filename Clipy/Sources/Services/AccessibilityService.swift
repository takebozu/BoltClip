// 
//  AccessibilityService.swift
//
//  BoltClip
//  GitHub: https://github.com/takebozu/BoltClip
// 
//  Created by Econa77 on 2018/10/03.
// 
//  Copyright © 2015-2018 Clipy Project.
//

import Foundation
import Cocoa

final class AccessibilityService {}

// MARK: - Permission
extension AccessibilityService {
    @discardableResult
    func isAccessibilityEnabled(isPrompt: Bool) -> Bool {
        // Accessibility permission is required for paste command from macOS 10.14 Mojave.
        // For macOS 10.14 and later only, check accessibility permission at startup and paste
        guard #available(macOS 10.14, *) else { return true }

        let checkOptionPromptKey = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let opts = [checkOptionPromptKey: isPrompt] as CFDictionary
        return AXIsProcessTrustedWithOptions(opts)
    }

    func showAccessibilityAuthenticationAlert() {
        let alert = NSAlert()
        alert.messageText = String(localized: "Please allow Accessibility")
        alert.informativeText = String(localized: "BoltClip requires Accessibility permission to paste clipboard items. Please enable \"Accessibility\" in the \"Security & Privacy\" preferences in System Settings.")
        alert.addButton(withTitle: String(localized: "Open System Preferences"))
        NSApp.activate(ignoringOtherApps: true)

        if alert.runModal() == NSApplication.ModalResponse.alertFirstButtonReturn {
            guard !openAccessibilitySettingWindow() else { return }
            isAccessibilityEnabled(isPrompt: true)
        }
    }

    func openAccessibilitySettingWindow() -> Bool {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") else { return false }
        return NSWorkspace.shared.open(url)
    }
}
