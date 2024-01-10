//
//  Operator.swift
//
//
//  Created by Florian Zand on 04.04.23.
//

infix operator ==*: ComparisonPrecedence
infix operator *==: ComparisonPrecedence
infix operator *=*: ComparisonPrecedence

infix operator ><: ComparisonPrecedence
infix operator ===: ComparisonPrecedence
infix operator !==: ComparisonPrecedence

prefix operator >>
prefix operator <<
