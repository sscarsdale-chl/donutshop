//
//  AdobeHtmlFile.swift
//  Donut Shop
//
//  Created by Shawn Scarsdale on 5/5/25.
//

import Foundation

struct AdobeHtmlFile: Hashable {
    let url: URL
    let fileName: String
    let width: Int
    let height: Int
    let compositionId: String
    var isConverted: Bool = false
    var images: [URL] = []
}
