//
//  Constants.swift
//  Dazar
//
//  Created by Alex Shacked on 19/11/2015.
//  Copyright © 2015 Dazar. All rights reserved.
//

import Foundation

enum Tag {
    case Restaurants, Cafes, Clothing, Shoes, Electronix, Beauty, Home, Grocery, Kids, Media, Sports
    func simpleDescription() -> String {
        switch self {
        case .Restaurants:
            return "restaurants"
        case .Cafes:
            return "cafes"
        case .Clothing:
            return "clothing"
        case .Shoes:
            return "shoes"
        case .Electronix:
            return "electronix"
        case .Beauty:
            return "beauty"
        case .Home:
            return "home"
        case .Grocery:
            return "grocery"
        case .Kids:
            return "kids"
        case .Media:
            return "media"
        case .Sports:
            return "sports"
        }
    }
}
