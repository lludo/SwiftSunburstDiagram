//
//  SunburstDiagramDemoTests.swift
//  SunburstDiagramDemoTests
//
//  Created by Ludo on 2/7/26.
//  Copyright © 2026 Ludovic Landry. All rights reserved.
//

import Foundation
import SunburstDiagram
@testable import Sunburst
import Testing

struct SunburstDiagramDemoTests {
    @MainActor
    @Test
    func bootstrapCreatesBundledSampleFileAndLoadsNodes() throws {
        let fixture = try Self.makeFixture()
        defer { Self.cleanupFixture(fixture) }

        #expect(fixture.store.files.count == 1)
        let selected = try #require(fixture.store.selectedFileDescriptor)
        #expect(selected.title == "Sample Activities")
        #expect(selected.isBundledSample)
        #expect(!fixture.configuration.nodes.isEmpty)
        #expect(FileManager.default.fileExists(atPath: selected.fileURL.path))
    }

    @MainActor
    @Test
    func createRenameDeleteCustomFileLifecycle() throws {
        let fixture = try Self.makeFixture()
        defer { Self.cleanupFixture(fixture) }

        fixture.store.createNewFile(named: "Trips")
        #expect(fixture.store.files.count == 2)
        #expect(fixture.store.selectedFileDescriptor?.title == "Trips")
        #expect(fixture.store.selectedFileDescriptor?.canDelete == true)

        let createdID = try #require(fixture.store.selectedFileID)
        fixture.store.renameFile(id: createdID, to: "Trips Renamed")
        #expect(fixture.store.selectedFileDescriptor?.title == "Trips Renamed")

        let renamedID = try #require(fixture.store.selectedFileID)
        fixture.store.deleteFile(id: renamedID)
        #expect(fixture.store.files.count == 1)
        #expect(fixture.store.selectedFileDescriptor?.title == "Sample Activities")
    }

    @MainActor
    @Test
    func createNewFileDefaultsToOrdinalFromRoot() throws {
        let fixture = try Self.makeFixture()
        defer { Self.cleanupFixture(fixture) }

        fixture.store.createNewFile(named: "Root Mode")
        let selectedURL = try #require(fixture.store.selectedFileDescriptor?.fileURL)
        let saved = try Self.decodeDataFile(at: selectedURL)
        switch saved.configuration.calculationMode {
        case .ordinalFromRoot:
            break
        default:
            Issue.record("Expected new file calculation mode to default to .ordinalFromRoot.")
        }
    }

    @MainActor
    @Test
    func persistWritesUpdatedNodesToDisk() throws {
        let fixture = try Self.makeFixture()
        defer { Self.cleanupFixture(fixture) }

        fixture.configuration.nodes = [Node(name: "Persisted Node", value: 12.5)]
        fixture.store.persistSelectedFileNow()

        let selectedURL = try #require(fixture.store.selectedFileDescriptor?.fileURL)
        let saved = try Self.decodeDataFile(at: selectedURL)
        #expect(saved.nodes.count == 1)
        #expect(saved.nodes.first?.name == "Persisted Node")
        let savedValue = try #require(saved.nodes.first?.value)
        #expect(abs(savedValue - 12.5) < 0.0001)
    }

    @MainActor
    @Test
    func resetBundledSampleRestoresShippedDefault() throws {
        let fixture = try Self.makeFixture()
        defer { Self.cleanupFixture(fixture) }

        let bundledID = try #require(fixture.store.selectedFileID)
        fixture.configuration.nodes = [Node(name: "Modified", value: 1.0)]
        fixture.store.persistSelectedFileNow()
        #expect(fixture.configuration.nodes.first?.name == "Modified")

        fixture.store.resetBundledSample(id: bundledID)

        #expect(fixture.configuration.nodes.first?.name == "Walking")
        #expect(!fixture.configuration.nodes.isEmpty)
    }

    @MainActor
    @Test
    func importCreatesCustomFileAndSelectsIt() throws {
        let fixture = try Self.makeFixture()
        defer { Self.cleanupFixture(fixture) }

        var imported = SampleActivitiesTemplate.defaultDocument(nodesOverride: [
            NodeFilePayload(name: "Imported Root", value: 42.0),
        ])
        imported.document.title = "Imported Plan"
        imported.document.shortDescription = "Imported for test."
        imported.document.isBundledSample = false
        imported.document.bundledSampleID = nil

        let externalURL = fixture.rootURL.appendingPathComponent("external-import.sunburst.json")
        try Self.writeDataFile(imported, to: externalURL)

        fixture.store.importFile(from: externalURL)

        #expect(fixture.store.selectedFileDescriptor?.title == "Imported Plan")
        #expect(fixture.configuration.nodes.first?.name == "Imported Root")
        #expect(fixture.store.selectedFileDescriptor?.isBundledSample == false)
    }

    @MainActor
    @Test
    func persistWritesSystemSymbolImageToDisk() throws {
        let fixture = try Self.makeFixture()
        defer { Self.cleanupFixture(fixture) }

        fixture.configuration.nodes = [Node(name: "Walk", image: .systemSymbol(name: "figure.walk"), value: 7)]
        fixture.store.persistSelectedFileNow()

        let selectedURL = try #require(fixture.store.selectedFileDescriptor?.fileURL)
        let saved = try Self.decodeDataFile(at: selectedURL)
        let savedNode = try #require(saved.nodes.first)
        guard case .systemSymbol(let symbolName) = savedNode.image else {
            Issue.record("Expected persisted node image to be an SF Symbol.")
            return
        }
        #expect(symbolName == "figure.walk")
    }

    // MARK: - Helpers

    @MainActor
    private static func makeFixture() throws -> Fixture {
        let rootURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent("SunburstDiagramDemoTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: rootURL, withIntermediateDirectories: true)

        let suiteName = "SunburstDiagramDemoTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)

        let configuration = SunburstConfiguration(nodes: [])
        let store = DemoDataStore(configuration: configuration,
                                  fileManager: .default,
                                  userDefaults: defaults,
                                  bootstrapFromDisk: true,
                                  dataDirectoryURL: rootURL.appendingPathComponent("DataFiles", isDirectory: true))

        return Fixture(rootURL: rootURL, suiteName: suiteName, configuration: configuration, store: store)
    }

    private static func cleanupFixture(_ fixture: Fixture) {
        if let defaults = UserDefaults(suiteName: fixture.suiteName) {
            defaults.removePersistentDomain(forName: fixture.suiteName)
        }
        try? FileManager.default.removeItem(at: fixture.rootURL)
    }

    private static func decodeDataFile(at url: URL) throws -> SunburstDataFile {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(SunburstDataFile.self, from: Data(contentsOf: url))
    }

    private static func writeDataFile(_ dataFile: SunburstDataFile, to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(dataFile)
        try data.write(to: url, options: .atomic)
    }

    private struct Fixture {
        let rootURL: URL
        let suiteName: String
        let configuration: SunburstConfiguration
        let store: DemoDataStore
    }
}
