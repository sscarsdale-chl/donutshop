//
//  FormatUtils.swift
//  Donut Shop
//
//  Created by Shawn Scarsdale on 5/5/25.
//

import Foundation

class FormatUtils {
    
    // Returns the width of the ad unit
    static func getWidth(_ content: String) -> Int {
        if let range = content.range(of: "width:") {
            let start = content.index(range.upperBound, offsetBy: 0)
            let end = content.index(start, offsetBy: 10)
            let widthStr = content[start..<end].components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
            return Int(widthStr) ?? 0
        }
        return 0
    }
    
    // Returns the height of the ad unit
    static func getHeight(_ content: String) -> Int {
        if let range = content.range(of: "height:") {
            let start = content.index(range.upperBound, offsetBy: 0)
            let end = content.index(start, offsetBy: 10)
            let heightStr = content[start..<end].components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
            return Int(heightStr) ?? 0
        }
        return 0
    }

    // Pulls the CompositionId out of the Adobe template
    static func getCompositionId(_ content: String) -> String {
        if let line = content.components(separatedBy: .newlines).first(where: { $0.contains("AdobeAn.getComposition") }) {
            return line
        }
        return ""
    }

}
