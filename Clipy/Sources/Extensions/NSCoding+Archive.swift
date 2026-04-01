//
//  NSCoding+Archive.swift
//
//  BoltClip
//  GitHub: https://github.com/takebozu/BoltClip
//
//  Created by Econa77 on 2016/11/19.
//
//  Copyright © 2015-2018 Clipy Project.
//

import Foundation

extension NSCoding {
    func archive() -> Data {
        return (try? NSKeyedArchiver.archivedData(withRootObject: self, requiringSecureCoding: false)) ?? Data()
    }
}

extension Array where Element: NSCoding {
    func archive() -> Data {
        return (try? NSKeyedArchiver.archivedData(withRootObject: self, requiringSecureCoding: false)) ?? Data()
    }
}
