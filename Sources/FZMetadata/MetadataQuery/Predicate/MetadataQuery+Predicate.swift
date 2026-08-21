//
//  MetadataQuery+Predicate.swift
//
//
//  Created by Florian Zand on 21.04.23.
//

import Foundation
import FZSwiftUtils
import UniformTypeIdentifiers

public extension MetadataQuery {
    /**
     A predicate for filtering the results of a query.

     ### Operators
     Predicates can be defined by comparing ``MetadataItem`` properties to values using operators and functions.

     Depending on the property type there are different operators and functions available:

     ## General
     - ``isFile``
     - ``isFolder``
     - ``isAlias``
     - ``isVolume``
     - ``any``:  Matches for ``MetadataItem/Attribute/fileName`` and ``MetadataItem/Attribute/textContent``.

     ```swift
     // is a file
     { $0.isFile }

     // is not an alias file
     { $0.isAlias == false }

     // File name or text content is "ViewController"
     { $0.any == "ViewController" }
     ```

     ## Equatable
     - `==`
     - `!=`
     - `== [Value]`  // equales any
     - `!= [Value]` // equales none
     - `&&`
     - `||`
     - `!(_)`

     ```swift
     // fileName is "MyFile.doc" and creator isn't "Florian"
     query.predicate = { $0.fileName == "MyFile.doc" && $0.creater != "Florian"}

     // fileExtension is either "mp4", "mov" or "ts"
     query.predicate = { $0.fileExtension == ["mp4", "mov", "ts"] }

     // fileExtension isn't "mp3", "wav" and aiff
     query.predicate = { $0.fileExtension != ["mp3", "wav", "aiff"] }
     ```

     ## Comparable
     - `>`
     - `>=`
     - `<`
     - `<=`
     - `between(Range)` OR `== Range`

     ```swift
     // fileSize is greater than or equal to 1 gb
     { $0.fileSize.gigabytes >= 1 }

     // // fileSize is between 500 and 1000 mb
     { $0.fileSize.megabytes.between(500...1000) }
     { $0.fileSize.megabytes == 500...1000 }
     ```

     ## String
     
     - ``MetadataQuery/PredicateComponent/starts(with:)`` OR  `*== String`
     - ``MetadataQuery/PredicateComponent/ends(with:)`` OR  `==* String`
     - ``MetadataQuery/PredicateComponent/contains(_:)-2gaiw`` OR `*=* String`

     ```swift
     // fileName ends with ".doc"
     { $0.fileName.ends(with: ".doc") }
     { $0.fileName ==*  ".doc" }

     // fileName contains "MyFile"
     { $0.fileName.contains("MyFile") }
     { $0.fileName *=*  "MyFile" }
     ```

     By default string predicates are case- and diacritic-insensitive.

     Use ``MetadataQuery/PredicateComponent/casesensitive-njwr`` for case-sensitive, ``MetadataQuery/PredicateComponent/diacriticsensitive-94n3a``, for diacritic-sensitve and ``MetadataQuery/PredicateComponent/wordbased-6czl1`` for word-based string comparsion.

     ```swift
     // case-sensitive
     { $0.fileName.caseSensitive.begins(with: "MyF") }

     // case- and diacritic-sensitive
     { $0.fileName.caseSensitive.diacriticSensitive.begins(with: "MyF") }
     ```

     ## Date
    
     You can either compare a date to another date, or use the following:
     
     - ``MetadataQuery/PredicateComponent/isNow``
     - ``MetadataQuery/PredicateComponent/isThisMinute``
     - ``MetadataQuery/PredicateComponent/isLastMinute``
     - ``MetadataQuery/PredicateComponent/isThisHour``
     - ``MetadataQuery/PredicateComponent/isLastHour``
     - ``MetadataQuery/PredicateComponent/isSameHour(as:)``
     - ``MetadataQuery/PredicateComponent/isToday``
     - ``MetadataQuery/PredicateComponent/isYesterday``
     - ``MetadataQuery/PredicateComponent/isSameDay(as:)``
     - ``MetadataQuery/PredicateComponent/isThisWeek``
     - ``MetadataQuery/PredicateComponent/isLastWeek``
     - ``MetadataQuery/PredicateComponent/isSameWeek(as:)``
     - ``MetadataQuery/PredicateComponent/isThisMonth``
     - ``MetadataQuery/PredicateComponent/isLastMonth``
     - ``MetadataQuery/PredicateComponent/isSameMonth(as:)``
     - ``MetadataQuery/PredicateComponent/isThisYear``
     - ``MetadataQuery/PredicateComponent/isLastYear``
     - ``MetadataQuery/PredicateComponent/isSameYear(as:)``
     - ``MetadataQuery/PredicateComponent/isWithin(_:_:)``
     
     ```swift
     // is today
     { $0.creationDate.isToday }

     // is same week as otherDate
     { $0.creationDate.isSameWeek(as: otherDate) }

     // is within 4 weeks
     { $0.creationDate.isWithin(4, .week) }
     ```
     
     ## FileSize
    
     You can either compare the file size to another FileSize, or use the following for comparison:
     
     - ``MetadataQuery/PredicateComponent/bytes``
     - ``MetadataQuery/PredicateComponent/kilobytes``
     - ``MetadataQuery/PredicateComponent/megabytes``
     - ``MetadataQuery/PredicateComponent/gigabytes``
     - ``MetadataQuery/PredicateComponent/terabytes``
     - ``MetadataQuery/PredicateComponent/petabytes``
     
     ```swift
     // File size is larger than 100.0 megabytes
     { $0.fileSize.megabytes > 100.0 }

     // File size is larger or equal to someFileSize
     { $0.fileSize >= someFileSize }
     ```
     
     ## TimeDuration
    
     You can either compare the duration to another TimeDuration, or use the following for comparison:
     
     - ``MetadataQuery/PredicateComponent/seconds``
     - ``MetadataQuery/PredicateComponent/minutes``
     - ``MetadataQuery/PredicateComponent/hours``
     - ``MetadataQuery/PredicateComponent/days``
     - ``MetadataQuery/PredicateComponent/weeks``
     - ``MetadataQuery/PredicateComponent/months``
     - ``MetadataQuery/PredicateComponent/years``
     
     ```swift
     // duration is longer than 50.0 minutes
     { $0.duration.minutes > 50.0 }

     // duration is longer or equal to someTimeDuration
     { $0.duration >= someTimeDuration }
     ```

     ## Collection
     
     - ``MetadataQuery/PredicateComponent/contains(_:)-45d6d``  OR `== Element`
     - ``MetadataQuery/PredicateComponent/doesNotContain(_:)``  OR `!= Element`
     - ``MetadataQuery/PredicateComponent/contains(any:)``
     - ``MetadataQuery/PredicateComponent/doesNotContain(any:)``
     - ``MetadataQuery/PredicateComponent/isEmpty``


     ```swift
     // finderTags contains "red"
     { $0.finderTags.contains("red") }
     { $0.finderTags == "red" }

     // finderTags doesn't contain "red"
     { $0.finderTags.doesNotContain("blue") }
     { $0.finderTags != "red" }

     // finderTags contains "red", "yellow" or `green`.
     { $0.finderTags.contains(any: ["red", "yellow", "green"]) }

     // finderTags doesn't contain "red", "yellow" and `green`.
     { $0.finderTags.doesNotContain(any: ["red", "yellow", "green"]) }
     
     // finderTags is empty (or nil)
     { $0.finderTags.isEmpty }
     ```
     */
    @dynamicMemberLookup
    struct PredicateItem {
        
        /// Returns the metadata attribute for the specified `MetadataItem` keypath.
        public subscript(dynamicMember member: KeyPath<MetadataItem, Bool?>) -> PredicateResult {
            .comparison(member.mdItemKey, .equalTo, true)
        }

        /// Returns the metadata attribute for the specified `MetadataItem` keypath.
        public subscript<V>(dynamicMember member: KeyPath<MetadataItem, V>) -> PredicateComponent<V> {
            .init(member.mdItemKey)
        }
        
        /// Matches for ``MetadataItem/Attribute/fileName`` and ``MetadataItem/Attribute/textContent``.
        public var any: PredicateComponent<String?> {
            .init("*")
        }

        /// The item is a file.
        public var isFile: PredicateResult {
            .comparison("kMDItemContentTypeTree", .equalTo, "public.data")
        }

        /// The item is a folder.
        public var isFolder: PredicateResult {
            .comparison("kMDItemContentTypeTree", .equalTo, "public.folder")
        }

        /// The item is a volume.
        public var isVolume: PredicateResult {
            .comparison("kMDItemContentTypeTree", .equalTo, "public.volume")
        }

        /// The item is an alias file.
        public var isAlias: PredicateResult {
            .comparison("kMDItemContentTypeTree", .equalTo, "com.apple.alias-file")
        }
        
        static var root: PredicateItem {
            .init()
        }
    }
}

// MARK: Protocols

protocol QueryRawRepresentable {
    associatedtype RawValue
    var rawValue: RawValue { get }
}

extension FileType: QueryRawRepresentable {
    var rawValue: String { identifier }
}

extension UTType: QueryRawRepresentable {
    var rawValue: String { identifier }
}

extension URLUbiquitousItemDownloadingStatus: QueryRawRepresentable { }
extension URLUbiquitousSharedItemPermissions: QueryRawRepresentable { }
extension MetadataItem.MediaCodec: QueryRawRepresentable { }
extension MetadataItem.MeteringMode: QueryRawRepresentable { }

protocol QueryNumeric { }
extension Int: QueryNumeric { }
extension Double: QueryNumeric { }
extension Float: QueryNumeric { }
extension CGFloat: QueryNumeric { }
extension DataSize: QueryNumeric { }
extension TimeDuration: QueryNumeric { }

protocol QueryPredicate {
    var mdKeys: [String] { get }
    var stringOptions: MetadataQuery.PredicateStringOptions { get }
    var valueConverter: PredicateValueConverter? { get }
}

extension QueryPredicate {
    var stringOptions: MetadataQuery.PredicateStringOptions { return [] }
    var valueConverter: PredicateValueConverter? { return nil }
}

extension String: QueryPredicate {
    var mdKeys: [String] { [self] }
}

protocol PredicateValueConverter {
    func value(for value: Any) -> Any
}

extension DataSize {
    enum Unit: Int, PredicateValueConverter {
        case byte = 0
        case kilobyte
        case megabyte
        case gigabyte
        case terabyte
        case petabyte
        case exabyte
        case zettabyte
        case yottabyte
        
        func value(for value: Any) -> Any {
            guard let value = value as? Double else { return value }
            return UInt64(value * pow(1000, Double(rawValue)))
        }
    }
}

extension TimeDuration {
    enum Unit: Double, PredicateValueConverter {
        case second = 1
        case minute = 60
        case hour = 3_600
        case day = 86_400
        case week = 604_800
        case month = 2_629_746
        case year = 31_557_600
        
        func value(for value: Any) -> Any {
            guard let seconds = value as? Double else { return value }
           return seconds * rawValue
        }
    }
}

extension MetadataQuery.PredicateItem {
    func group(_ type: FileType) -> MetadataQuery.PredicateResult {
        let value = type.metadataQuery
        return .init(value.predicate, [value.mdKey])
    }
}

extension FileType {
    var metadataQuery: (predicate: NSPredicate, mdKey: String) {
        let mdKey: String
        let key: NSExpression
        let type: NSComparisonPredicate.Operator
        switch self {
        case .executable, .folder, .image, .video, .audio, .pdf, .presentation:
            key = .keyPath("_kMDItemGroupId")
            mdKey = "_kMDItemGroupId"
            type = .equalTo
        default:
            key = .keyPath("kMDItemContentTypeTree")
            mdKey = "kMDItemContentTypeTree"
            type = .like
        }
        let value: NSExpression
        switch self {
        case .executable: value = NSExpression(format: "%i", 8)
        case .folder: value = NSExpression(format: "%i", 9)
        case .audio: value = NSExpression(format: "%i", 10)
        case .pdf: value = NSExpression(format: "%i", 11)
        case .image: value = NSExpression(format: "%i", 13)
        case .video: value = NSExpression(format: "%i", 7)
        case .presentation: value = NSExpression(format: "%i", 12)
        default: value = NSExpression(format: "%@", identifier)
        }

        let modifier: NSComparisonPredicate.Modifier
        switch self {
        case .application, .archive, .text, .document:
            modifier = .any
        default:
            modifier = .direct
        }
        return (NSComparisonPredicate(left: key, right: value, modifier: modifier, type: type), mdKey)
    }
}
