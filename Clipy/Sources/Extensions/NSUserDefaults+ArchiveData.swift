//
//  NSUserDefaults+ArchiveData.swift
//
//  Clipstream
//  GitHub: https://github.com/clipy
//  HP: https://clipy-app.com
//
//  Created by Econa77 on 2016/06/23.
//
//  Copyright © 2015-2018 Clipstream Project.
//

import Foundation
import Cocoa

extension UserDefaults {
    func setArchiveData<T: NSCoding>(_ object: T, forKey key: String) {
        guard let data = try? NSKeyedArchiver.archivedData(withRootObject: object, requiringSecureCoding: false) else { return }
        set(data, forKey: key)
    }

    func archiveDataForKey<T: NSCoding>(_: T.Type, key: String) -> T? {
        guard let data = object(forKey: key) as? Data else { return nil }
        guard let unarchiver = try? NSKeyedUnarchiver(forReadingFrom: data) else { return nil }
        unarchiver.requiresSecureCoding = false
        defer { unarchiver.finishDecoding() }
        guard let object = unarchiver.decodeObject(forKey: NSKeyedArchiveRootObjectKey) as? T else { return nil }
        return object
    }
}
