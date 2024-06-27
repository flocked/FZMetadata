//
//  URL+MetadataQuery.swift
//
//
//  Created by Florian Zand on 27.06.24.
//

import Foundation
import FZSwiftUtils

extension URL {
    /**
     Returns the files to the specified completion handler.
     
     - Parameters:
     - name: The file names
     - types: The file types.
     - extension: The file extensions.
     - attributes: The optional metadata attributes to fetch.
     - completion: The completion handler that returns the found files.
     
     */
    func files(nameContains name: String? = nil, types: [FileType]? = nil, extensions: [String]? = nil, attributes: [MetadataItem.Attribute] = [], completion: @escaping ([MetadataItem])->()) {
        let query = MetadataQuery()
        let id = MetadataQueries.addQuery(query)
        query.predicate = { $0.isFile }
        query.attributes = attributes
        if let name = name {
            query.predicate = { query.predicate!($0) && $0.fileName.contains(name) }
        }
        if let types = types, !types.isEmpty {
            query.predicate = { query.predicate!($0) && $0.fileType == types }
        }
        if let extensions = extensions, !extensions.isEmpty {
            query.predicate = { query.predicate!($0) && $0.fileExtension == extensions }
        }
        query.resultsHandler = { items, _ in
            completion(items)
            query.stop()
            MetadataQueries.removeQuery(id)
        }
        query.start()
    }
}

class MetadataQueries {
    static func addQuery(_ query: MetadataQuery) -> UUID {
        let uuid = UUID()
        queries[uuid] = query
        return uuid
    }
    static func removeQuery(_ id: UUID) {
        queries[id] = nil
    }
    
    private static var queries: [UUID : MetadataQuery] = [:]
}
