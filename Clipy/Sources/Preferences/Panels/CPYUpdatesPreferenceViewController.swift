//
//  CPYUpdatesPreferenceViewController.swift
//
//  BoltClip
//  GitHub: https://github.com/takebozu/BoltClip
//
//  Copyright © 2015-2018 Clipy Project.
//  Copyright © 2026 Satoshi Takezawa
//

import Cocoa
import Sparkle

final class CPYUpdatesPreferenceViewController: NSViewController {

    // MARK: - Properties
    private var updater: SPUUpdater? {
        (NSApp.delegate as? AppDelegate)?.updaterController.updater
    }

    private let automaticCheckButton = NSButton(checkboxWithTitle: "", target: nil, action: nil)
    private let intervalPopUp = NSPopUpButton(frame: .zero, pullsDown: false)
    private let lastCheckField = NSTextField(labelWithString: "")
    private let versionField = NSTextField(labelWithString: "")

    // MARK: - Life Cycle
    override func loadView() {
        let container = NSView(frame: NSRect(x: 0, y: 0, width: 480, height: 134))
        self.view = container

        setupCheckNowButton(in: container)
        setupAutomaticCheckControls(in: container)
        setupLastCheckField(in: container)
        setupVersionField(in: container)
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        updateLastCheckDate()
    }

    // MARK: - Setup
    private func setupCheckNowButton(in container: NSView) {
        let button = NSButton(title: String(localized: "Check Now"), target: self, action: #selector(checkForUpdates))
        button.bezelStyle = .rounded
        button.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(button)
        NSLayoutConstraint.activate([
            button.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            button.topAnchor.constraint(equalTo: container.topAnchor, constant: 12)
        ])
    }

    private func setupAutomaticCheckControls(in container: NSView) {
        automaticCheckButton.title = String(localized: "Automatically check for updates:")
        automaticCheckButton.target = self
        automaticCheckButton.action = #selector(toggleAutomaticChecks(_:))
        automaticCheckButton.state = (updater?.automaticallyChecksForUpdates == true) ? .on : .off
        automaticCheckButton.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(automaticCheckButton)

        intervalPopUp.addItems(withTitles: [
            String(localized: "Daily"),
            String(localized: "Weekly"),
            String(localized: "Monthly")
        ])
        intervalPopUp.itemArray[0].tag = 86400
        intervalPopUp.itemArray[1].tag = 604800
        intervalPopUp.itemArray[2].tag = 2592000
        if let interval = updater?.updateCheckInterval {
            intervalPopUp.selectItem(withTag: Int(interval))
        }
        intervalPopUp.isEnabled = automaticCheckButton.state == .on
        intervalPopUp.target = self
        intervalPopUp.action = #selector(changeCheckInterval(_:))
        intervalPopUp.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(intervalPopUp)

        NSLayoutConstraint.activate([
            automaticCheckButton.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 60),
            automaticCheckButton.topAnchor.constraint(equalTo: container.topAnchor, constant: 50),
            intervalPopUp.leadingAnchor.constraint(equalTo: automaticCheckButton.trailingAnchor, constant: 8),
            intervalPopUp.centerYAnchor.constraint(equalTo: automaticCheckButton.centerYAnchor),
            intervalPopUp.widthAnchor.constraint(equalToConstant: 110)
        ])
    }

    private func setupLastCheckField(in container: NSView) {
        lastCheckField.font = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)
        lastCheckField.textColor = .secondaryLabelColor
        lastCheckField.alignment = .center
        lastCheckField.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(lastCheckField)
        NSLayoutConstraint.activate([
            lastCheckField.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            lastCheckField.topAnchor.constraint(equalTo: container.topAnchor, constant: 80)
        ])
    }

    private func setupVersionField(in container: NSView) {
        versionField.stringValue = "v\(Bundle.main.appVersion ?? "")"
        versionField.font = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)
        versionField.textColor = .secondaryLabelColor
        versionField.alignment = .center
        versionField.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(versionField)
        NSLayoutConstraint.activate([
            versionField.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            versionField.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -12)
        ])
    }

    // MARK: - Actions
    @objc private func checkForUpdates() {
        (NSApp.delegate as? AppDelegate)?.updaterController.checkForUpdates(nil)
        // Delay to allow Sparkle to update the last check date
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.updateLastCheckDate()
        }
    }

    @objc private func toggleAutomaticChecks(_ sender: NSButton) {
        let enabled = sender.state == .on
        updater?.automaticallyChecksForUpdates = enabled
        intervalPopUp.isEnabled = enabled
    }

    @objc private func changeCheckInterval(_ sender: NSPopUpButton) {
        guard let tag = sender.selectedItem?.tag else { return }
        updater?.updateCheckInterval = TimeInterval(tag)
    }

    // MARK: - Helpers
    private func updateLastCheckDate() {
        if let date = updater?.lastUpdateCheckDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .full
            formatter.timeStyle = .medium
            lastCheckField.stringValue = formatter.string(from: date)
        } else {
            lastCheckField.stringValue = ""
        }
    }
}
