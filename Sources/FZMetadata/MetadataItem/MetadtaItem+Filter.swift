//
//  MetadtaItem+Filter.swift
//
//
//  Created by Florian Zand on 01.05.25.
//

import Foundation

extension [MetadataItem] {
    func filter(maxDepth: Int, folders: [URL]) -> [MetadataItem] {
        guard !folders.isEmpty, maxDepth >= 0 else {
            return self
        }
        let processedFolders = folders.map{ ProcessedFolder($0) }.sorted { $0.componentCount > $1.componentCount }
        let strictMaxAllowedComponents = processedFolders.first?.componentCount ?? 0 + maxDepth

        let collectorQueue = DispatchQueue(label: "MetadataItem.FilterQueue")
        let items = indexed()
        var filteredItems: [(Int, MetadataItem)] = []
        DispatchQueue.concurrentPerform(iterations: items.count) { index in
            let item = items[index]
            guard let url = item.element.url else { return }
            let standardizedUrl = url.standardizedFileURL
            let urlComponents = standardizedUrl.pathComponents
            let urlComponentCount = urlComponents.count
            guard urlComponentCount <= strictMaxAllowedComponents else {
                return
            }
            for folderInfo in processedFolders {
                guard urlComponentCount >= folderInfo.componentCount else {
                    continue
                }
                if urlComponents.starts(with: folderInfo.components) {
                    let depth = urlComponentCount - folderInfo.componentCount
                    if depth <= maxDepth {
                        collectorQueue.sync {
                            filteredItems.append(item)
                        }
                        break
                    } else {
                        break
                    }
                }
            }
        }
        return filteredItems.sorted(by: \.0, .smallestFirst).map({$0.1})
    }
}

fileprivate struct ProcessedFolder {
    let original: URL
    let components: [String]
    let componentCount: Int
    
    init(_ url: URL) {
        original = url
        components = url.standardizedFileURL.pathComponents
        componentCount = components.count
    }
}
