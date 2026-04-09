//
//  NSLock+BoltClip.swift
//
//  BoltClip
//  GitHub: https://github.com/takebozu/BoltClip
//
//  Created by Econa77 on 2016/01/20.
//
//  Copyright © 2015-2018 Clipy Project.
//  Copyright © 2026 Satoshi Takezawa
//

import Foundation

extension NSRecursiveLock {
    convenience init(name: String) {
        self.init()
        self.name = name
    }
}
