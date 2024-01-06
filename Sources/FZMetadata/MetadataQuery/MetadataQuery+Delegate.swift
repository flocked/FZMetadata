//
//  MetadataQuery+Delegate.swift
//
//
//  Created by Florian Zand on 06.01.24.
//

import Foundation

extension MetadataQuery {
    class DelegateProxy: NSObject, NSMetadataQueryDelegate {
        func metadataQuery(_ query: NSMetadataQuery, replacementObjectForResultObject result: NSMetadataItem) -> Any {
            return MetadataItem(item: result)
        }
    }
}
