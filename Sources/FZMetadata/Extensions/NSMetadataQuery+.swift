//
//  NSMetadata+.swift
//
//
//  Created by Florian Zand on 28.08.22.
//

import Foundation

extension NSMetadataQuery {
    /// Updates the values for the specified attribute names.
    func values(of attributes: [String], forResultsAt index: Int) -> [String: Any] {
        var values: [String: Any] = [:]
        attributes.forEach {
            values[$0] = value(ofAttribute: $0, forResultAt: index)
        }
        return values
    }
}
