//
//  Item.swift
//  Donut Shop
//
//  Created by Shawn Scarsdale on 5/5/25.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
