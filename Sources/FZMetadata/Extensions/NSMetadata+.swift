//
//  File.swift
//  
//
//  Created by Florian Zand on 28.08.22.
//

import Foundation

internal extension NSMetadataItem {
    func value<T>(for attribute: String) -> T? {
        return self.value(forAttribute: attribute) as? T
    }
}

internal extension NSMetadataQuery {
    func values(of attributes: [String], forResultsAt index: Int) -> [String: Any] {
        var values = [String: Any]()
        attributes.forEach({ values[$0] = value(ofAttribute: $0, forResultAt: index) })
        return values
    }
}
