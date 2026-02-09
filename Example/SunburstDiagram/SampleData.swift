//
//  SampleData.swift
//  SunburstDiagramDemo
//
//  Created by Ludovic Landry on 6/10/19.
//  Copyright © 2019 Ludovic Landry. All rights reserved.
//

import Combine
import Foundation
import SunburstDiagram

enum SampleData {
    static func nodes() -> [Node] {
        SampleActivitiesTemplate.defaultDocument(nodesOverride: nil).nodes.map(\.node)
    }
}

enum SampleActivitiesTemplate {
    static let bundledSampleID = "sample-activities"
    static let fileSuffix = ".sunburst"
    static let legacyFileSuffix = ".sunburst.json"
    static let supportedFileSuffixes = [fileSuffix, legacyFileSuffix]
    static let defaultFileName = "\(bundledSampleID)\(fileSuffix)"
    static let bundledSubdirectory = "SampleDataFiles"

    static func defaultDocument(nodesOverride: [NodeFilePayload]?) -> SunburstDataFile {
        var document = bundledDocument() ?? fallbackDocument()
        if let nodesOverride {
            document.nodes = nodesOverride
        }
        return document
    }

    static func bundledDocument() -> SunburstDataFile? {
        guard let bundledURL = bundledDocumentURL() else {
            return nil
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let data = try? Data(contentsOf: bundledURL),
              var dataFile = try? decoder.decode(SunburstDataFile.self, from: data) else {
            return nil
        }
        dataFile.schemaVersion = SunburstDataFile.currentSchemaVersion
        dataFile.app = .current
        dataFile.document.isBundledSample = true
        dataFile.document.bundledSampleID = bundledSampleID
        return dataFile
    }

    static func bundledDocumentURL() -> URL? {
        guard let urls = Bundle.main.urls(forResourcesWithExtension: nil, subdirectory: bundledSubdirectory) else {
            return nil
        }
        return urls.first(where: { $0.lastPathComponent == defaultFileName })
    }

    private static func fallbackDocument() -> SunburstDataFile {
        let now = Date()
        return SunburstDataFile(
            schemaVersion: SunburstDataFile.currentSchemaVersion,
            app: .current,
            document: .init(
                title: "Sample Activities",
                shortDescription: "Bundled sample missing from resources.",
                createdAt: now,
                updatedAt: now,
                isBundledSample: true,
                bundledSampleID: bundledSampleID
            ),
            configuration: .defaultDemoConfiguration,
            nodes: []
        )
    }
}

struct SunburstDataFile: Codable {
    static let currentSchemaVersion = 1

    var schemaVersion: Int
    var app: AppMetadata
    var document: DocumentMetadata
    var configuration: SunburstConfigurationFilePayload
    var nodes: [NodeFilePayload]

    struct AppMetadata: Codable {
        var appName: String
        var appVersion: String
        var bundleIdentifier: String

        static var current: AppMetadata {
            let bundle = Bundle.main
            return AppMetadata(
                appName: bundle.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "SunburstDiagramDemo",
                appVersion: bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0",
                bundleIdentifier: bundle.bundleIdentifier ?? "com.example.SunburstDiagramDemo"
            )
        }
    }

    struct DocumentMetadata: Codable {
        var title: String
        var shortDescription: String
        var createdAt: Date
        var updatedAt: Date
        var isBundledSample: Bool
        var bundledSampleID: String?
    }
}

struct SunburstConfigurationFilePayload: Codable {
    var calculationMode: CalculationModePayload
    var nodesSort: NodesSortPayload
    var marginBetweenArcs: Double
    var collapsedArcThickness: Double
    var expandedArcThickness: Double
    var innerRadius: Double
    var startingAngle: Double
    var minimumArcAngleShown: ArcMinimumAnglePayload
    var maximumRingsShownCount: UInt?
    var maximumExpandedRingsShownCount: UInt?
    var allowsSelection: Bool

    static let defaultDemoConfiguration = SunburstConfigurationFilePayload(
        calculationMode: .ordinalFromLeaves,
        nodesSort: .none,
        marginBetweenArcs: 1.0,
        collapsedArcThickness: 8.0,
        expandedArcThickness: 52.0,
        innerRadius: 60.0,
        startingAngle: 0.0,
        minimumArcAngleShown: .showAll,
        maximumRingsShownCount: 4,
        maximumExpandedRingsShownCount: 2,
        allowsSelection: true
    )
}

enum CalculationModePayload: Codable {
    case ordinalFromRoot
    case ordinalFromLeaves
    case parentDependent(totalValue: Double?)
    case parentIndependent(totalValue: Double?)

    private enum CodingKeys: String, CodingKey {
        case type
        case totalValue
    }

    private enum ModeType: String, Codable {
        case ordinalFromRoot
        case ordinalFromLeaves
        case parentDependent
        case parentIndependent
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let modeType = try container.decode(ModeType.self, forKey: .type)
        switch modeType {
        case .ordinalFromRoot:
            self = .ordinalFromRoot
        case .ordinalFromLeaves:
            self = .ordinalFromLeaves
        case .parentDependent:
            self = .parentDependent(totalValue: try container.decodeIfPresent(Double.self, forKey: .totalValue))
        case .parentIndependent:
            self = .parentIndependent(totalValue: try container.decodeIfPresent(Double.self, forKey: .totalValue))
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .ordinalFromRoot:
            try container.encode(ModeType.ordinalFromRoot, forKey: .type)
        case .ordinalFromLeaves:
            try container.encode(ModeType.ordinalFromLeaves, forKey: .type)
        case .parentDependent(let totalValue):
            try container.encode(ModeType.parentDependent, forKey: .type)
            try container.encodeIfPresent(totalValue, forKey: .totalValue)
        case .parentIndependent(let totalValue):
            try container.encode(ModeType.parentIndependent, forKey: .type)
            try container.encodeIfPresent(totalValue, forKey: .totalValue)
        }
    }
}

enum NodesSortPayload: String, Codable {
    case none
    case asc
    case desc
}

enum ArcMinimumAnglePayload: Codable {
    case showAll
    case group(ifLessThan: Double)
    case hide(ifLessThan: Double)

    private enum CodingKeys: String, CodingKey {
        case type
        case threshold
    }

    private enum PayloadType: String, Codable {
        case showAll
        case group
        case hide
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let payloadType = try container.decode(PayloadType.self, forKey: .type)
        switch payloadType {
        case .showAll:
            self = .showAll
        case .group:
            self = .group(ifLessThan: try container.decode(Double.self, forKey: .threshold))
        case .hide:
            self = .hide(ifLessThan: try container.decode(Double.self, forKey: .threshold))
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .showAll:
            try container.encode(PayloadType.showAll, forKey: .type)
        case .group(let threshold):
            try container.encode(PayloadType.group, forKey: .type)
            try container.encode(threshold, forKey: .threshold)
        case .hide(let threshold):
            try container.encode(PayloadType.hide, forKey: .type)
            try container.encode(threshold, forKey: .threshold)
        }
    }
}

struct NodeFilePayload: Codable, Identifiable, Sendable {
    var id: UUID
    var name: String
    var showName: Bool
    var image: ImageRef?
    var value: Double?
    var backgroundColor: ColorRef?
    var children: [NodeFilePayload]

    init(id: UUID = UUID(),
         name: String,
         showName: Bool = true,
         image: ImageRef? = nil,
         value: Double? = nil,
         backgroundColor: ColorRef? = nil,
         children: [NodeFilePayload] = []) {
        self.id = id
        self.name = name
        self.showName = showName
        self.image = image
        self.value = value
        self.backgroundColor = backgroundColor
        self.children = children
    }

    init(node: Node) {
        self.id = node.id
        self.name = node.name
        self.showName = node.showName
        self.image = node.image
        self.value = node.value
        self.backgroundColor = node.backgroundColor
        self.children = node.children.map(NodeFilePayload.init(node:))
    }

    var node: Node {
        Node(id: id,
             name: name,
             showName: showName,
             image: image,
             value: value,
             backgroundColor: backgroundColor,
             children: children.map(\.node))
    }
}

struct DemoDataFileDescriptor: Identifiable {
    var id: String { fileName }
    let fileName: String
    let fileURL: URL
    let document: SunburstDataFile.DocumentMetadata

    var title: String { document.title }
    var shortDescription: String { document.shortDescription }
    var isBundledSample: Bool { document.isBundledSample }
    var canDelete: Bool { !document.isBundledSample }
    var canRename: Bool { !document.isBundledSample }
    var canReset: Bool { document.isBundledSample }
}

@MainActor
final class DemoDataStore: ObservableObject {
    @Published private(set) var files: [DemoDataFileDescriptor] = []
    @Published private(set) var selectedFileID: String?
    @Published var lastError: String?

    let configuration: SunburstConfiguration

    private let fileManager: FileManager
    private let userDefaults: UserDefaults
    private let customDataDirectoryURL: URL?
    private var configurationCancellable: AnyCancellable?
    private var pendingSaveWorkItem: DispatchWorkItem?
    private var isApplyingLoadedDocument = false

    private static let selectedFileDefaultsKey = "sunburst.demo.selectedDataFile"

    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    init(configuration: SunburstConfiguration,
         fileManager: FileManager = .default,
         userDefaults: UserDefaults = .standard,
         bootstrapFromDisk: Bool = true,
         dataDirectoryURL: URL? = nil) {
        self.configuration = configuration
        self.fileManager = fileManager
        self.userDefaults = userDefaults
        self.customDataDirectoryURL = dataDirectoryURL

        bindConfiguration()
        if bootstrapFromDisk {
            bootstrapAndLoad()
        }
    }

    var selectedFileDescriptor: DemoDataFileDescriptor? {
        guard let selectedFileID else { return nil }
        return files.first(where: { $0.id == selectedFileID })
    }

    var selectedFileTitle: String {
        selectedFileDescriptor?.title ?? "No file selected"
    }

    func bootstrapAndLoad() {
        do {
            try fileManager.createDirectory(at: dataDirectoryURL, withIntermediateDirectories: true)
            try ensureBundledSamplesExist()
            try reloadFiles()
            selectInitialFile()
        } catch {
            handle(error: error, context: "Unable to initialize the data folder")
        }
    }

    func createNewFile(named proposedTitle: String? = nil) {
        do {
            persistSelectedFileNow()

            let title = normalizedTitle(proposedTitle) ?? nextUntitledTitle()
            let fileURL = uniqueFileURL(for: title)
            let now = Date()
            var newFileConfiguration = SunburstConfigurationFilePayload.defaultDemoConfiguration
            newFileConfiguration.calculationMode = .ordinalFromRoot
            let dataFile = SunburstDataFile(
                schemaVersion: SunburstDataFile.currentSchemaVersion,
                app: .current,
                document: .init(
                    title: title,
                    shortDescription: "Custom editable data file.",
                    createdAt: now,
                    updatedAt: now,
                    isBundledSample: false,
                    bundledSampleID: nil
                ),
                configuration: newFileConfiguration,
                nodes: []
            )
            try writeDataFile(dataFile, to: fileURL)
            try reloadFiles()
            selectFile(id: fileURL.lastPathComponent)
        } catch {
            handle(error: error, context: "Unable to create a new data file")
        }
    }

    func renameFile(id: String, to proposedTitle: String) {
        guard let descriptor = files.first(where: { $0.id == id }), descriptor.canRename else { return }
        let title = normalizedTitle(proposedTitle) ?? ""
        guard !title.isEmpty else { return }

        do {
            var dataFile = try readDataFile(at: descriptor.fileURL)
            dataFile.document.title = title
            dataFile.document.updatedAt = Date()
            dataFile.app = .current

            let destinationURL = uniqueFileURL(for: title, excludingFileName: descriptor.fileName)
            if destinationURL.lastPathComponent == descriptor.fileName {
                try writeDataFile(dataFile, to: descriptor.fileURL)
            } else {
                try writeDataFile(dataFile, to: descriptor.fileURL)
                try fileManager.moveItem(at: descriptor.fileURL, to: destinationURL)
            }

            try reloadFiles()
            if selectedFileID == descriptor.id {
                selectedFileID = destinationURL.lastPathComponent
                userDefaults.set(selectedFileID, forKey: Self.selectedFileDefaultsKey)
            }
        } catch {
            handle(error: error, context: "Unable to rename file")
        }
    }

    func deleteFile(id: String) {
        guard let descriptor = files.first(where: { $0.id == id }), descriptor.canDelete else { return }

        do {
            if selectedFileID == descriptor.id {
                persistSelectedFileNow()
            }
            try fileManager.removeItem(at: descriptor.fileURL)
            try reloadFiles()
            if selectedFileID == descriptor.id {
                selectInitialFile()
            }
        } catch {
            handle(error: error, context: "Unable to delete file")
        }
    }

    func resetBundledSample(id: String) {
        guard let descriptor = files.first(where: { $0.id == id }),
              descriptor.canReset else {
            return
        }

        do {
            let bundledSource: SunburstDataFile
            if let bundledResourceURL = bundledSampleResourceURL(forFileName: descriptor.fileName) {
                bundledSource = try readDataFile(at: bundledResourceURL)
            } else if descriptor.document.bundledSampleID == SampleActivitiesTemplate.bundledSampleID {
                bundledSource = SampleActivitiesTemplate.defaultDocument(nodesOverride: nil)
            } else {
                throw CocoaError(.fileNoSuchFile)
            }

            var resetDocument = normalizedBundledSampleDocument(
                bundledSource,
                bundledSampleID: descriptor.document.bundledSampleID ?? bundledSampleID(forFileName: descriptor.fileName),
                fallbackTitle: descriptor.title
            )
            if let existing = try? readDataFile(at: descriptor.fileURL) {
                resetDocument.document.createdAt = existing.document.createdAt
            }
            resetDocument.document.updatedAt = Date()
            try writeDataFile(resetDocument, to: descriptor.fileURL)
            try reloadFiles()
            if selectedFileID == id {
                try loadSelectedFileIntoConfiguration()
            }
        } catch {
            handle(error: error, context: "Unable to reset bundled sample")
        }
    }

    func selectFile(id: String) {
        guard selectedFileID != id else { return }
        persistSelectedFileNow()
        selectedFileID = id
        userDefaults.set(id, forKey: Self.selectedFileDefaultsKey)

        do {
            try loadSelectedFileIntoConfiguration()
        } catch {
            handle(error: error, context: "Unable to load selected file")
        }
    }

    func importFile(from externalURL: URL) {
        let startedSecurityScope = externalURL.startAccessingSecurityScopedResource()
        defer {
            if startedSecurityScope {
                externalURL.stopAccessingSecurityScopedResource()
            }
        }

        do {
            var imported = try readDataFile(at: externalURL)
            imported.schemaVersion = SunburstDataFile.currentSchemaVersion
            imported.app = .current

            let fallbackTitle = externalURL.deletingPathExtension().lastPathComponent
            let normalized = normalizedTitle(imported.document.title) ?? normalizedTitle(fallbackTitle) ?? "Imported File"
            imported.document.title = normalized
            imported.document.shortDescription = imported.document.shortDescription.isEmpty ? "Imported from external data file." : imported.document.shortDescription
            imported.document.isBundledSample = false
            imported.document.bundledSampleID = nil
            imported.document.updatedAt = Date()
            if imported.document.createdAt.timeIntervalSince1970 <= 0 {
                imported.document.createdAt = Date()
            }

            let destinationURL = uniqueFileURL(for: normalized)
            try writeDataFile(imported, to: destinationURL)
            try reloadFiles()
            selectFile(id: destinationURL.lastPathComponent)
        } catch {
            handle(error: error, context: "Unable to import file")
        }
    }

    func persistSelectedFileNow() {
        guard !isApplyingLoadedDocument,
              let descriptor = selectedFileDescriptor else {
            return
        }

        do {
            var existing = try readDataFile(at: descriptor.fileURL)
            existing.schemaVersion = SunburstDataFile.currentSchemaVersion
            existing.app = .current
            existing.document.updatedAt = Date()
            existing.configuration = configuration.filePayload
            existing.nodes = configuration.nodes.map(NodeFilePayload.init(node:))
            try writeDataFile(existing, to: descriptor.fileURL)
        } catch {
            handle(error: error, context: "Unable to save changes")
        }
    }

    private func bindConfiguration() {
        configurationCancellable = configuration.objectWillChange.sink { [weak self] _ in
            self?.scheduleAutosave()
        }
    }

    private func scheduleAutosave() {
        guard !isApplyingLoadedDocument else { return }
        pendingSaveWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            self?.persistSelectedFileNow()
        }
        pendingSaveWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: workItem)
    }

    private func ensureBundledSamplesExist() throws {
        let bundledResourceURLs = bundledSampleResourceURLs()
        if bundledResourceURLs.isEmpty {
            let fileURL = dataDirectoryURL.appendingPathComponent(SampleActivitiesTemplate.defaultFileName)
            guard !fileManager.fileExists(atPath: fileURL.path),
                  !bundledSampleExists(withID: SampleActivitiesTemplate.bundledSampleID) else { return }
            let fallbackDataFile = SampleActivitiesTemplate.defaultDocument(nodesOverride: nil)
            try writeDataFile(fallbackDataFile, to: fileURL)
            return
        }

        for resourceURL in bundledResourceURLs {
            let fileName = resourceURL.lastPathComponent
            let sampleID = bundledSampleID(forFileName: fileName)
            guard !bundledSampleExists(withID: sampleID) else { continue }
            let destinationURL = dataDirectoryURL.appendingPathComponent(fileName)
            guard !fileManager.fileExists(atPath: destinationURL.path) else { continue }
            let dataFile = try readDataFile(at: resourceURL)
            let normalizedDataFile = normalizedBundledSampleDocument(
                dataFile,
                bundledSampleID: sampleID,
                fallbackTitle: fileName.sampleTitleFromFileName
            )
            try writeDataFile(normalizedDataFile, to: destinationURL)
        }
    }

    private func bundledSampleResourceURLs() -> [URL] {
        guard let urls = Bundle.main.urls(forResourcesWithExtension: nil,
                                          subdirectory: SampleActivitiesTemplate.bundledSubdirectory) else {
            return []
        }
        return urls
            .filter { hasSupportedFileSuffix($0.lastPathComponent) }
            .sorted { $0.lastPathComponent.localizedCaseInsensitiveCompare($1.lastPathComponent) == .orderedAscending }
    }

    private func bundledSampleResourceURL(forFileName fileName: String) -> URL? {
        bundledSampleResourceURLs().first(where: { $0.lastPathComponent == fileName })
    }

    private func hasSupportedFileSuffix(_ fileName: String) -> Bool {
        SampleActivitiesTemplate.supportedFileSuffixes.contains { fileName.hasSuffix($0) }
    }

    private func bundledSampleExists(withID bundledSampleID: String) -> Bool {
        guard let urls = try? fileManager.contentsOfDirectory(
            at: dataDirectoryURL,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) else {
            return false
        }

        for url in urls where hasSupportedFileSuffix(url.lastPathComponent) {
            guard let dataFile = try? readDataFile(at: url) else { continue }
            if dataFile.document.isBundledSample,
               dataFile.document.bundledSampleID == bundledSampleID {
                return true
            }
        }
        return false
    }

    private func bundledSampleID(forFileName fileName: String) -> String {
        let normalizedBaseName: String
        if fileName.hasSuffix(SampleActivitiesTemplate.fileSuffix) {
            normalizedBaseName = String(fileName.dropLast(SampleActivitiesTemplate.fileSuffix.count))
        } else if fileName.hasSuffix(SampleActivitiesTemplate.legacyFileSuffix) {
            normalizedBaseName = String(fileName.dropLast(SampleActivitiesTemplate.legacyFileSuffix.count))
        } else {
            normalizedBaseName = (fileName as NSString).deletingPathExtension
        }
        return normalizedBaseName.isEmpty ? fileName.fileNameSafe : normalizedBaseName
    }

    private func normalizedBundledSampleDocument(_ dataFile: SunburstDataFile,
                                                 bundledSampleID: String,
                                                 fallbackTitle: String) -> SunburstDataFile {
        var normalized = dataFile
        normalized.schemaVersion = SunburstDataFile.currentSchemaVersion
        normalized.app = .current
        normalized.document.title = normalizedTitle(normalized.document.title) ?? fallbackTitle
        normalized.document.shortDescription = normalizedTitle(normalized.document.shortDescription) ?? "Bundled sample data file."
        normalized.document.isBundledSample = true
        normalized.document.bundledSampleID = bundledSampleID

        let now = Date()
        if normalized.document.createdAt.timeIntervalSince1970 <= 0 {
            normalized.document.createdAt = now
        }
        if normalized.document.updatedAt.timeIntervalSince1970 <= 0 {
            normalized.document.updatedAt = normalized.document.createdAt
        }
        return normalized
    }

    private func reloadFiles() throws {
        let urls = try fileManager.contentsOfDirectory(
            at: dataDirectoryURL,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )
        .filter { hasSupportedFileSuffix($0.lastPathComponent) }

        let descriptors = try urls.map { url -> DemoDataFileDescriptor in
            let dataFile = try readDataFile(at: url)
            return DemoDataFileDescriptor(
                fileName: url.lastPathComponent,
                fileURL: url,
                document: dataFile.document
            )
        }
        .sorted { lhs, rhs in
            if lhs.isBundledSample != rhs.isBundledSample {
                return lhs.isBundledSample && !rhs.isBundledSample
            }
            return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
        }

        files = descriptors
    }

    private func selectInitialFile() {
        if let storedID = userDefaults.string(forKey: Self.selectedFileDefaultsKey),
           files.contains(where: { $0.id == storedID }) {
            selectedFileID = storedID
        } else if let bundled = files.first(where: { $0.document.bundledSampleID == SampleActivitiesTemplate.bundledSampleID }) {
            selectedFileID = bundled.id
        } else if let bundled = files.first(where: { $0.isBundledSample }) {
            selectedFileID = bundled.id
        } else {
            selectedFileID = files.first?.id
        }

        userDefaults.set(selectedFileID, forKey: Self.selectedFileDefaultsKey)
        do {
            try loadSelectedFileIntoConfiguration()
        } catch {
            handle(error: error, context: "Unable to load initial file")
        }
    }

    private func loadSelectedFileIntoConfiguration() throws {
        guard let descriptor = selectedFileDescriptor else { return }
        let dataFile = try readDataFile(at: descriptor.fileURL)
        isApplyingLoadedDocument = true
        configuration.apply(filePayload: dataFile.configuration)
        configuration.nodes = dataFile.nodes.map(\.node)
        isApplyingLoadedDocument = false
    }

    private func readDataFile(at url: URL) throws -> SunburstDataFile {
        let data = try Data(contentsOf: url)
        return try decoder.decode(SunburstDataFile.self, from: data)
    }

    private func writeDataFile(_ dataFile: SunburstDataFile, to url: URL) throws {
        let data = try encoder.encode(dataFile)
        try data.write(to: url, options: .atomic)
    }

    private func uniqueFileURL(for title: String, excludingFileName excludedFileName: String? = nil) -> URL {
        let normalizedBase = title.fileNameSafe
        var candidateIndex = 1
        var candidateName = "\(normalizedBase)\(SampleActivitiesTemplate.fileSuffix)"
        while fileManager.fileExists(atPath: dataDirectoryURL.appendingPathComponent(candidateName).path) {
            if candidateName == excludedFileName {
                break
            }
            candidateIndex += 1
            candidateName = "\(normalizedBase)-\(candidateIndex)\(SampleActivitiesTemplate.fileSuffix)"
        }
        return dataDirectoryURL.appendingPathComponent(candidateName)
    }

    private func nextUntitledTitle() -> String {
        let existingTitles = Set(files.map(\.title))
        if !existingTitles.contains("Untitled") {
            return "Untitled"
        }

        var index = 2
        while existingTitles.contains("Untitled \(index)") {
            index += 1
        }
        return "Untitled \(index)"
    }

    private func normalizedTitle(_ proposedTitle: String?) -> String? {
        guard let proposedTitle else { return nil }
        let trimmed = proposedTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private var dataDirectoryURL: URL {
        if let customDataDirectoryURL {
            return customDataDirectoryURL
        }
        let baseDirectory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        return baseDirectory
            .appendingPathComponent("SunburstDiagramDemo", isDirectory: true)
            .appendingPathComponent("DataFiles", isDirectory: true)
    }

    private func handle(error: Error, context: String) {
        lastError = "\(context). \(error.localizedDescription)"
    }
}

extension SunburstConfiguration {
    fileprivate var filePayload: SunburstConfigurationFilePayload {
        SunburstConfigurationFilePayload(
            calculationMode: CalculationModePayload(calculationMode),
            nodesSort: NodesSortPayload(nodesSort),
            marginBetweenArcs: Double(marginBetweenArcs),
            collapsedArcThickness: Double(collapsedArcThickness),
            expandedArcThickness: Double(expandedArcThickness),
            innerRadius: Double(innerRadius),
            startingAngle: startingAngle,
            minimumArcAngleShown: ArcMinimumAnglePayload(minimumArcAngleShown),
            maximumRingsShownCount: maximumRingsShownCount,
            maximumExpandedRingsShownCount: maximumExpandedRingsShownCount,
            allowsSelection: allowsSelection
        )
    }

    fileprivate func apply(filePayload: SunburstConfigurationFilePayload) {
        calculationMode = filePayload.calculationMode.calculationMode
        nodesSort = filePayload.nodesSort.nodesSort
        marginBetweenArcs = CGFloat(filePayload.marginBetweenArcs)
        collapsedArcThickness = CGFloat(filePayload.collapsedArcThickness)
        expandedArcThickness = CGFloat(filePayload.expandedArcThickness)
        innerRadius = CGFloat(filePayload.innerRadius)
        startingAngle = filePayload.startingAngle
        minimumArcAngleShown = filePayload.minimumArcAngleShown.arcMinimumAngle
        maximumRingsShownCount = filePayload.maximumRingsShownCount
        maximumExpandedRingsShownCount = filePayload.maximumExpandedRingsShownCount
        allowsSelection = filePayload.allowsSelection
    }
}

private extension CalculationModePayload {
    init(_ calculationMode: CalculationMode) {
        switch calculationMode {
        case .ordinalFromRoot:
            self = .ordinalFromRoot
        case .ordinalFromLeaves:
            self = .ordinalFromLeaves
        case .parentDependent(let totalValue):
            self = .parentDependent(totalValue: totalValue)
        case .parentIndependent(let totalValue):
            self = .parentIndependent(totalValue: totalValue)
        }
    }

    var calculationMode: CalculationMode {
        switch self {
        case .ordinalFromRoot:
            return .ordinalFromRoot
        case .ordinalFromLeaves:
            return .ordinalFromLeaves
        case .parentDependent(let totalValue):
            return .parentDependent(totalValue: totalValue)
        case .parentIndependent(let totalValue):
            return .parentIndependent(totalValue: totalValue)
        }
    }
}

private extension NodesSortPayload {
    init(_ nodesSort: NodesSort) {
        switch nodesSort {
        case .none:
            self = .none
        case .asc:
            self = .asc
        case .desc:
            self = .desc
        }
    }

    var nodesSort: NodesSort {
        switch self {
        case .none:
            return .none
        case .asc:
            return .asc
        case .desc:
            return .desc
        }
    }
}

private extension ArcMinimumAnglePayload {
    init(_ arcMinimumAngle: ArcMinimumAngle) {
        switch arcMinimumAngle {
        case .showAll:
            self = .showAll
        case .group(let value):
            self = .group(ifLessThan: value)
        case .hide(let value):
            self = .hide(ifLessThan: value)
        }
    }

    var arcMinimumAngle: ArcMinimumAngle {
        switch self {
        case .showAll:
            return .showAll
        case .group(let threshold):
            return .group(ifLessThan: threshold)
        case .hide(let threshold):
            return .hide(ifLessThan: threshold)
        }
    }
}

private extension String {
    var fileNameSafe: String {
        let allowedCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_ "))
        let sanitizedScalars = unicodeScalars.map { scalar -> Character in
            if allowedCharacters.contains(scalar) {
                return Character(scalar)
            }
            return "-"
        }
        let collapsedWhitespace = String(sanitizedScalars)
            .replacingOccurrences(of: "\\s+", with: "-", options: .regularExpression)
            .replacingOccurrences(of: "-{2,}", with: "-", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
            .lowercased()
        return collapsedWhitespace.isEmpty ? "data-file" : collapsedWhitespace
    }

    var sampleTitleFromFileName: String {
        let baseName: String
        if hasSuffix(SampleActivitiesTemplate.fileSuffix) {
            baseName = String(dropLast(SampleActivitiesTemplate.fileSuffix.count))
        } else if hasSuffix(SampleActivitiesTemplate.legacyFileSuffix) {
            baseName = String(dropLast(SampleActivitiesTemplate.legacyFileSuffix.count))
        } else {
            baseName = (self as NSString).deletingPathExtension
        }

        let normalized = baseName
            .replacingOccurrences(of: "[-_]+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return normalized.isEmpty ? "Sample Data" : normalized.capitalized
    }
}
