//
//  CPYClip.swift
//
//  BoltClip
//  GitHub: https://github.com/takebozu/BoltClip
//
//  Created by Econa77 on 2015/06/21.
//
//  Copyright © 2015-2018 Clipy Project.
//  Copyright © 2026 Satoshi Takezawa
//

import Cocoa
import SwiftData

@Model
final class CPYClip {

    // MARK: - Properties
    var dataPath: String = ""
    var title: String = ""
    @Attribute(.unique) var dataHash: String = ""
    var primaryType: String = ""
    var updateTime: Int = 0
    var thumbnailPath: String = ""
    var isColorCode: Bool = false

    init() {}

    init(dataPath: String = "", title: String = "", dataHash: String = "",
         primaryType: String = "", updateTime: Int = 0,
         thumbnailPath: String = "", isColorCode: Bool = false) {
        self.dataPath = dataPath
        self.title = title
        self.dataHash = dataHash
        self.primaryType = primaryType
        self.updateTime = updateTime
        self.thumbnailPath = thumbnailPath
        self.isColorCode = isColorCode
    }

}
