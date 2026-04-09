//
//  CPYSplitView.swift
//
//  BoltClip
//  GitHub: https://github.com/takebozu/BoltClip
//
//  Created by Econa77 on 2016/06/29.
//
//  Copyright © 2015-2018 Clipy Project.
//  Copyright © 2026 Satoshi Takezawa
//

import Cocoa

class CPYSplitView: NSSplitView {

    // MARK: - Properties
    @IBInspectable var separatorColor: NSColor = .separatorColor {
        didSet {
            needsDisplay = true
        }
    }

    // MARK: - Draw
    override func drawDivider(in rect: NSRect) {
        separatorColor.setFill()
        rect.fill()
    }

}
