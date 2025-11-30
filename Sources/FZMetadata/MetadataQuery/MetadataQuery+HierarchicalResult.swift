//
//  HierarchicalResult.swift
//  
//
//  Created by Florian Zand on 31.08.24.
//

import Foundation
import FZSwiftUtils

extension MetadataQuery {
    /**
     The hierarchical query results.
     
     The items of the query’s results are mapped hierarchically to their file system path.
     */
    public class HierarchicalResult: CustomStringConvertible, Hashable {
        var items: [MappedItem]
        
        struct MappedItem: Hashable {
            let item: MetadataItem
            let url: URL
            let components: [String]
            init?(_ item: MetadataItem) {
                guard let url = item.url else { return nil }
                self.item = item
                self.components = url.pathComponents
                self.url = url
            }
        }
        
        
        /// The files of the results.
        public var files: [File] {
            _files
        }
        
        /// The folders of the results.
        public var folders: [Folder] {
            _folders
        }
        
        /// The url to the top level folder.
        public var topLevelURL: URL {
            _topLevelURL
        }
        
        /// The file at the specified url.
        public func file(at url: URL) -> File? {
            let pathComponents = url.pathComponents
            if pathComponents.count == level {
                return files.first(where: {$0.url == url })
            } else if pathComponents.count > level {
                return folders.filter({ $0.url.pathComponents[safe: level] == pathComponents[level] }).compactMap({ $0.file(at: url ) }).first
            }
            return nil
        }
        
        /// The folder at the specified url.
        public func folder(at url: URL) -> Folder? {
            let pathComponents = url.pathComponents
            if pathComponents.count == level {
                return folders.first(where: {$0.url == url })
            } else if pathComponents.count > level {
                return folders.filter({ $0.url.pathComponents[safe: level] == pathComponents[level] }).compactMap({ $0.folder(at: url ) }).first
            }
            return nil
        }
        
        /// The metadata item at the specified url.
        func item(at url: URL) -> MetadataItem? {
            let pathComponents = url.pathComponents
            if pathComponents.count == level {
                return files.first(where: {$0.url == url })?.item
            } else if pathComponents.count > level {
                return folders.filter({ $0.url.pathComponents[safe: level] == pathComponents[level] }).compactMap({ $0.item(at: url ) }).first
            }
            return nil
        }
        
        /// The metadata item at the specified url.
        public subscript(url: URL) -> MetadataItem? {
            item(at: url)
        }
        
        /// Returns all files including the files of all folders.
        public var allFiles: [File] {
            files + folders.flatMap({$0.allFiles})
        }
        
        /// Returns all folders including the subfolders of all folders.
        public var allFolders: [Folder] {
            folders + folders.flatMap({$0.allSubfolders})
        }
        
        /// Returns all items including the items of all files and foldes.
        public var allItems: [MetadataItem] {
            files.compactMap({$0.item}) + folders.flatMap({$0.allItems}) + folders.compactMap({$0.item})
        }
        
        /// Returns all files up to the maximum depth including the files of all files and foldes.
        public func allFiles(maxDepth: Int) -> [File] {
            guard maxDepth > 0 else { return files }
            return files + folders.flatMap({$0.allFiles(maxDepth: level + maxDepth)})
        }
        
        /// Returns all folders up to the maximum depth including the subfolders of all folders.
        public func allFolders(maxDepth: Int) -> [Folder] {
            guard maxDepth > 0 else { return folders }
            return folders + folders.flatMap({$0.allSubfolders(maxDepth: level + maxDepth)})
        }
        
        /// Returns all items up to the maximum depth including the items of all files and foldes.
        public func allItems(maxDepth: Int) -> [MetadataItem] {
            guard maxDepth > 0 else { return files.compactMap({$0.item}) + folders.compactMap({$0.item}) }
            return files.compactMap({$0.item}) + folders.flatMap({$0.allItems(maxDepth: level + maxDepth)}) + folders.compactMap({$0.item})
        }
              
        public init(_ items: [MetadataItem]) {
            self.items = items.compactMap({ MappedItem($0) })
        }
        
        public var description: String {
            var values: [String] = []
            values.append("MappedQueryResults(")
            values.append(contentsOf: Folder(files: files, subfolders: folders).strings(index: 1))
            values.append(")")
            return values.joined(separator: "\n")
        }
        
        public static func == (lhs: MetadataQuery.HierarchicalResult, rhs: MetadataQuery.HierarchicalResult) -> Bool {
            lhs.hashValue == rhs.hashValue
        }
        
        public func hash(into hasher: inout Hasher) {
            hasher.combine(items)
        }
        
        private lazy var _files: [File] = {
            updateValues()
            return files
        }()
        
        private lazy var _folders: [Folder] = {
            updateValues()
            return folders
        }()
        
        private lazy var _topLevelURL: URL = {
            updateValues()
            return topLevelURL
        }()
        
        lazy var level: Int = {
            updateValues()
            return level
        }()
        
        func updateValues() {
            let main = Folder(items)
            self._files = main.files
            self._folders = main.subfolders
            self.level = main.level
            self._topLevelURL = main.url
            items = []
        }
    }
}

extension MetadataQuery.HierarchicalResult {
    /// File of a hierarchical query results.
    public class File: CustomStringConvertible, Hashable {
        /// The url of the file.
        public let url: URL
        
        /// The metadata item of the file.
        public let item: MetadataItem
        
        /// The parent folder of the file.
        public let parent: Folder?
        
        public let level: Int
        
        init(_ item: MetadataItem, parent: Folder? = nil, level: Int = 0) {
            self.url = item.url!
            self.item = item
            self.parent = parent
            self.level = level
        }
        
        public var description: String {
            url.lastPathComponent
        }
        
        public static func == (lhs: MetadataQuery.HierarchicalResult.File, rhs: MetadataQuery.HierarchicalResult.File) -> Bool {
            lhs.hashValue == rhs.hashValue
        }
        
        public func hash(into hasher: inout Hasher) {
            hasher.combine(item)
        }
    }
}

extension MetadataQuery.HierarchicalResult {
    /// Folder of a hierarchical query results.
    public class Folder: Hashable, CustomStringConvertible {
        
        var items: [MappedItem]
        let level: Int
        
        /// The url of the folder.
        public let url: URL
        
        /// The name of the folder.
        public var name: String {
            url.lastPathComponent
        }
        
        /// The metadata item of the folder.
        public var item: MetadataItem? {
            _item
        }
        
        /// The files of the folder.
        public var files: [File] {
            _files
        }
        
        /// The subfolders of the folder.
        public var subfolders: [Folder] {
            _subfolders
        }
        
        /// The parent folder.
        public var parent: Folder? = nil
                
        /// All subfolders.
        public var allSubfolders: [Folder] {
            subfolders + subfolders.flatMap({$0.allSubfolders})
        }
        
        /// All files including the files of all subfolders.
        public var allFiles: [File] {
            files + subfolders.flatMap({$0.allFiles})
        }
        
        /// All metadata items including the items of all subfolders.
        public var allItems: [MetadataItem] {
            files.compactMap({$0.item}) + subfolders.compactMap({$0.item}) + subfolders.flatMap({$0.allItems})
        }
        
        func allFiles(maxDepth: Int) -> [File] {
            var files = files
            if level < maxDepth {
                files += subfolders.flatMap({$0.allFiles(maxDepth: maxDepth)})
            }
            return files
        }
        
        func allSubfolders(maxDepth: Int) -> [Folder] {
            var subfolders = subfolders
            if level < maxDepth {
                subfolders += subfolders.flatMap({$0.allSubfolders(maxDepth: maxDepth)})
            }
            return subfolders
        }
        
        func allItems(maxDepth: Int) -> [MetadataItem] {
            var items = files.compactMap({$0.item})
            if level < maxDepth {
                items += subfolders.compactMap({$0.item}) + subfolders.flatMap({$0.allItems(maxDepth: maxDepth)})
            }
            return items
        }
        
        func file(at url: URL) -> File? {
            let pathComponents = url.pathComponents
            if pathComponents.count-1 == level {
                return files.first(where: {$0.url == url })
            } else if pathComponents.count > level {
                return subfolders.lazy.compactMap({
                    if $0.url.pathComponents[safe: self.level] == pathComponents[self.level] {
                        return $0.file(at: url)
                    } else { return nil }
                }).first
            }
            return nil
        }
        
        func folder(at url: URL) -> Folder? {
            let pathComponents = url.pathComponents
            if pathComponents.count == level {
                return self.url == url ? self : nil
            } else if pathComponents.count - 1 > level {
                return subfolders.lazy.compactMap({
                    if $0.url.pathComponents[safe: self.level] == pathComponents[self.level] {
                        return $0.folder(at: url)
                    } else { return nil }
                }).first
            }
            return nil
        }
        
        func item(at url: URL) -> MetadataItem? {
            let pathComponents = url.pathComponents
            if pathComponents.count-1 == level {
                return files.first(where: {$0.url == url })?.item
            } else if pathComponents.count == level {
                return self.url == url ? item : nil
            } else if pathComponents.count > level {
                return subfolders.lazy.compactMap({
                    if $0.url.pathComponents[safe: self.level] == pathComponents[self.level] {
                        return $0.item(at: url)
                    } else { return nil }
                }).first
            }
            return nil
        }
        
        private lazy var _item: MetadataItem? = {
            setupValues()
            return _item
        }()
        
        private lazy var _files: [File] = {
            setupValues()
            return _files
        }()
        
        private lazy var _subfolders: [Folder] = {
            setupValues()
            return _subfolders
        }()
        
        func setupValues() {
            let dic = Dictionary(grouping: items, by: \.components[safe: level])
            var files: [File] = []
            var folders: [Folder] = []
            for val in dic {
                if val.key == nil, val.value.count == 1, let item = val.value.first, item.url.isDirectory {
                    self._item = item.item
                }
                guard let key = val.key else { continue }
                if val.value.count == 1, let item = val.value.first, item.url.isFile {
                    files += File(item.item, level: level+1)
                } else {
                    folders += Folder(val.value, url: url.appendingPathComponent(key), index: level+1, parent: self)
                }
            }
            _files = files
            _subfolders = folders
            items = []
        }
        
        init(files: [File], subfolders: [Folder]) {
            self.items = []
            self.level = .max
            self.url = URL(fileURLWithPath: "/")
            self._files = files
            self._subfolders = subfolders
            self._item = nil
        }
        
        init(_ items: [MappedItem]) {
            if items.isEmpty {
                self.items = []
                self.url = URL(fileURLWithPath: "/")
                self.level = .max
                self._files = []
                self._subfolders = []
                self._item = nil
            } else {
                let index = items.map({$0.components}).firstChangedIndex ?? 1
                self.level = index-1
                self.items = items
                self.url = items.first!.url.dropPathComponents(to: index-1)
            }
        }
        
        init(_ items: [MappedItem], url: URL, index: Int, parent: Folder? = nil) {
            self.items = items
            self.level = index
            self.url = url
            self.parent = parent
        }
        
        func strings(index: Int = 0) -> [String] {
            let tab = Array(repeating: "\t", count: index).joined(separator: "")
            var values = subfolders.compactMap({ (tab + ($0.url.lastPathComponent)) + $0.strings(index: index+1) }).flattened()
            values += files.compactMap({ tab + $0.description })
            return values
        }
        
        func indexedStrings(index: Int = 0) -> [(index: Int, string: String)] {
            var values = subfolders.compactMap({ (index, $0.url.lastPathComponent) + $0.indexedStrings(index: index+1) }).flattened()
            values += files.compactMap({ (index, $0.description) })
            return values
        }
        
        public var description: String {
            var values: [String] = []
            values += "Folder("
            values += strings(index: 1)
            values += ")"
            return values.joined(separator: "\n")
        }
        
        public static func == (lhs: MetadataQuery.HierarchicalResult.Folder, rhs: MetadataQuery.HierarchicalResult.Folder) -> Bool {
            lhs.hashValue == rhs.hashValue
        }
        
        public func hash(into hasher: inout Hasher) {
            hasher.combine(items.compactMap({$0.item}))
        }
    }
}

extension URL {
    func dropPathComponents(to amount: Int) -> URL {
        if pathComponents.count <= amount { return self }
        var url = self
        while url.pathComponents.count != amount {
            url = url.deletingLastPathComponent()
        }
        return url
    }
}

extension Array where Element: RandomAccessCollection, Element.Element: Comparable, Element.Index == Int {
    var firstChangedIndex: Int? {
        guard let maxCount = self.map(\.count).max(), !isEmpty else {
            return nil
        }
        for index in 0..<maxCount {
            var firstValue: Element.Element?
            for (i, collection) in enumerated() {
                guard index < collection.count else {
                    return index
                }
                let value = collection[index]
                if i == 0 {
                    firstValue = value
                } else if value != firstValue {
                    return index
                }
            }
        }
        return nil
    }
}


/// Unused
class HierarchicalItem {
    private var _items: [MappedItem] = []
    private var pending: [Dictionary<String?, [MappedItem]>.Element] = []
    private var _children: [HierarchicalItem] = []

    public enum ItemType: Hashable {
        /// Folder.
        case folder
        /// File.
        case file
    }
    
    /// The URL of the path.
    public let url: URL
    
    /// The type of the path.
    public let type: ItemType
    
    /// The metadata item of the path.
    public let item: MetadataItem?
    
    /// The name of the path.
    public var name: String { url.lastPathComponent }
    
    /// The file system level of the path.
    public let level: Int
    
    /// The number of metadata items for the path.
    public let itemsCount: Int
    
    /// A sequence of child paths for this path.
    public var children: ChildSequence {
        ChildSequence(self, 0)
    }
        
    /// A sequence of metadata items for this path.
    public var items: ItemSequence {
        ItemSequence(self, 0)
    }
    
    public var files: [HierarchicalItem] {
        children.filter({ $0.type == .file })
    }
    
    public var folders: [HierarchicalItem] {
        children.filter({ $0.type == .folder })
    }
    
    /// The parent folder of the path.
    public var parent: HierarchicalItem?
    
    public subscript(url: URL) -> HierarchicalItem? {
        path(for: url)
    }
    
    func path(for url: URL) -> HierarchicalItem? {
        if url == self.url { return self }
        let components = url.pathComponents
        let current = self.url.pathComponents
        if components.count > current.count, Array(components.prefix(current.count)) == current {
            for child in children {
                if let path = child.path(for: url) {
                    return path
                }
            }
        }
        return nil
    }
    
    private func buildNextChild() -> HierarchicalItem? {
        if !_items.isEmpty {
            pending = Dictionary(grouping: _items, by: \.components[safe: level]).map({$0})
            _items = []
        }
        guard let val = pending.removeFirstSafetly() else { return nil }
        guard let key = val.key else { return buildNextChild() }
        if val.value.count == 1, let item = val.value.first, item.url.isFile {
            let file = HierarchicalItem(item.item, url.appendingPathComponent(key), level+1, .file, self)
            _children += file
            return file
        } else {
            let folder = HierarchicalItem(val.value, url.appendingPathComponent(key), level+1, .folder, self)
            _children += folder
            return folder
        }
    }
    
    public init(_ items: [MetadataItem]) {
        self._items = items.compactMap({ MappedItem($0) })
        self.type = .folder
        if !items.isEmpty {
            self.level = (_items.map({$0.components}).firstChangedIndex ?? 1)-1
            self.url = _items.first!.url.dropPathComponents(to: level)
        } else {
            self.level = 0
            self.url = .file("/")
        }
        itemsCount = _items.count
        item = nil
    }
    
    private init(_ item: MetadataItem, _ url: URL, _ level: Int, _ type: ItemType = .folder, _ parent: HierarchicalItem? = nil) {
        self.item = item
        self.level = level
        self.type = type
        self.url = url
        self.parent = parent
        self.itemsCount = 1
    }
    
    private init(_ items: [MappedItem], _ url: URL, _ level: Int, _ type: ItemType = .folder, _ parent: HierarchicalItem? = nil) {
        self._items = items
        self.level = level
        self.type = type
        self.url = url
        self.parent = parent
        self.item = items.first(where: { $0.components[safe: level] == nil })?.item
        self.itemsCount = items.count
    }
    
    private struct MappedItem: Hashable {
        let item: MetadataItem
        let url: URL
        let components: [String]
        init?(_ item: MetadataItem) {
            guard let url = item.url else { return nil }
            self.item = item
            self.components = url.pathComponents
            self.url = url
        }
    }
}

extension HierarchicalItem {
    public struct ItemSequence: Sequence {
        private let item: HierarchicalItem
        private let maxDepth: Int?
        private let predicate: ((MetadataItem)->(Bool))
        
        public var recursive: Self {
            Self(item, nil, predicate)
        }
        
        public func recursive(maxDepth: Int) -> Self {
            Self(item, maxDepth, predicate)
        }
        
        func filter(_ predicate: @escaping ((MetadataItem)->(Bool))) -> Self {
            Self(item, maxDepth, predicate)
        }
        
        init(_ item: HierarchicalItem, _ maxDepth: Int?, _ predicate: @escaping ((MetadataItem)->(Bool)) = { _ in return true }) {
            self.item = item
            self.maxDepth = maxDepth
            self.predicate = predicate
        }
        
        public func makeIterator() -> Iterator {
            Iterator(item, maxDepth, predicate)
        }
        
        public class Iterator: IteratorProtocol {
            public var level = 0
            private let item: HierarchicalItem
            private let iterator: ChildSequence.Iterator
            private let predicate: ((MetadataItem)->(Bool))

            init(_ item: HierarchicalItem, _ maxDepth: Int?, _ predicate: @escaping ((MetadataItem)->(Bool))) {
                self.item = item
                self.iterator = item.children.maxDepth(maxDepth).makeIterator()
                self.predicate = predicate
            }
            
            public func skipDescendants() {
                iterator.skipDescendants()
            }
            
            public func next() -> MetadataItem? {
                while let child = iterator.next() {
                    if let item = child.item {
                        guard predicate(item) else { continue }
                        level = iterator.level
                        return item
                    }
                }
                return nil
            }
        }
    }
}

extension HierarchicalItem {
    public struct ChildSequence: Sequence {
        private let item: HierarchicalItem
        private let maxDepth: Int?
        private let predicate: ((HierarchicalItem)->(Bool))
        
        public var recursive: Self {
            Self(item, nil, predicate)
        }
        
        public func recursive(maxDepth: Int) -> Self {
            Self(item, maxDepth, predicate)
        }
        
        func maxDepth(_ maxDepth: Int?) -> Self {
            Self(item, maxDepth, predicate)
        }
        
        func filter(_ predicate: @escaping ((HierarchicalItem)->(Bool))) -> Self {
            Self(item, maxDepth, predicate)
        }
        
        init(_ item: HierarchicalItem, _ maxDepth: Int?, _ predicate: @escaping ((HierarchicalItem)->(Bool)) = { _ in return true }) {
            self.item = item
            self.maxDepth = maxDepth
            self.predicate = predicate
        }
        
        public func makeIterator() -> Iterator {
            Iterator(item, maxDepth, 0, predicate)
        }
        
        public class Iterator: IteratorProtocol {
            public var level = 0
            private let item: HierarchicalItem
            private let maxDepth: Int?
            private var index: Int = 0
            private var iterator: Iterator?
            private var _level = 0
            private var predicate: ((HierarchicalItem)->(Bool)) = { _ in return true }
            
            init(_ item: HierarchicalItem, _ maxDepth: Int?, _ level: Int = 0, _ predicate: @escaping ((HierarchicalItem)->(Bool)) = { _ in return true }) {
                self.item = item
                self.maxDepth = maxDepth
                self.level = level
                self._level = level
                self.predicate = predicate
            }
            
            public func skipDescendants() {
                iterator = nil
            }
            
            public func next() -> HierarchicalItem? {
                if let iterator = iterator, let child = iterator.next() {
                    guard predicate(child) else { return next() }
                    level = iterator.level
                    return child
                }
                iterator = nil
                guard let child = item._children[safe: index] ?? item.buildNextChild() else { return nil }
                guard predicate(child) else { return next() }
                level = _level
                index += 1
                if level < maxDepth ?? .max {
                    iterator = ChildSequence.Iterator(child, maxDepth, level + 1, predicate)
                }
                return child
            }
        }
    }
}
