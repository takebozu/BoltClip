//
//  ClipService.swift
//
//  BoltClip
//  GitHub: https://github.com/takebozu/BoltClip
//
//  Created by Econa77 on 2016/11/17.
//
//  Copyright © 2015-2018 Clipy Project.
//

import Foundation
import Cocoa
import SwiftData
import PINCache
import RxSwift
import RxCocoa

final class ClipService {

    // MARK: - Properties
    fileprivate var cachedChangeCount = BehaviorRelay<Int>(value: 0)
    fileprivate var storeTypes = [String: NSNumber]()
    fileprivate let scheduler = SerialDispatchQueueScheduler(qos: .userInteractive)
    fileprivate let lock = NSRecursiveLock(name: "me.takezawa.BoltClip.ClipUpdatable")
    fileprivate var disposeBag = DisposeBag()

    // MARK: - Clips
    func startMonitoring() {
        disposeBag = DisposeBag()
        // Pasteboard observe timer
        Observable<Int>.interval(.milliseconds(750), scheduler: scheduler)
            .map { _ in NSPasteboard.general.changeCount }
            .withLatestFrom(cachedChangeCount.asObservable()) { ($0, $1) }
            .filter { $0 != $1 }
            .subscribe(onNext: { [weak self] changeCount, _ in
                self?.cachedChangeCount.accept(changeCount)
                self?.create()
            })
            .disposed(by: disposeBag)
        // Store types
        AppEnvironment.current.defaults.rx
            .observe([String: NSNumber].self, Constants.UserDefaults.storeTypes)
            .compactMap { $0 }
            .asDriver(onErrorDriveWith: .empty())
            .drive(onNext: { [weak self] in
                self?.storeTypes = $0
            })
            .disposed(by: disposeBag)
    }

    func clearAll() {
        let context = ModelContext(AppEnvironment.current.modelContainer)
        let descriptor = FetchDescriptor<CPYClip>()
        guard let clips = try? context.fetch(descriptor) else { return }

        // Delete saved images
        clips
            .filter { !$0.thumbnailPath.isEmpty }
            .map { $0.thumbnailPath }
            .forEach { PINCache.shared.removeObject(forKey: $0) }
        // Delete from SwiftData
        clips.forEach { context.delete($0) }
        try? context.save()
        // Delete written datas
        AppEnvironment.current.dataCleanService.cleanDatas()
    }

    func delete(with clip: CPYClip) {
        let context = ModelContext(AppEnvironment.current.modelContainer)
        // Delete saved images
        let path = clip.thumbnailPath
        if !path.isEmpty {
            PINCache.shared.removeObject(forKey: path)
        }
        // Delete from SwiftData
        let hash = clip.dataHash
        var descriptor = FetchDescriptor<CPYClip>(predicate: #Predicate { $0.dataHash == hash })
        descriptor.fetchLimit = 1
        if let existing = try? context.fetch(descriptor).first {
            context.delete(existing)
            try? context.save()
        }
    }

    func incrementChangeCount() {
        cachedChangeCount.accept(cachedChangeCount.value + 1)
    }

}

// MARK: - Create Clip
extension ClipService {
    fileprivate func create() {
        lock.lock(); defer { lock.unlock() }

        // Store types
        if !storeTypes.values.contains(NSNumber(value: true)) { return }
        // Pasteboard types
        let pasteboard = NSPasteboard.general
        let types = self.types(with: pasteboard)
        if types.isEmpty { return }

        // Excluded application
        guard !AppEnvironment.current.excludeAppService.frontProcessIsExcludedApplication() else { return }
        // Special applications
        guard !AppEnvironment.current.excludeAppService.copiedProcessIsExcludedApplications(pasteboard: pasteboard) else { return }

        // Create data
        let data = CPYClipData(pasteboard: pasteboard, types: types)
        save(with: data)
    }

    func create(with image: NSImage) {
        lock.lock(); defer { lock.unlock() }

        // Create only image data
        let data = CPYClipData(image: image)
        save(with: data)
    }

    fileprivate func save(with data: CPYClipData) {
        let container = AppEnvironment.current.modelContainer
        let context = ModelContext(container)

        // Copy already copied history
        let hashStr = "\(data.hash)"
        let isCopySameHistory = AppEnvironment.current.defaults.bool(forKey: Constants.UserDefaults.copySameHistory)
        var checkDescriptor = FetchDescriptor<CPYClip>(predicate: #Predicate { $0.dataHash == hashStr })
        checkDescriptor.fetchLimit = 1
        if (try? context.fetch(checkDescriptor).first) != nil, !isCopySameHistory { return }

        // Don't save empty string history
        if data.isOnlyStringType && data.stringValue.isEmpty { return }

        // Overwrite same history
        let isOverwriteHistory = AppEnvironment.current.defaults.bool(forKey: Constants.UserDefaults.overwriteSameHistory)
        let savedHash = (isOverwriteHistory) ? data.hash : Int.random(in: 0..<1000000)

        // Saved time and path
        let unixTime = Int(Date().timeIntervalSince1970)
        let savedPath = CPYUtilities.applicationSupportFolder() + "/\(NSUUID().uuidString).data"
        // Create clip object
        let clip = CPYClip()
        clip.dataPath = savedPath
        if data.stringValue.isEmpty && !data.fileNames.isEmpty {
            clip.title = data.fileNames.map { URL(fileURLWithPath: $0).lastPathComponent }.joined(separator: ", ")
        } else {
            clip.title = data.stringValue[0...10000]
        }
        clip.dataHash = "\(savedHash)"
        clip.updateTime = unixTime
        clip.primaryType = data.primaryType?.rawValue ?? ""

        DispatchQueue.main.async {
            // Save thumbnail image
            if let thumbnailImage = data.thumbnailImage {
                PINCache.shared.setObjectAsync(thumbnailImage, forKey: "\(unixTime)", completion: nil)
                clip.thumbnailPath = "\(unixTime)"
            }
            if let colorCodeImage = data.colorCodeImage {
                PINCache.shared.setObjectAsync(colorCodeImage, forKey: "\(unixTime)", completion: nil)
                clip.thumbnailPath = "\(unixTime)"
                clip.isColorCode = true
            }
            // Save SwiftData and .data file
            let mainContext = AppEnvironment.current.modelContainer.mainContext
            if CPYUtilities.prepareSaveToPath(CPYUtilities.applicationSupportFolder()) {
                if let archivedData = try? NSKeyedArchiver.archivedData(withRootObject: data, requiringSecureCoding: false) {
                    let savedURL = URL(fileURLWithPath: savedPath)
                    if (try? archivedData.write(to: savedURL)) != nil {
                        mainContext.insert(clip)
                        try? mainContext.save()
                    }
                }
            }
        }
    }

    private func types(with pasteboard: NSPasteboard) -> [NSPasteboard.PasteboardType] {
        let types = pasteboard.types?.filter { canSave(with: $0) } ?? []
        return NSOrderedSet(array: types).array as? [NSPasteboard.PasteboardType] ?? []
    }

    private func canSave(with type: NSPasteboard.PasteboardType) -> Bool {
        let dictionary = CPYClipData.availableTypesDictionary
        guard let value = dictionary[type] else { return false }
        guard let number = storeTypes[value] else { return false }
        return number.boolValue
    }
}
