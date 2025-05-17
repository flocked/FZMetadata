//
//  NSMetadata+.swift
//
//
//  Created by Florian Zand on 28.08.22.
//

import Foundation
import FZSwiftUtils

extension NSMetadataQuery {
    /// Returns the values for the attribute names and result index.
    func values(of attributes: [String], forResultsAt index: Int) -> [String: Any] {
        attributes.reduce(into: [:]) { $0[$1] = value(ofAttribute: $1, forResultAt: index) }
    }
}
