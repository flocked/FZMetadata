//
//  HierarchicalResults.swift
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
    public class HierarchicalResults: CustomStringConvertible, Hashable {
        var items: [MetadataItem]
        
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
            self.items = items
        }
        
        public var description: String {
            var values: [String] = []
            values.append("MappedQueryResults(")
            values.append(contentsOf: Folder(files: files, subfolders: folders).strings(index: 1))
            values.append(")")
            return values.joined(separator: "\n")
        }
        
        public static func == (lhs: MetadataQuery.HierarchicalResults, rhs: MetadataQuery.HierarchicalResults) -> Bool {
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
            self._topLevelURL = main.url ?? URL(fileURLWithPath: "/")
            items = []
        }
    }
}

extension MetadataQuery.HierarchicalResults {
    /// File of a hierarchical query results.
    public class File: CustomStringConvertible, Hashable {
        /// The url of the file.
        public let url: URL
        
        /// The metadata item of the file.
        public let item: MetadataItem
        
        /// The parent folder of the file.
        public var parent: Folder? = nil
        
        init(_ item: MetadataItem, parent: Folder? = nil) {
            self.url = item.url!
            self.item = item
            self.parent = parent
        }
        
        public var description: String {
            url.lastPathComponent
        }
        
        public static func == (lhs: MetadataQuery.HierarchicalResults.File, rhs: MetadataQuery.HierarchicalResults.File) -> Bool {
            lhs.hashValue == rhs.hashValue
        }
        
        public func hash(into hasher: inout Hasher) {
            hasher.combine(item)
        }
    }
}

extension MetadataQuery.HierarchicalResults {
    /// Folder of a hierarchical query results.
    public class Folder: Hashable, CustomStringConvertible {
        
        var items: [MetadataItem]
        let level: Int
        
        /// The url of the folder.
        public var url: URL {
            _url
        }
        
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
        
        private lazy var _url: URL = {
            setupValues()
            return _url
        }()
        
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
            let dic = Dictionary(grouping: items, by: \.url?.pathComponents[safe: level])
            var files: [File] = []
            var folders: [Folder] = []
            for val in dic {
                if val.key == nil, val.value.count == 1, let item = val.value.first, item.url!.isDirectory {
                    self._item = item
                }
                guard let key = val.key else { continue }
                if val.value.count == 1, let item = val.value.first, item.url?.isFile == true {
                    files.append(File(item))
                } else {
                    folders.append(Folder(val.value, url: _url.appendingPathComponent(key), index: level+1, parent: self))
                }
            }
            _files = files
            _subfolders = folders
            items = []
        }
        
        init(files: [File], subfolders: [Folder]) {
            self.items = []
            self.level = .max
            self._files = files
            self._subfolders = subfolders
            self._item = nil
            self._url = URL(fileURLWithPath: "/")
        }
                    
        init(_ items: [MetadataItem]) {
            if items.isEmpty {
                self.items = []
                self.level = .max
                self._files = []
                self._subfolders = []
                self._url = URL(fileURLWithPath: "/")
                self._item = nil
            } else {
                let index = items.compactMap({$0.url?.pathComponents}).firstChangedIndex ?? 1
                self.level = index-1
                self.items = items
                self._url = items.first!.url!.dropPathComponents(to: index-1)
            }
        }
        
        init(_ items: [MetadataItem], url: URL, index: Int, parent: Folder? = nil) {
            self.items = items
            self.level = index
            self._url = url
            self.parent = parent
            
        }
        
        func strings(index: Int = 0) -> [String] {
            let tab = Array(repeating: "\t", count: index).joined(separator: "")
            var values = subfolders.flatMap({ (tab + ($0.url.lastPathComponent ?? "_Folder")) + $0.strings(index: index+1) })
            values += files.compactMap({ tab + $0.description })
            return values
        }
        
        func indexedStrings(index: Int = 0) -> [(index: Int, string: String)] {
            var values = subfolders.flatMap({ (index, $0.url.lastPathComponent ?? "Folder") + $0.indexedStrings(index: index+1) })
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
        
        public static func == (lhs: MetadataQuery.HierarchicalResults.Folder, rhs: MetadataQuery.HierarchicalResults.Folder) -> Bool {
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
        guard !isEmpty else { return nil }
        let maxIndex = (compactMap({$0.count}).max() ?? 0)
        for index in 0..<maxIndex {
            let values = compactMap({$0[safe: index]})
            guard values.count == count else { return index }
            var compare = values.first
            for value in values {
                if compare != value {
                    return index
                }
                compare = value
            }
            }
        return nil
        }
        
      //  return (0..<maxIndex).first(where: { index in compactMap({$0[safe: index]}).count != count })
    }

