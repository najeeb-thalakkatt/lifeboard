//
//  LifeboardWidgetBundle.swift
//  LifeboardWidget
//
//  Created by Najeeb Thalakkatt on 2026-03-12.
//

import WidgetKit
import SwiftUI

@main
struct LifeboardWidgetBundle: WidgetBundle {
    var body: some Widget {
        ThisWeekWidget()
        HomePadWidget()
    }
}
