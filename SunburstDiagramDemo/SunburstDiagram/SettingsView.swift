//
//  SettingsView.swift
//  SunburstDiagramDemo
//
//  Created by Ludovic Landry  on 6/17/19.
//  Copyright © 2019 Ludovic Landry. All rights reserved.
//

import SwiftUI
import SunburstDiagram

struct SettingsView : View {
    
    @State var test: CGFloat = 1.0
    
    @State var configuration: SunburstConfiguration
    
    @State var parentTotalValue: Double? = nil
    @State var arcAngleShownIfLessThan: Double = 0.0
    
    @State var haveMaximumRingsShownCount: Bool = false
    @State var haveMaximumExpandedRingsShownCount: Bool = false
    
    var body: some View {
        Form {
            Section {

                VStack {
                    Text("Test: \(test)")
                    Slider(value: $test, from: CGFloat(0), through: CGFloat(6.0), by: CGFloat(1.0))
                }

//                ForEach(configuration.nodes) { node in // public var nodes: [Node] = []
//                    Text(node.name)
//                }
                Picker(selection: $configuration.nodesSort, label: Text("nodesSort")) {
                    Text(".none").tag(NodesSort.none)
                    Text(".asc").tag(NodesSort.asc)
                    Text(".desc").tag(NodesSort.desc)
                }
            }
            Section {
                Picker(selection: $configuration.calculationMode, label: Text("calculationMode")) {
                    Text(".ordinalFromLeaves").tag(CalculationMode.ordinalFromLeaves)
                    Text(".ordinalFromRoot").tag(CalculationMode.ordinalFromRoot)
                    Text(".parentDependent").tag(CalculationMode.parentDependent(totalValue: parentTotalValue))
                    Text(".parentIndependent").tag(CalculationMode.parentIndependent(totalValue: parentTotalValue))
                }
//                if case .parentDependent(let totalValue) = configuration.calculationMode {
//                    Stepper(value: $parentTotalValue, in: 0 ... 250) { Text(".parentDependent(totalValue:)") }
//                } else if case .parentInependent(let totalValue) = configuration.calculationMode {
//                    Stepper(value: $parentTotalValue, in: 0 ... 250) { Text(".parentIndependent(totalValue:)") }
//                }
            }
            Section {
                Stepper(value: $configuration.marginBetweenArcs, in: CGFloat(0) ... CGFloat(6)) {
                    Text("marginBetweenArcs: \(Int(configuration.marginBetweenArcs))")
                }
                Stepper(value: $configuration.collapsedArcThickness, in: CGFloat(4) ... CGFloat(20)) {
                    Text("collapsedArcThickness")
                }.disabled(true)
                Stepper(value: $configuration.expandedArcThickness, in: CGFloat(30) ... CGFloat(120)) {
                    Text("expandedArcThickness")
                }.disabled(true)
                Stepper(value: $configuration.innerRadius, in: CGFloat(0) ... CGFloat(200)) {
                    Text("innerRadius")
                }.disabled(true)
            }
            Section {
                Stepper(value: $configuration.startingAngle, in: 0.0 ... .pi) { Text("startingAngle") }
                Picker(selection: $configuration.minimumArcAngleShown, label: Text("minimumArcAngleShown")) {
                    Text(".showAll").tag(ArcMinimumAngle.showAll)
                    Text(".group(ifLessThan:)").tag(ArcMinimumAngle.group(ifLessThan: arcAngleShownIfLessThan))
                    Text(".hide(ifLessThan:)").tag(ArcMinimumAngle.hide(ifLessThan: arcAngleShownIfLessThan))
                }
//                if configuration.calculationMode == .group {
//                    Stepper(value: $parentTotalValue, in: 0.0 ... .pi) { Text(".group(ifLessThan:)") }
//                } else if configuration.calculationMode == .hide {
//                    Stepper(value: $parentTotalValue, in: 0.0 ... .pi) { Text(".hide(ifLessThan:)") }
//                }
            }.disabled(true)
            Section {
                Toggle(isOn: $haveMaximumRingsShownCount) {
                    Text("maximumRingsShownCount")
                }
//                if haveMaximumRingsShownCount {
//                    Stepper(value: $configuration.maximumRingsShownCount, in: 30 ... 120) {
//                        Text("maximumRingsShownCount")
//                    }
//                }
                Toggle(isOn: $haveMaximumExpandedRingsShownCount) {
                    Text("maximumExpandedRingsShownCount")
                }
//                if haveMaximumExpandedRingsShownCount {
//                    Stepper(value: $configuration.maximumExpandedRingsShownCount, in: 0 ... 200) {
//                        Text("maximumExpandedRingsShownCount")
//                    }
//                }
            }.disabled(true)
        }
    }
}

#if DEBUG
struct SettingsView_Previews : PreviewProvider {
    static var previews: some View {
        let configuration = SunburstConfiguration(nodes: [])
        return SettingsView(configuration: configuration)
    }
}
#endif
