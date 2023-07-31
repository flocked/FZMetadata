//
//  MetadataItem+FinderTag.swift
//  
//
//  Created by Florian Zand on 30.03.23.
//

import Foundation

public extension MetadataItem {
    struct FinderTag: Hashable {
        public enum Color: Int, CaseIterable, QueryRawRepresentable {
            case none
            case grey
            case green
            case purple
            case blue
            case yellow
            case red
            case orange
           public var name: String {
                switch self {
                case .none: return "none"
                case .grey: return "gray"
                case .green: return "green"
                case .purple: return "purple"
                case .blue: return "blue"
                case .yellow: return "yellow"
                case .red:  return "red"
                case .orange: return "orange"
                }
            }
           public var value: NSColor {
                switch self {
                case .none: return .clear
                case .grey: return .systemGray
                case .green: return .systemGreen
                case .purple: return .systemPurple
                case .blue: return .systemBlue
                case .yellow: return .systemYellow
                case .red: return .systemRed
                case .orange: return .systemOrange
                }
            }
        }
        public let name: String
        public let color: Color
    }
}

#if os(macOS)
import AppKit
public extension NSWorkspace {
    typealias FinderTag = MetadataItem.FinderTag
    var finderTags: [FinderTag] {
        return self.fileLabels.enumerated().compactMap({FinderTag($0.element, index: $0.offset)})
    }
}

internal extension MetadataItem.FinderTag {
    init?(_ name: String, index: Int) {
        guard let color = Color(rawValue: index) else { return nil }
        self.name = name
        self.color = color
    }
    
    init?(_ index: Int) {
        let finderTags = NSWorkspace.shared.finderTags
        guard index < finderTags.count else { return nil }
        self = finderTags[index]
    }
}
#endif
