//
//  IfLetView.swift
//  SunburstDiagram
//
//  Created by Ludovic Landry on 6/11/19.
//  Copyright © 2019 Ludovic Landry. All rights reserved.
//

import SwiftUI

struct IfLet<T, Out: View>: View {
    
    let value: T?
    let produce: (T) -> Out
    
    init(_ value: T?, produce: @escaping (T) -> Out) {
        self.value = value
        self.produce = produce
    }
    
    var body: some View {
        Group {
            if value != nil {
                produce(value!)
            }
        }
    }
}
