//
//  MetadataQuery+Delegate.swift
//
//
//  Created by Florian Zand on 06.01.24.
//

import Foundation

extension MetadataQuery {
    class Delegate: NSObject, NSMetadataQueryDelegate {
        func metadataQuery(_: NSMetadataQuery, replacementObjectForResultObject result: NSMetadataItem) -> Any {
            MetadataItem(item: result)
        }
    }
}
