//
//  NSUI Typealias.swift
//  
//
//  Created by Florian Zand on 14.09.23.
//

#if os(macOS)
import AppKit
public typealias NSUIColor = NSColor
#elseif canImport(UIKit)
import UIKit
public typealias NSUIColor = UIColor
#endif
