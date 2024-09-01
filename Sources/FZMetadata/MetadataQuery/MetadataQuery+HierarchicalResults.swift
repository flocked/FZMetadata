//
//  File.swift
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
        let items: [MetadataItem]
        
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
        
        /// Returns all folders including the subfolders of all folders.
        public var allItems: [MetadataItem] {
            files.compactMap({$0.item}) + folders.flatMap({$0.allItems}) + folders.compactMap({$0.item})
        }
              
        init(_ items: [MetadataItem]) {
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
        
        init(_ item: MetadataItem, _ url: URL, parent: Folder? = nil) {
            self.url = url
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
        
        let items: [(item: MetadataItem, url: URL)]
        let level: Int
        
        /// The url of the folder.
        public var url: URL {
            _url
        }
        
        /// The name of the folder.
        public var name: String {
            _name
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
        
        func file(at url: URL) -> File? {
            let pathComponents = url.pathComponents
            if pathComponents.count-1 == level {
                return files.first(where: {$0.url == url })
            } else if pathComponents.count > level {
                return subfolders.filter({ $0.url.pathComponents[safe: level] == pathComponents[level] }).compactMap({ $0.file(at: url ) }).first
            }
            return nil
        }
        
        func folder(at url: URL) -> Folder? {
            let pathComponents = url.pathComponents
            if pathComponents.count == level {
                return self.url == url ? self : nil
            } else if pathComponents.count > level {
                return subfolders.filter({ $0.url.pathComponents[safe: level] == pathComponents[level] }).compactMap({ $0.folder(at: url ) }).first
            }
            return nil
        }
        
        func item(at url: URL) -> MetadataItem? {
            let pathComponents = url.pathComponents
            if pathComponents.count-1 == level, let file = files.first(where: {$0.url == url }) {
                return file.item
            } else if pathComponents.count == level {
                return self.url == url ? self.item : nil
            } else if pathComponents.count > level {
                return subfolders.filter({ $0.url.pathComponents[safe: level] == pathComponents[level] }).compactMap({ $0.item(at: url ) }).first
            }
            return nil
        }
        
        private lazy var _url: URL = {
            setupValues()
            return url
        }()
        
        private var _name: String {
            url.lastPathComponent
        }
        
        private lazy var _item: MetadataItem? = {
            setupValues()
            return item
        }()
        
        private lazy var _files: [File] = {
            setupValues()
            return files
        }()
        
        private lazy var _subfolders: [Folder] = {
            setupValues()
            return subfolders
        }()
        
        func setupValues() {
            let dic = Dictionary(grouping: items, by: \.url.pathComponents[safe: level])
            var files: [File] = []
            var folders: [Folder] = []
            var url: URL?
            var item: MetadataItem?
            for val in dic {
                if val.key == nil, val.value.count == 1, let val = val.value.first, val.url.isDirectory {
                    url = val.url
                    item = val.item
                }
                guard val.key != nil else { continue }
                if val.value.count == 1, let val = val.value.first, val.url.isFile {
                    files.append(File(val.item, val.url))
                } else {
                    folders.append(Folder(val.value, index: level+1, parent: self))
                }
            }
            self._files = files
            self._subfolders = folders
            self._url = url ?? items.first!.url.parent ?? items.first!.url
            self._item = item
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
            let items: [(item: MetadataItem, url: URL)] = items.compactMap({ if let path = $0.path { return ($0, URL(fileURLWithPath: path)) } else { return nil } }).sorted(by: \.url.path)
            if items.isEmpty {
                self.items = []
                self.level = .max
                self._files = []
                self._subfolders = []
                self._url = URL(fileURLWithPath: "/")
                self._item = nil
            } else {
                let index = items.compactMap({$0.1.pathComponents}).firstChangedIndex ?? 1
                let main = Folder(items, index: index-1)
                self.level = index-1
                self.items = items
            }
        }
        
        init(_ items: [(item: MetadataItem, url: URL)], index: Int, parent: Folder? = nil) {
            self.items = items
            self.level = index
            self._url = items.first!.url.parent ?? URL(fileURLWithPath: "/")
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
            values.append("Folder(")
            values.append(contentsOf: strings(index: 1))
            values.append(")")
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

extension Array where Element: RandomAccessCollection, Element.Index == Int {
    var firstChangedIndex: Int? {
        guard !isEmpty else { return nil }
        let maxIndex = (compactMap({$0.count}).max() ?? 0)
        return (0..<maxIndex).first(where: { index in compactMap({$0[safe: index]}).count != count })
    }
}
