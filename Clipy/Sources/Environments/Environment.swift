//
//  Environment.swift
//
//  BoltClip
//  GitHub: https://github.com/takebozu/BoltClip
//
//  Created by Econa77 on 2017/08/10.
//
//  Copyright © 2015-2018 Clipy Project.
//

import Foundation
import SwiftData

struct Environment {

    // MARK: - Properties
    let clipService: ClipService
    let hotKeyService: HotKeyService
    let dataCleanService: DataCleanService
    let pasteService: PasteService
    let excludeAppService: ExcludeAppService
    let accessibilityService: AccessibilityService
    let menuManager: MenuManager

    let defaults: UserDefaults
    let modelContainer: ModelContainer

    // MARK: - Initialize
    init(clipService: ClipService = ClipService(),
         hotKeyService: HotKeyService = HotKeyService(),
         dataCleanService: DataCleanService = DataCleanService(),
         pasteService: PasteService = PasteService(),
         excludeAppService: ExcludeAppService = ExcludeAppService(applications: []),
         accessibilityService: AccessibilityService = AccessibilityService(),
         menuManager: MenuManager = MenuManager(),
         defaults: UserDefaults = .standard,
         modelContainer: ModelContainer = try! ModelContainer(for: CPYClip.self, CPYFolder.self, CPYSnippet.self)) {

        self.clipService = clipService
        self.hotKeyService = hotKeyService
        self.dataCleanService = dataCleanService
        self.pasteService = pasteService
        self.excludeAppService = excludeAppService
        self.accessibilityService = accessibilityService
        self.menuManager = menuManager
        self.defaults = defaults
        self.modelContainer = modelContainer
    }

}
