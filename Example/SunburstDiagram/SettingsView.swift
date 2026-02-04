//
//  SettingsView.swift
//  SunburstDiagramDemo
//
//  Created by Ludovic Landry  on 6/17/19.
//  Copyright © 2019 Ludovic Landry. All rights reserved.
//

import SunburstDiagram
import SwiftUI

struct SettingsView: View {

    @ObservedObject var configuration: SunburstConfiguration
    
    var body: some View {
        NavigationStack {
            container
            .navigationTitle("Configuration")
        }
    }

    @ViewBuilder
    private var container: some View {
        #if os(tvOS)
        List { formContent }
        #else
        Form { formContent }
        #endif
    }

    @ViewBuilder
    private var formContent: some View {
        Section("Content") {
            NavigationLink(destination: SettingsNodesView(nodes: configuration.nodes)) {
                Text("Nodes")
                Spacer()
                Text(configuration.nodes.isEmpty ? "No nodes" : "\(configuration.nodes.count) root nodes")
                    .foregroundColor(.secondary)
            }
            Picker(selection: $configuration.nodesSort, label: Text("Node Sorting")) {
                Text(".none").tag(NodesSort.none)
                Text(".asc").tag(NodesSort.asc)
                Text(".desc").tag(NodesSort.desc)
            }
            Picker(selection: $configuration.calculationMode, label: Text("Calculation Mode")) {
                Text(".ordinalFromLeaves").tag(CalculationMode.ordinalFromLeaves)
                Text(".ordinalFromRoot").tag(CalculationMode.ordinalFromRoot)
                Text(".parentDependent(totalValue:)").tag(CalculationMode.parentDependent(totalValue: nil))
                Text(".parentIndependent(totalValue:)").tag(CalculationMode.parentIndependent(totalValue: nil))
            }
        }
        Section("Dimensions") {
            sliderRow(title: "Margin Between Arcs",
                      value: $configuration.marginBetweenArcs,
                      range: CGFloat(0)...CGFloat(6),
                      step: 0.1,
                      fractionDigits: 1)
            sliderRow(title: "Inner Radius",
                      value: $configuration.innerRadius,
                      range: CGFloat(6)...CGFloat(200),
                      step: 1,
                      fractionDigits: 0)
            sliderRow(title: "Expanded Arc Thickness",
                      value: $configuration.expandedArcThickness,
                      range: CGFloat(30)...CGFloat(120),
                      step: 1,
                      fractionDigits: 0)
            sliderRow(title: "Collapsed Arc Thickness",
                      value: $configuration.collapsedArcThickness,
                      range: CGFloat(2)...CGFloat(12),
                      step: 1,
                      fractionDigits: 0)
        }
        Section("More") {
            sliderRow(title: "Starting Angle",
                      value: $configuration.startingAngle,
                      range: Double(-180)...Double(180),
                      step: 1,
                      fractionDigits: 0)
            Toggle("Limit Rings", isOn: configuration.maximumRingsShownCountToggleBinding)
            if configuration.maximumRingsShownCount != nil {
                sliderRow(title: "Maximum Rings",
                          value: self.configuration.maximumRingsShownCountSliderBinding,
                          range: 1...10,
                          step: 1,
                          fractionDigits: 0)
            }
            Toggle("Limit Expanded Rings", isOn: configuration.maximumExpandedRingsShownCountToggleBinding)
            if configuration.maximumExpandedRingsShownCount != nil {
                sliderRow(title: "Maximum Expanded Rings",
                          value: self.configuration.maximumExpandedRingsShownCountSliderBinding,
                          range: 0...8,
                          step: 1,
                          fractionDigits: 0)
            }
            Picker(selection: $configuration.minimumArcAngleShown, label: Text("Minimum Arc Angle")) {
                Text(".showAll").tag(ArcMinimumAngle.showAll)
                Text(".group(ifLessThan:)").tag(ArcMinimumAngle.group(ifLessThan: 1.0))
                Text(".hide(ifLessThan:)").tag(ArcMinimumAngle.hide(ifLessThan: 1.0))
            }.disabled(true)
        }
        Section("Interactions") {
            LabeledContent("Selected Node") {
                Text(configuration.selectedNode == nil ? "none" : configuration.selectedNode!.name)
                    .foregroundColor(Color.secondary)
            }
            LabeledContent("Focused Node") {
                Text(configuration.focusedNode == nil ? "none" : configuration.focusedNode!.name)
                    .foregroundColor(Color.secondary)
            }
        }
    }

    @ViewBuilder
    private func sliderRow(title: String,
                           value: Binding<Double>,
                           range: ClosedRange<Double>,
                           step: Double,
                           fractionDigits: Int) -> some View {
        #if os(tvOS)
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                Spacer()
                Text(value.wrappedValue, format: .number.precision(.fractionLength(fractionDigits)))
                    .foregroundColor(.secondary)
                    .monospacedDigit()
            }
            Text("Adjustable on iOS/macOS")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        #else
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                Spacer()
                Text(value.wrappedValue, format: .number.precision(.fractionLength(fractionDigits)))
                    .foregroundColor(.secondary)
                    .monospacedDigit()
            }
            Slider(value: value, in: range, step: step)
        }
        #endif
    }

    @ViewBuilder
    private func sliderRow(title: String,
                           value: Binding<CGFloat>,
                           range: ClosedRange<CGFloat>,
                           step: CGFloat,
                           fractionDigits: Int) -> some View {
        let doubleBinding = Binding<Double>(
            get: { Double(value.wrappedValue) },
            set: { value.wrappedValue = CGFloat($0) }
        )
        sliderRow(title: title,
                  value: doubleBinding,
                  range: Double(range.lowerBound)...Double(range.upperBound),
                  step: Double(step),
                  fractionDigits: fractionDigits)
    }
}

extension SunburstConfiguration {

    static let defaultMaximumExpandedRingsShownCount: UInt = 2
    static let defaultMaximumRingsShownCount: UInt = 4

    // MARK: maximumExpandedRingsShownCount bindings

    var maximumExpandedRingsShownCountSliderBinding: Binding<Double> {
        return Binding(get: { () -> Double in
            return Double(self.maximumExpandedRingsShownCount ?? SunburstConfiguration.defaultMaximumExpandedRingsShownCount)
        }, set: { (value) in
            self.maximumExpandedRingsShownCount = UInt(value)
        })
    }

    var maximumExpandedRingsShownCountToggleBinding: Binding<Bool> {
        return Binding(get: { () -> Bool in
            return self.maximumExpandedRingsShownCount != nil
        }, set: { (value) in
            self.maximumExpandedRingsShownCount = value ? SunburstConfiguration.defaultMaximumExpandedRingsShownCount : nil
        })
    }

    // MARK: maximumRingsShownCount bindings

    var maximumRingsShownCountSliderBinding: Binding<Double> {
        return Binding(get: { () -> Double in
            return Double(self.maximumRingsShownCount ?? SunburstConfiguration.defaultMaximumRingsShownCount)
        }, set: { (value) in
            self.maximumRingsShownCount = UInt(value)
        })
    }

    var maximumRingsShownCountToggleBinding: Binding<Bool> {
        return Binding(get: { () -> Bool in
            return self.maximumRingsShownCount != nil
        }, set: { (value) in
            self.maximumRingsShownCount = value ? SunburstConfiguration.defaultMaximumRingsShownCount : nil
        })
    }
}

#if DEBUG
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        let configuration = SunburstConfiguration(nodes: [
            Node(name: "Walking",
                 showName: false,
                 image: .asset(name: "walking"),
                 value: 10.0,
                 backgroundColor: .system(.blue)),
            Node(name: "Restaurant",
                 showName: false,
                 image: .asset(name: "eating"),
                 value: 30.0,
                 backgroundColor: .system(.red)),
            Node(name: "Home",
                 showName: false,
                 image: .asset(name: "house"),
                 value: 75.0,
                 backgroundColor: .system(.teal))
        ])
        return SettingsView(configuration: configuration)
    }
}
#endif
