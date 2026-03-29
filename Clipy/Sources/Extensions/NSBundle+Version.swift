//
//  NSBundle+Version.swift
//
//  Clipstream
//  GitHub: https://github.com/clipy
//  HP: https://clipy-app.com
//
//  Created by Econa77 on 2016/03/29.
//
//  Copyright © 2015-2018 Clipstream Project.
//

import Foundation

extension Bundle {
    var appVersion: String? {
        return infoDictionary?["CFBundleShortVersionString"] as? String
    }
}
