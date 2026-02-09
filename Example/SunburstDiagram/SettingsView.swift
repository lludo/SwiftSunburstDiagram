//
//  SettingsView.swift
//  SunburstDiagramDemo
//
//  Created by Ludovic Landry  on 6/17/19.
//  Copyright © 2019 Ludovic Landry. All rights reserved.
//

import SunburstDiagram
import SwiftUI
#if os(iOS) || os(macOS)
import UniformTypeIdentifiers
#endif

struct SettingsView: View {
    @ObservedObject var configuration: SunburstConfiguration
    @ObservedObject var dataStore: DemoDataStore
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var selectedTab: SettingsTab = .data
    @State private var navigationPath: [SettingsNavigationRoute] = []

    var body: some View {
        #if os(tvOS)
        NavigationStack(path: $navigationPath) {
            List { formContent }
                .navigationDestination(for: SettingsNavigationRoute.self) { route in
                    destination(for: route)
                }
        }
        #else
        VStack(spacing: 0) {
            segmentedTabBar
                .padding(.vertical, 12)

            if selectedTab == .data {
                NavigationStack(path: $navigationPath) {
                    Form { dataTabContent }
                        .navigationDestination(for: SettingsNavigationRoute.self) { route in
                            destination(for: route)
                        }
                }
            } else {
                Form { selectedTabContent }
            }
        }
        .onChange(of: selectedTab) { _, newTab in
            guard newTab == .data else { return }
            syncNavigationToSelectedNode(configuration.selectedNode?.id)
        }
        .onChange(of: configuration.selectedNode?.id) { _, _ in
            syncNavigationToSelectedNode(configuration.selectedNode?.id)
        }
        .onChange(of: navigationPath) { _, newPath in
            syncSelectionToNavigationPath(newPath)
        }
        #endif
    }

    @ViewBuilder
    private var formContent: some View {
        Section {
            segmentedTabBar
        }

        selectedTabContent
    }

    @ViewBuilder
    private var selectedTabContent: some View {
        switch selectedTab {
        case .data:
            dataTabContent
        case .presentation:
            presentationTabContent
        case .layout:
            layoutTabContent
        case .interaction:
            interactionTabContent
        }
    }

    private var segmentedTabBar: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(SettingsTab.allCases) { tab in
                        Button {
                            selectedTab = tab
                            centerTab(tab, with: proxy, animated: true)
                            if tab == .data {
                                syncNavigationToSelectedNode(configuration.selectedNode?.id)
                            }
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: tab.systemImage)
                                    .font(.system(size: 18, weight: .semibold))
                                Text(tab.title(for: horizontalSizeClass))
                                    .font(.system(size: 17, weight: .semibold))
                                    .lineLimit(1)
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 20)
                            .foregroundColor(selectedTab == tab ? .white : .accentColor)
                            .background(
                                Capsule()
                                    .fill(selectedTab == tab ? Color.accentColor : Color.accentColor.opacity(0.18))
                            )
                        }
                        .buttonStyle(.plain)
                        .fixedSize(horizontal: true, vertical: false)
                        .id(tab)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 2)
            }
            .onAppear {
                centerTab(selectedTab, with: proxy, animated: false)
            }
            .onChange(of: selectedTab) { _, newTab in
                centerTab(newTab, with: proxy, animated: true)
            }
        }
    }

    private func centerTab(_ tab: SettingsTab, with proxy: ScrollViewProxy, animated: Bool) {
        let scroll = {
            proxy.scrollTo(tab, anchor: .center)
        }
        if animated {
            withAnimation(.easeInOut(duration: 0.2)) {
                scroll()
            }
        } else {
            scroll()
        }
    }

    @ViewBuilder
    private var dataTabContent: some View {
        Section("Data") {
            NavigationLink(value: SettingsNavigationRoute.dataFiles) {
                HStack(spacing: 10) {
                    Image(systemName: "folder")
                        .foregroundColor(.secondary)
                        .frame(width: 18)
                    Text("Data File")
                    Spacer()
                    Text(dataStore.selectedFileTitle)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            NavigationLink(value: SettingsNavigationRoute.editNodes) {
                HStack(spacing: 10) {
                    Image(systemName: "point.3.connected.trianglepath.dotted")
                        .foregroundColor(.secondary)
                        .frame(width: 18)
                    Text("Edit Nodes")
                    Spacer()
                    Text(configuration.nodes.isEmpty ? "No nodes" : "\(configuration.nodes.count) root nodes")
                        .foregroundColor(.secondary)
                }
            }

            NavigationLink(value: SettingsNavigationRoute.validation) {
                HStack(spacing: 10) {
                    Image(systemName: configuration.validationIssues.isEmpty ? "checkmark.shield" : "exclamationmark.shield")
                        .foregroundColor(.secondary)
                        .frame(width: 18)
                    Text("Validation")
                    Spacer()
                    if configuration.validationIssues.isEmpty {
                        Text("No issues")
                            .foregroundColor(.green)
                    } else {
                        Text("\(configuration.validationIssues.count) issue\(configuration.validationIssues.count == 1 ? "" : "s")")
                            .foregroundColor(.orange)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func destination(for route: SettingsNavigationRoute) -> some View {
        switch route {
        case .dataFiles:
            DataSettingsView(configuration: configuration, dataStore: dataStore)
        case .editNodes:
            SettingsNodesView(
                nodes: Binding(
                    get: { configuration.nodes },
                    set: { updatedNodes in
                        configuration.nodes = updatedNodes
                    }
                ),
                title: dataStore.selectedFileTitle,
                onNodesMutated: {
                    // Force a fresh value assignment so Sunburst rebuilds when nested node edits
                    // occur through deep bindings (image/symbol updates included).
                    configuration.nodes = configuration.nodes.map { $0 }
                }
            )
        case .editNode(let nodeID):
            if let nodeBinding = bindingForNode(withID: nodeID, in: $configuration.nodes) {
                NodeEditorView(node: nodeBinding, onMutate: {
                    configuration.nodes = configuration.nodes.map { $0 }
                })
            } else {
                Text("This node no longer exists.")
                    .foregroundColor(.secondary)
            }
        case .validation:
            ValidationIssuesView(configuration: configuration)
        }
    }

    private func syncNavigationToSelectedNode(_ selectedNodeID: UUID?) {
        guard selectedTab == .data else { return }
        guard let selectedNodeID else { return }
        guard let nodeIDPath = pathToNode(id: selectedNodeID, in: configuration.nodes) else { return }

        let targetPath: [SettingsNavigationRoute] = [.editNodes] + nodeIDPath.map { .editNode($0) }
        guard targetPath != navigationPath else { return }
        navigationPath = targetPath
    }

    private func syncSelectionToNavigationPath(_ path: [SettingsNavigationRoute]) {
        guard selectedTab == .data else { return }

        let selectedNodeID = selectedNodeID(in: path)
        if let selectedNodeID,
           let selectedNode = findNode(withID: selectedNodeID, in: configuration.nodes) {
            guard configuration.selectedNode?.id != selectedNode.id else { return }
            configuration.selectedNode = selectedNode
            return
        }

        guard path.isEmpty else { return }

        if configuration.selectedNode != nil {
            configuration.selectedNode = nil
        }
        if configuration.focusedNode != nil {
            configuration.focusedNode = nil
        }
    }

    private func selectedNodeID(in path: [SettingsNavigationRoute]) -> UUID? {
        for route in path.reversed() {
            if case .editNode(let nodeID) = route {
                return nodeID
            }
        }
        return nil
    }

    private func pathToNode(id targetID: UUID, in nodes: [Node]) -> [UUID]? {
        for node in nodes {
            if node.id == targetID {
                return [node.id]
            }
            if let childPath = pathToNode(id: targetID, in: node.children) {
                return [node.id] + childPath
            }
        }
        return nil
    }

    private func findNode(withID targetID: UUID, in nodes: [Node]) -> Node? {
        for node in nodes {
            if node.id == targetID {
                return node
            }
            if let child = findNode(withID: targetID, in: node.children) {
                return child
            }
        }
        return nil
    }

    private func bindingForNode(withID nodeID: UUID, in nodesBinding: Binding<[Node]>) -> Binding<Node>? {
        guard let indexPath = indexPathForNode(withID: nodeID, in: nodesBinding.wrappedValue) else {
            return nil
        }
        return bindingForNode(at: indexPath, in: nodesBinding)
    }

    private func indexPathForNode(withID nodeID: UUID, in nodes: [Node], basePath: [Int] = []) -> [Int]? {
        for index in nodes.indices {
            let currentPath = basePath + [index]
            let node = nodes[index]
            if node.id == nodeID {
                return currentPath
            }
            if let childPath = indexPathForNode(withID: nodeID, in: node.children, basePath: currentPath) {
                return childPath
            }
        }
        return nil
    }

    private func bindingForNode(at indexPath: [Int], in nodesBinding: Binding<[Node]>) -> Binding<Node>? {
        guard let index = indexPath.first, nodesBinding.wrappedValue.indices.contains(index) else {
            return nil
        }
        if indexPath.count == 1 {
            return Binding<Node>(
                get: { nodesBinding.wrappedValue[index] },
                set: { nodesBinding.wrappedValue[index] = $0 }
            )
        }
        let childBindings = Binding<[Node]>(
            get: { nodesBinding.wrappedValue[index].children },
            set: { nodesBinding.wrappedValue[index].children = $0 }
        )
        return bindingForNode(at: Array(indexPath.dropFirst()), in: childBindings)
    }

    @ViewBuilder
    private var presentationTabContent: some View {
        Section("Presentation") {
            Picker(selection: $configuration.nodesSort,
                   label: settingsRowLabel(title: "Node Sorting", systemImage: "arrow.up.arrow.down")) {
                Text(".none").tag(NodesSort.none)
                Text(".asc").tag(NodesSort.asc)
                Text(".desc").tag(NodesSort.desc)
            }
            Picker(selection: $configuration.calculationMode,
                   label: settingsRowLabel(title: "Calculation Mode", systemImage: "angle")) {
                Text(".ordinalFromLeaves").tag(CalculationMode.ordinalFromLeaves)
                Text(".ordinalFromRoot").tag(CalculationMode.ordinalFromRoot)
                Text(".parentDependent(totalValue:)").tag(CalculationMode.parentDependent(totalValue: nil))
                Text(".parentIndependent(totalValue:)").tag(CalculationMode.parentIndependent(totalValue: nil))
            }
        }
    }

    @ViewBuilder
    private var layoutTabContent: some View {
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
    }

    @ViewBuilder
    private var interactionTabContent: some View {
        Section("Interactions") {
            LabeledContent {
                Text(configuration.selectedNode?.name ?? "none")
                    .foregroundColor(.secondary)
            } label: {
                settingsRowLabel(title: "Selected Node", systemImage: "checkmark.circle")
            }
            LabeledContent {
                Text(configuration.focusedNode?.name ?? "none")
                    .foregroundColor(.secondary)
            } label: {
                settingsRowLabel(title: "Focused Node", systemImage: "scope")
            }
        }
    }

    private func settingsRowLabel(title: String, systemImage: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .foregroundColor(.secondary)
                .frame(width: 18)
            Text(title)
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

private enum SettingsTab: String, CaseIterable, Identifiable {
    case data
    case presentation
    case layout
    case interaction

    var id: String { rawValue }

    func title(for _: UserInterfaceSizeClass?) -> String {
        switch self {
        case .data:
            return "Data"
        case .presentation:
            return "Presentation"
        case .layout:
            return "Layout"
        case .interaction:
            return "Interaction"
        }
    }

    var systemImage: String {
        switch self {
        case .data:
            return "folder"
        case .presentation:
            return "arrow.up.arrow.down.circle"
        case .layout:
            return "square.3.layers.3d"
        case .interaction:
            return "hand.tap"
        }
    }
}

enum SettingsNavigationRoute: Hashable {
    case dataFiles
    case editNodes
    case editNode(UUID)
    case validation
}

struct DataSettingsView: View {
    @ObservedObject var configuration: SunburstConfiguration
    @ObservedObject var dataStore: DemoDataStore

    @State private var renameTarget: DemoDataFileDescriptor?
    @State private var renameText = ""
    #if os(iOS) || os(macOS)
    @State private var isImporterPresented = false
    #endif

    var body: some View {
        container
            .navigationTitle("Data Sources")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .alert("Rename Data File",
                   isPresented: Binding(
                    get: { renameTarget != nil },
                    set: { shouldPresent in
                        if !shouldPresent {
                            renameTarget = nil
                        }
                    })) {
                TextField("File Name", text: $renameText)
                Button("Cancel", role: .cancel) {
                    renameTarget = nil
                }
                Button("Save") {
                    if let target = renameTarget {
                        dataStore.renameFile(id: target.id, to: renameText)
                    }
                    renameTarget = nil
                }
            } message: {
                Text("Rename this custom data file.")
            }
            .alert("Data Error",
                   isPresented: Binding(
                    get: { dataStore.lastError != nil },
                    set: { shouldPresent in
                        if !shouldPresent {
                            dataStore.lastError = nil
                        }
                    })) {
                Button("OK", role: .cancel) {
                    dataStore.lastError = nil
                }
            } message: {
                Text(dataStore.lastError ?? "")
            }
            #if os(iOS) || os(macOS)
            .fileImporter(
                isPresented: $isImporterPresented,
                allowedContentTypes: [.sunburstDataFile, .json],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    guard let url = urls.first else { return }
                    dataStore.importFile(from: url)
                case .failure(let error):
                    dataStore.lastError = "Import failed. \(error.localizedDescription)"
                }
            }
            #endif
    }

    @ViewBuilder
    private var container: some View {
        #if os(tvOS)
        List { content }
        #else
        Form { content }
            #if os(iOS)
            .listSectionSpacing(.compact)
            #endif
        #endif
    }

    @ViewBuilder
    private var content: some View {
        Section("Files") {
            if dataStore.files.isEmpty {
                Text("No data files available.")
                    .foregroundColor(.secondary)
            } else {
                ForEach(dataStore.files) { file in
                    fileRow(file)
                }
            }
        }

        Section {
            Button {
                dataStore.createNewFile()
            } label: {
                Label("New File", systemImage: "plus")
            }

            #if os(iOS) || os(macOS)
            Button {
                isImporterPresented = true
            } label: {
                Label("Import Data File", systemImage: "square.and.arrow.down")
            }
            #endif
        }
    }

    private func fileRow(_ file: DemoDataFileDescriptor) -> some View {
        HStack(spacing: 12) {
            Image(systemName: fileRowIconName(for: file))
                .foregroundColor(.secondary)
                .frame(width: 18, height: 18)

            VStack(alignment: .leading, spacing: 2) {
                Text(file.title)
                Text(file.shortDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
                if file.isBundledSample {
                    Text("Bundled sample")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Spacer(minLength: 6)

            if dataStore.selectedFileID == file.id {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.accentColor)
            }

            Menu {
                if file.canRename {
                    Button {
                        renameTarget = file
                        renameText = file.title
                    } label: {
                        Label("Rename", systemImage: "pencil")
                    }
                }

                if file.canReset {
                    Button {
                        dataStore.resetBundledSample(id: file.id)
                    } label: {
                        Label("Reset to Default", systemImage: "arrow.counterclockwise")
                    }
                }

                if file.canDelete {
                    Button(role: .destructive) {
                        dataStore.deleteFile(id: file.id)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }

                #if os(iOS) || os(macOS)
                ShareLink(item: file.fileURL) {
                    Label("Export", systemImage: "square.and.arrow.up")
                }
                #endif
            } label: {
                Image(systemName: "ellipsis.circle")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            dataStore.selectFile(id: file.id)
        }
    }

    private func fileRowIconName(for file: DemoDataFileDescriptor) -> String {
        if file.isBundledSample {
            return "star.square.on.square.fill"
        }
        if file.shortDescription.localizedCaseInsensitiveContains("import") {
            return "square.and.arrow.down.fill"
        }
        return "doc.text.fill"
    }
}

private struct ValidationIssuesView: View {
    @ObservedObject var configuration: SunburstConfiguration

    private var validationMessages: [String] {
        ValidationIssueFormatter.messages(for: configuration.validationIssues, in: configuration.nodes)
    }

    var body: some View {
        container
            .navigationTitle("Validation")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
    }

    @ViewBuilder
    private var container: some View {
        #if os(tvOS)
        List { content }
        #else
        Form { content }
        #endif
    }

    @ViewBuilder
    private var content: some View {
        if validationMessages.isEmpty {
            Section {
                Label("No validation issues in this file.", systemImage: "checkmark.circle")
                    .foregroundColor(.green)
            }
        } else {
            Section {
                ForEach(validationMessages, id: \.self) { message in
                    Label(message, systemImage: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                }
            }
        }
    }
}

private enum ValidationIssueFormatter {
    static func messages(for issues: [ValidationIssue], in nodes: [Node]) -> [String] {
        issues.map { issue in
            switch issue {
            case .missingNodeValue(let mode, let nodeID):
                let nodeName = nodeDisplayName(for: nodeID, in: nodes)
                switch mode {
                case .parentDependent:
                    return "Node \"\(nodeName)\" is missing a value in parent-dependent mode."
                case .parentIndependent:
                    return "Leaf node \"\(nodeName)\" is missing a value in parent-independent mode."
                case .ordinalFromRoot, .ordinalFromLeaves:
                    return "Node \"\(nodeName)\" is missing a value."
                }
            case .parentValueLessThanChildren(let nodeID, let parentValue, let childrenSum):
                let nodeName = nodeDisplayName(for: nodeID, in: nodes)
                return "Node \"\(nodeName)\" has value \(number(parentValue)), but its children sum to \(number(childrenSum))."
            case .totalValueTooSmall(_, let provided, let requiredMinimum):
                return "Total value \(number(provided)) is below required minimum \(number(requiredMinimum)); display is clamped."
            }
        }
    }

    private static func nodeDisplayName(for nodeID: UUID, in nodes: [Node]) -> String {
        nodeName(for: nodeID, in: nodes) ?? "Unknown Node"
    }

    private static func nodeName(for nodeID: UUID, in nodes: [Node]) -> String? {
        for node in nodes {
            if node.id == nodeID {
                return node.name
            }
            if let nested = nodeName(for: nodeID, in: node.children) {
                return nested
            }
        }
        return nil
    }

    private static func number(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0...2)))
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

#if os(iOS) || os(macOS)
private extension UTType {
    static var sunburstDataFile: UTType {
        UTType(filenameExtension: "sunburst") ?? .json
    }
}
#endif

#if DEBUG
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        let configuration = SunburstConfiguration(nodes: SampleData.nodes())
        let dataStore = DemoDataStore(configuration: configuration, bootstrapFromDisk: false)
        return SettingsView(configuration: configuration, dataStore: dataStore)
    }
}
#endif
