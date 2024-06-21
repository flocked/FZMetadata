//
//  MetadataItem+FinderTag.swift
//
//
//  Created by Florian Zand on 30.03.23.
//

import Foundation
#if os(macOS)
    import AppKit
#else
    import UIKit
#endif

extension MetadataItem {
    /// The primary Finder tag color.
    public enum FinderTagColor: Int, QueryRawRepresentable, CustomStringConvertible {
        /// A Finder tag with no color.
        case none = 0
        /// Gray Finder tag.
        case gray
        /// Green Finder tag.
        case green
        /// Purple Finder tag.
        case purple
        /// Blue Finder tag.
        case blue
        /// Yellow Finder tag.
        case yellow
        /// Red Finder tag.
        case red
        /// Orange Finder tag.
        case orange
        
        #if os(macOS)
            /// `NSColor` representation.
            public var nsColor: NSColor {
                switch self {
                case .none: return .clear
                case .gray: return .systemGray
                case .green: return .systemGreen
                case .purple: return .systemPurple
                case .blue: return .systemBlue
                case .yellow: return .systemYellow
                case .red: return .systemRed
                case .orange: return .systemOrange
                }
            }
        #elseif os(iOS) || os(tvOS)
            /// `UIColor` representation.
            public var color: UIColor {
                switch self {
                case .none: return .clear
                case .gray: return .systemGray
                case .green: return .systemGreen
                case .purple: return .systemPurple
                case .blue: return .systemBlue
                case .yellow: return .systemYellow
                case .red: return .systemRed
                case .orange: return .systemOrange
                }
            }
        #else
        /// `UIColor` representation.
        public var color: UIColor {
            switch self {
            case .none: return .clear
            case .gray: return .gray
            case .green: return .green
            case .purple: return .purple
            case .blue: return .blue
            case .yellow: return .yellow
            case .red: return .red
            case .orange: return .orange
            }
        }
        #endif
        
        public var description: String {
            switch self {
            case .none: return "None"
            case .gray: return "None"
            case .green: return "None"
            case .purple: return "None"
            case .blue: return "None"
            case .yellow: return "None"
            case .red: return "None"
            case .orange: return "None"
            }
        }
    }
}

/*
 #if os(macOS)
 extension NSWorkspace {
     /// The available Finder tags.
     var FinderTagColors: [MetadataItem.FinderTagColor] {
         return fileLabels.compactMap({MetadataItem.FinderTagColor(rawValue: $0)})
     }
 }
 #endif
 */
