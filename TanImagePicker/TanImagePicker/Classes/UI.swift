//
//  UI.swift
//  TanImagePicker
//
//  Created by Tangent on 19/12/2017.
//  Copyright © 2017 Tangent. All rights reserved.
//

import UIKit

public extension TanImagePicker {
    public typealias Measure = () -> CGFloat
    enum UIItem {
        case contentViewbackgroundColor(UIColor)
        case imageMargin(Measure)
        case customViewControllerWidth(Measure)
        case checkViewBottomMargin(Measure)
        case checkViewRightMargin(Measure)
        case videoMarkViewBottomMargin(Measure)
        case videoMarkViewLeftMargin(Measure)
        case indicationViewImageMargin(Measure)
        case indicationViewBackgroundColor(UIColor)
        case cellProgressViewRadius(Measure)
        case cellProgressViewLineWidth(Measure)
        case automaticallyFetchVideoIfHas(Bool)
    }
}

extension TanImagePicker.UIItem: Hashable {
    public static func ==(lhs: TanImagePicker.UIItem, rhs: TanImagePicker.UIItem) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
    
    public var hashValue: Int {
        switch self {
        case .contentViewbackgroundColor: return 0
        case .imageMargin: return 1
        case .customViewControllerWidth: return 2
        case .checkViewBottomMargin: return 3
        case .checkViewRightMargin: return 4
        case .indicationViewImageMargin: return 5
        case .indicationViewBackgroundColor: return 6
        case .videoMarkViewBottomMargin: return 7
        case .videoMarkViewLeftMargin: return 8
        case .cellProgressViewRadius: return 9
        case .cellProgressViewLineWidth: return 10
        case .automaticallyFetchVideoIfHas: return 11
        }
    }
}

public extension TanImagePicker {
    struct UI {
        private(set) static var backgroundColor: UIColor = .white
        private(set) static var imageMargin: Measure = { 2 }
        private(set) static var customViewControllerWidth: Measure = { 0.55 * UIScreen.main.bounds.width }
        private(set) static var checkViewBottomMargin: Measure = { 7 }
        private(set) static var checkViewHorizontalMargin: Measure = { 6 }
        private(set) static var indicationViewImageMargin: Measure = { 9 }
        private(set) static var indicationViewBackgroundColor: UIColor = .white
        private(set) static var videoMarkViewBottomMargin: Measure = { 10 }
        private(set) static var videoMarkVideLeftMargin: Measure = { 8 }
        private(set) static var cellProgressViewRadius: Measure = { 18 }
        private(set) static var cellProgressViewLineWidth: Measure = { 4 }
        private(set) static var automaticallyFetchVideoIfHas: Bool = true
        
        private static func _update(_ item: UIItem) {
            switch item {
            case .contentViewbackgroundColor(let color):
                backgroundColor = color
            case .imageMargin(let margin):
                imageMargin = margin
            case .customViewControllerWidth(let width):
                customViewControllerWidth = width
            case .checkViewBottomMargin(let margin):
                checkViewBottomMargin = margin
            case .checkViewRightMargin(let margin):
                checkViewHorizontalMargin = margin
            case .indicationViewImageMargin(let margin):
                indicationViewImageMargin = margin
            case .indicationViewBackgroundColor(let color):
                indicationViewBackgroundColor = color
            case .videoMarkViewBottomMargin(let margin):
                videoMarkViewBottomMargin = margin
            case .videoMarkViewLeftMargin(let margin):
                videoMarkVideLeftMargin = margin
            case .cellProgressViewRadius(let radius):
                cellProgressViewRadius = radius
            case .cellProgressViewLineWidth(let width):
                cellProgressViewLineWidth = width
            case .automaticallyFetchVideoIfHas(let ok):
                automaticallyFetchVideoIfHas = ok
            }
        }
        
        static func update(_ items: Set<UIItem>) {
            items.forEach(_update)
        }
    }
}
