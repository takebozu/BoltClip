//
//  NSCoding+Archive.swift
//
//  Clipstream
//  GitHub: https://github.com/clipy
//  HP: https://clipy-app.com
//
//  Created by Econa77 on 2016/11/19.
//
//  Copyright © 2015-2018 Clipstream Project.
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
