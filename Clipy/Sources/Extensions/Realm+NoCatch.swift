//
//  Realm+NoCatch.swift
//
//  Clipstream
//  GitHub: https://github.com/clipy
//  HP: https://clipy-app.com
//
//  Created by Econa77 on 2016/03/11.
//
//  Copyright © 2015-2018 Clipstream Project.
//

import Foundation
import RealmSwift

extension Realm {
    func transaction(_ block: (() throws -> Void)) {
        do {
            try write(block)
        } catch {}
    }
}
