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
    /// A finder tag.
    enum FinderTagColor: String, CaseIterable, QueryRawRepresentable {
        /// A finder tag with no color.
        case none = "None"
        /// Gray finder tag.
        case gray = "Gray"
        /// Green finder tag.
        case green = "Green"
        /// Purple finder tag.
        case purple = "Purple"
        /// Blue finder tag.
        case blue = "Blue"
        /// Yellow finder tag.
        case yellow = "Yellow"
        /// Red finder tag.
        case red = "Red"
        /// Orange finder tag.
        case orange = "Orange"
        #if os(macOS)
            /// The color of the finder tag.
            public var color: NSColor {
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
            /// The color of the finder tag.
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
        #endif
    }
}

/*
 #if os(macOS)
 extension NSWorkspace {
     /// The available finder tags.
     var finderTagColors: [MetadataItem.FinderTagColor] {
         return fileLabels.compactMap({MetadataItem.FinderTagColor(rawValue: $0)})
     }
 }
 #endif
 */
