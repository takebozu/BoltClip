//
//  DataCleanService.swift
//
//  BoltClip
//  GitHub: https://github.com/takebozu/BoltClip
//
//  Created by Econa77 on 2016/11/20.
//
//  Copyright © 2015-2018 Clipy Project.
//

import Foundation
import RxSwift
import SwiftData
import PINCache

final class DataCleanService {

    // MARK: - Properties
    fileprivate var disposeBag = DisposeBag()
    fileprivate let scheduler = SerialDispatchQueueScheduler(qos: .utility)

    // MARK: - Monitoring
    func startMonitoring() {
        disposeBag = DisposeBag()
        // Clean datas every 30 minutes
        Observable<Int>.interval(.seconds(60 * 30), scheduler: scheduler)
            .subscribe(onNext: { [weak self] _ in
                self?.cleanDatas()
            })
            .disposed(by: disposeBag)
    }

    // MARK: - Delete Data
    func cleanDatas() {
        let context = ModelContext(AppEnvironment.current.modelContainer)
        let flowHistories = overflowingClips(with: context)
        flowHistories
            .filter { !$0.thumbnailPath.isEmpty }
            .map { $0.thumbnailPath }
            .forEach { PINCache.shared.removeObject(forKey: $0) }
        flowHistories.forEach { context.delete($0) }
        try? context.save()
        cleanFiles(with: context)
    }

    private func overflowingClips(with context: ModelContext) -> [CPYClip] {
        let descriptor = FetchDescriptor<CPYClip>(sortBy: [SortDescriptor(\.updateTime, order: .reverse)])
        let maxHistorySize = AppEnvironment.current.defaults.integer(forKey: Constants.UserDefaults.maxHistorySize)

        guard let clips = try? context.fetch(descriptor) else { return [] }
        guard clips.count > maxHistorySize else { return [] }

        let lastClip = clips[maxHistorySize - 1]
        let cutoffTime = lastClip.updateTime
        let targetDescriptor = FetchDescriptor<CPYClip>(predicate: #Predicate { $0.updateTime < cutoffTime })
        return (try? context.fetch(targetDescriptor)) ?? []
    }

    private func cleanFiles(with context: ModelContext) {
        let fileManager = FileManager.default
        guard let paths = try? fileManager.contentsOfDirectory(atPath: CPYUtilities.applicationSupportFolder()) else { return }

        let descriptor = FetchDescriptor<CPYClip>()
        guard let allClips = try? context.fetch(descriptor) else { return }
        let allClipPaths = allClips.compactMap { $0.dataPath.components(separatedBy: "/").last }

        // Delete diff datas
        DispatchQueue.main.async {
            Set(allClipPaths).symmetricDifference(paths)
                .map { CPYUtilities.applicationSupportFolder() + "/" + "\($0)" }
                .forEach { CPYUtilities.deleteData(at: $0) }
        }
    }
}
