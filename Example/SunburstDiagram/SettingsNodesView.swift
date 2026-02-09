//
//  SettingsNodesView.swift
//  SunburstDiagramDemo
//
//  Created by Ludovic Landry  on 6/18/19.
//  Copyright © 2019 Ludovic Landry. All rights reserved.
//

import SunburstDiagram
import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

struct SettingsNodesView: View {
    @Binding var nodes: [Node]
    let title: String
    let onNodesMutated: (() -> Void)?

    init(nodes: Binding<[Node]>, title: String,
         onNodesMutated: (() -> Void)? = nil) {
        self._nodes = nodes
        self.title = title
        self.onNodesMutated = onNodesMutated
    }

    var body: some View {
        container
            .navigationTitle(title)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        addNode()
                    } label: {
                        Label("Add Node", systemImage: "plus")
                    }
                }
            }
    }

    @ViewBuilder
    private var container: some View {
        #if os(tvOS)
        List { listContent }
        #else
        Form { listContent }
        #endif
    }

    @ViewBuilder
    private var listContent: some View {
        Section("Nodes") {
            if nodes.isEmpty {
                Text("No nodes yet.")
                    .foregroundColor(.secondary)
            } else {
                ForEach(nodes) { node in
                    NavigationLink(value: SettingsNavigationRoute.editNode(node.id)) {
                        nodeRow(node)
                    }
                }
                .onDelete(perform: deleteNodes)
            }
        }
    }

    private func addNode() {
        nodes.append(Node(name: nextNodeName(),
                          backgroundColor: NodeColorPalette.nextColorRef(forSiblingCount: nodes.count)))
        onNodesMutated?()
    }

    private func nextNodeName() -> String {
        let existingNames = Set(nodes.map(\.name))
        if !existingNames.contains("New Node") {
            return "New Node"
        }
        var index = 2
        while existingNames.contains("New Node \(index)") {
            index += 1
        }
        return "New Node \(index)"
    }

    private func deleteNodes(at offsets: IndexSet) {
        nodes.remove(atOffsets: offsets)
        onNodesMutated?()
    }

    private func nodeRow(_ node: Node) -> some View {
        HStack {
            nodeIcon(for: node)
                .frame(width: 20, height: 20)
                .foregroundColor(.secondary)
            VStack(alignment: .leading, spacing: 2) {
                Text(node.name)
                Text(node.value.map { "Value: \($0.formatted(.number.precision(.fractionLength(0...2))))" } ?? "No value")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text(node.children.isEmpty ? "Leaf" : "\(node.children.count) child")
                .foregroundColor(.secondary)
                .font(.subheadline)
        }
    }

    @ViewBuilder
    private func nodeIcon(for node: Node) -> some View {
        if case .systemSymbol(let symbolName)? = node.image {
            Image(systemName: symbolName)
                .resizable()
                .scaledToFit()
        } else if case .asset(_, _)? = node.image {
            node.image?.resolve()
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
        } else {
            Image(systemName: node.children.isEmpty ? "document.circle.fill" : "folder.circle.fill")
                .resizable()
                .scaledToFit()
        }
    }
}

struct NodeEditorView: View {
    @Binding var node: Node
    @Environment(\.colorScheme) private var colorScheme
    @State private var nodeValueText = ""
    let onMutate: (() -> Void)?

    init(node: Binding<Node>, onMutate: (() -> Void)? = nil) {
        self._node = node
        self.onMutate = onMutate
    }

    var body: some View {
        Form {
            Section("Name") {
                LabeledContent("Name") {
                    TextField("Untitled Node", text: nameBinding)
                        .multilineTextAlignment(.trailing)
                }
                Toggle("Show Name", isOn: showNameBinding)
            }

            Section("Icon & Color") {
                NavigationLink {
                    SFSymbolPickerView(selection: imageSystemSymbolNameBinding)
                } label: {
                    Text("Symbol")
                    Spacer()
                    if let symbolName = selectedSystemSymbolName {
                        Image(systemName: symbolName)
                            .foregroundColor(.secondary)
                        Text(symbolName)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    } else {
                        Text("Choose")
                            .foregroundColor(.secondary)
                    }
                }

                NavigationLink {
                    NodeColorPickerView(selection: backgroundColorBinding)
                } label: {
                    Text("Color")
                    Spacer()
                    if let selectedColorOption {
                        Circle()
                            .fill(selectedColorOption.color.resolve(in: colorScheme))
                            .frame(width: 14, height: 14)
                            .overlay(
                                Circle()
                                    .stroke(.secondary.opacity(0.25), lineWidth: 1)
                            )
                        Text(selectedColorOption.name)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    } else if node.backgroundColor != nil {
                        Circle()
                            .fill(node.backgroundColor?.resolve(in: colorScheme) ?? .clear)
                            .frame(width: 14, height: 14)
                            .overlay(
                                Circle()
                                    .stroke(.secondary.opacity(0.25), lineWidth: 1)
                            )
                        Text("Custom")
                            .foregroundColor(.secondary)
                    } else {
                        Text("No Color")
                            .foregroundColor(.secondary)
                    }
                }
            }

            Section("Value") {
                Toggle("Has Value", isOn: hasValueBinding)
                if node.value != nil {
                    #if os(iOS)
                    TextField("Value", text: nodeValueTextBinding)
                        .keyboardType(.decimalPad)
                    #else
                    TextField("Value", text: nodeValueTextBinding)
                    #endif
                }
            }

            Section("Children") {
                if node.children.isEmpty {
                    Text("No child nodes yet.")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(node.children) { childNode in
                        NavigationLink(value: SettingsNavigationRoute.editNode(childNode.id)) {
                            childNodeRow(childNode)
                        }
                    }
                    .onDelete(perform: deleteChildren)
                }

                Button {
                    updateNode { currentNode in
                        currentNode.children.append(
                            Node(
                                name: nextChildNodeName(),
                                backgroundColor: NodeColorPalette.nextColorRef(forSiblingCount: currentNode.children.count)
                            )
                        )
                    }
                } label: {
                    Label("Add Child Node", systemImage: "plus")
                }
            }
        }
        .navigationTitle(node.name)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .onAppear {
            syncNodeValueTextFromModel()
        }
        .onChange(of: node.value) { _ in
            syncNodeValueTextFromModel()
        }
    }

    private var nameBinding: Binding<String> {
        Binding(
            get: { node.name },
            set: { newName in
                let trimmedName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
                let resolvedName = trimmedName.isEmpty ? "Untitled Node" : trimmedName
                node = node.copy(name: resolvedName)
                onMutate?()
            }
        )
    }

    private var showNameBinding: Binding<Bool> {
        Binding(
            get: { node.showName },
            set: { shouldShowName in
                updateNode { $0.showName = shouldShowName }
            }
        )
    }

    private var hasValueBinding: Binding<Bool> {
        Binding(
            get: { node.value != nil },
            set: { shouldHaveValue in
                updateNode { currentNode in
                    currentNode.value = shouldHaveValue ? (currentNode.value ?? 0.0) : nil
                }
                if shouldHaveValue {
                    syncNodeValueTextFromModel()
                } else {
                    nodeValueText = ""
                }
            }
        )
    }

    private var nodeValueTextBinding: Binding<String> {
        Binding(
            get: { nodeValueText },
            set: { newValue in
                nodeValueText = newValue
                let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { return }
                guard let parsedValue = parseNodeValue(trimmed) else { return }
                updateNode { $0.value = parsedValue }
            }
        )
    }

    private var imageSystemSymbolNameBinding: Binding<String> {
        Binding(
            get: {
                guard case .systemSymbol(let name) = node.image else {
                    return ""
                }
                return name
            },
            set: { newValue in
                let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                updateNode { currentNode in
                    currentNode.image = trimmed.isEmpty ? nil : .systemSymbol(name: trimmed)
                }
            }
        )
    }

    private var selectedSystemSymbolName: String? {
        guard case .systemSymbol(let name) = node.image else {
            return nil
        }
        return name
    }

    private var backgroundColorBinding: Binding<ColorRef?> {
        Binding(
            get: { node.backgroundColor },
            set: { color in
                updateNode { $0.backgroundColor = color }
            }
        )
    }

    private var selectedColorOption: NodeColorOption? {
        NodeColorCatalog.option(for: node.backgroundColor)
    }

    private func nextChildNodeName() -> String {
        let existingNames = Set(node.children.map(\.name))
        if !existingNames.contains("New Child") {
            return "New Child"
        }
        var index = 2
        while existingNames.contains("New Child \(index)") {
            index += 1
        }
        return "New Child \(index)"
    }

    private func deleteChildren(at offsets: IndexSet) {
        updateNode { currentNode in
            currentNode.children.remove(atOffsets: offsets)
        }
    }

    private func childNodeRow(_ childNode: Node) -> some View {
        HStack {
            childNodeIcon(for: childNode)
                .frame(width: 20, height: 20)
                .foregroundColor(.secondary)
            VStack(alignment: .leading, spacing: 2) {
                Text(childNode.name)
                Text(childNode.value.map { "Value: \($0.formatted(.number.precision(.fractionLength(0...2))))" } ?? "No value")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text(childNode.children.isEmpty ? "Leaf" : "\(childNode.children.count) child")
                .foregroundColor(.secondary)
                .font(.subheadline)
        }
    }

    @ViewBuilder
    private func childNodeIcon(for childNode: Node) -> some View {
        if case .systemSymbol(let symbolName)? = childNode.image {
            Image(systemName: symbolName)
                .resizable()
                .scaledToFit()
        } else if case .asset(_, _)? = childNode.image {
            childNode.image?.resolve()
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
        } else {
            Image(systemName: childNode.children.isEmpty ? "document.circle.fill" : "folder.circle.fill")
                .resizable()
                .scaledToFit()
        }
    }

    private func updateNode(_ mutate: (inout Node) -> Void) {
        var updatedNode = node
        mutate(&updatedNode)
        node = updatedNode
        onMutate?()
    }

    private func syncNodeValueTextFromModel() {
        guard let value = node.value else {
            if !nodeValueText.isEmpty {
                nodeValueText = ""
            }
            return
        }

        if let parsedValue = parseNodeValue(nodeValueText), parsedValue == value {
            return
        }

        nodeValueText = value.formatted(.number.precision(.fractionLength(0...6)))
    }

    private func parseNodeValue(_ text: String) -> Double? {
        let normalized = text.replacingOccurrences(of: ",", with: ".")
        return Double(normalized)
    }
}

private struct NodeColorPickerView: View {
    @Binding var selection: ColorRef?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        List {
            Section("Pastel") {
                noColorRow
                ForEach(NodeColorCatalog.pastelOptions) { option in
                    colorRow(option)
                }
            }

            Section("System") {
                ForEach(NodeColorCatalog.systemOptions) { option in
                    colorRow(option)
                }
            }
        }
        .navigationTitle("Colors")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    private func colorRow(_ option: NodeColorOption) -> some View {
        Button {
            selection = option.color
            dismiss()
        } label: {
            HStack(spacing: 12) {
                Circle()
                    .fill(option.color.resolve(in: colorScheme))
                    .frame(width: 16, height: 16)
                    .overlay(
                        Circle()
                            .stroke(.secondary.opacity(0.25), lineWidth: 1)
                    )
                Text(option.name)
                    .foregroundColor(.primary)
                Spacer()
                if selection == option.color {
                    Image(systemName: "checkmark")
                        .foregroundColor(.accentColor)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var noColorRow: some View {
        Button {
            selection = nil
            dismiss()
        } label: {
            HStack(spacing: 12) {
                Circle()
                    .fill(.clear)
                    .frame(width: 16, height: 16)
                    .overlay(
                        Circle()
                            .stroke(.secondary.opacity(0.35), style: StrokeStyle(lineWidth: 1, dash: [2, 2]))
                    )
                Text("(No Color)")
                    .foregroundColor(.primary)
                Spacer()
                if selection == nil {
                    Image(systemName: "checkmark")
                        .foregroundColor(.accentColor)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

private struct NodeColorOption: Identifiable, Hashable {
    let id: String
    let name: String
    let color: ColorRef
}

private enum NodeColorCatalog {
    private static let pastelNames: [String] = [
        "Rose",
        "Peach",
        "Apricot",
        "Mint",
        "Seafoam",
        "Sky",
        "Periwinkle",
        "Lavender",
        "Lilac",
        "Sage",
    ]

    static let pastelOptions: [NodeColorOption] = Array(zip(pastelNames, ColorRef.nodePalette)).enumerated().map { index, item in
        let (name, color) = item
        return NodeColorOption(id: "pastel-\(index)", name: name, color: color)
    }

    static let systemOptions: [NodeColorOption] = SystemColor.nodePalette.map { systemColor in
        NodeColorOption(
            id: "system-\(systemColor.rawValue)",
            name: systemColor.displayName,
            color: .system(systemColor)
        )
    }

    private static let allOptions: [NodeColorOption] = pastelOptions + systemOptions

    static func option(for color: ColorRef?) -> NodeColorOption? {
        guard let color else { return nil }
        return allOptions.first { $0.color == color }
    }
}

private struct SFSymbolPickerView: View {
    @Binding var selection: String
    @State private var searchText = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            Section {
                noImageRow
                if let customSymbolCandidate {
                    symbolRow(symbolName: customSymbolCandidate, subtitle: "Use typed symbol name")
                }
                if filteredSymbols.isEmpty {
                    Text("No symbols match your search.")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(filteredSymbols, id: \.self) { symbolName in
                        symbolRow(symbolName: symbolName, subtitle: nil)
                    }
                }
            }
        }
        .navigationTitle("Symbols")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        #if !os(tvOS)
        .searchable(text: $searchText, prompt: "Search by symbol name")
        #endif
    }

    private var noImageRow: some View {
        Button {
            selection = ""
            dismiss()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "xmark.circle")
                    .frame(width: 24)
                    .foregroundColor(.secondary)
                Text("(No Image)")
                    .foregroundColor(.primary)
                Spacer()
                if selection.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Image(systemName: "checkmark")
                        .foregroundColor(.accentColor)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var filteredSymbols: [String] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return SFSymbolCatalog.names }
        return SFSymbolCatalog.names.filter { $0.localizedCaseInsensitiveContains(query) }
    }

    private var customSymbolCandidate: String? {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return nil }
        guard !SFSymbolCatalog.names.contains(where: { $0.caseInsensitiveCompare(query) == .orderedSame }) else {
            return nil
        }
        return isValidSFSymbolName(query) ? query : nil
    }

    private func symbolRow(symbolName: String, subtitle: String?) -> some View {
        Button {
            selection = symbolName
            dismiss()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: symbolName)
                    .frame(width: 24)
                    .foregroundColor(.accentColor)
                VStack(alignment: .leading, spacing: 2) {
                    Text(symbolName)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    if let subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                if selection == symbolName {
                    Image(systemName: "checkmark")
                        .foregroundColor(.accentColor)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

private enum SFSymbolCatalog {
    static let names: [String] = [
        "figure.walk",
        "figure.walk.circle",
        "figure.run",
        "figure.hiking",
        "figure.roll",
        "house",
        "house.fill",
        "building.2",
        "car",
        "car.fill",
        "bicycle",
        "tram",
        "airplane",
        "sailboat",
        "bus",
        "train.side.front.car",
        "fork.knife",
        "cup.and.saucer",
        "takeoutbag.and.cup.and.straw",
        "wineglass",
        "birthday.cake",
        "leaf",
        "leaf.fill",
        "tree",
        "flame",
        "drop",
        "sun.max",
        "moon",
        "cloud",
        "cloud.rain",
        "snowflake",
        "wind",
        "bolt",
        "heart",
        "heart.fill",
        "heart.circle",
        "star",
        "star.fill",
        "checkmark.circle",
        "checkmark.circle.fill",
        "xmark.circle",
        "questionmark.circle",
        "exclamationmark.triangle",
        "info.circle",
        "bell",
        "bell.fill",
        "calendar",
        "clock",
        "timer",
        "hourglass",
        "chart.bar",
        "chart.bar.fill",
        "chart.pie",
        "chart.pie.fill",
        "chart.line.uptrend.xyaxis",
        "list.bullet",
        "square.grid.2x2",
        "folder",
        "folder.fill",
        "doc",
        "doc.text",
        "book",
        "book.fill",
        "bookmark",
        "bookmark.fill",
        "paperplane",
        "paperclip",
        "link",
        "magnifyingglass",
        "plus",
        "minus",
        "pencil",
        "highlighter",
        "trash",
        "archivebox",
        "gear",
        "slider.horizontal.3",
        "wrench",
        "hammer",
        "paintbrush",
        "camera",
        "camera.fill",
        "photo",
        "photo.fill",
        "video",
        "play",
        "pause",
        "stop",
        "backward",
        "forward",
        "music.note",
        "headphones",
        "mic",
        "speaker.wave.2",
        "wifi",
        "antenna.radiowaves.left.and.right",
        "battery.100",
        "bolt.fill",
        "globe",
        "map",
        "mappin",
        "location",
        "location.fill",
        "flag",
        "flag.fill",
        "tag",
        "tag.fill",
        "cart",
        "bag",
        "gift",
        "bed.double",
        "sofa",
        "washer",
        "dishwasher",
        "tv",
        "desktopcomputer",
        "iphone",
        "applewatch",
        "person",
        "person.fill",
        "person.2",
        "person.2.fill",
        "person.3",
        "figure.2",
        "figure.2.and.child.holdinghands",
        "pawprint",
        "fish",
        "tortoise",
        "hare",
        "ladybug",
        "snowman",
        "theatermasks",
        "gamecontroller",
        "sportscourt",
        "dumbbell",
        "cross.case",
        "bandage",
        "stethoscope",
        "pills",
        "book.closed",
        "graduationcap",
        "briefcase",
        "banknote",
        "creditcard",
        "chart.xyaxis.line",
        "ellipsis.circle",
        "square.and.arrow.up",
        "square.and.arrow.down",
        "doc.on.doc",
        "shield",
        "lock",
        "lock.open",
        "key"
    ]
}

private func isValidSFSymbolName(_ name: String) -> Bool {
    #if canImport(UIKit)
    return UIImage(systemName: name) != nil
    #elseif canImport(AppKit)
    return NSImage(systemSymbolName: name, accessibilityDescription: nil) != nil
    #else
    return !name.isEmpty
    #endif
}

private extension Node {
    func copy(name: String) -> Node {
        Node(
            id: id,
            name: name,
            showName: showName,
            image: image,
            value: value,
            backgroundColor: backgroundColor,
            children: children
        )
    }
}

private enum NodeColorPalette {
    static func nextColorRef(forSiblingCount siblingCount: Int) -> ColorRef {
        let palette = ColorRef.nodePalette
        guard !palette.isEmpty else { return .system(.gray) }
        return palette[siblingCount % palette.count]
    }
}

private extension SystemColor {
    var displayName: String {
        rawValue
            .replacingOccurrences(of: "([a-z])([A-Z])",
                                  with: "$1 $2",
                                  options: .regularExpression)
            .capitalized
    }
}

#if DEBUG
struct SettingsNodesView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsNodesView(nodes: .constant([
            Node(name: "Walking",
                 showName: false,
                 image: .asset(name: "walking"),
                 value: 10.0,
                 backgroundColor: .system(.blue))
        ]), title: "Nodes")
    }
}
#endif
