//
//  TagItem.swift
//  Dazar
//
//  Created by Alex Shacked on 19/11/2015.
//  Copyright © 2015 Dazar. All rights reserved.
//

import UIKit

class TagItem {
    var text: String
    var checked: Bool
    
    init(text: String, checked: Bool) {
        self.text = text
        self.checked = checked
    }
    
    func toggle() {
        checked = !checked
    }
}
