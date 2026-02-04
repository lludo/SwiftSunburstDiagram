//
//  AppearanceRef.swift
//  SunburstDiagram
//
//  Created by Ludovic Landry on 6/13/19.
//  Copyright © 2019 Ludovic Landry. All rights reserved.
//

import Foundation

public enum BundleRef: Hashable, Codable, Sendable {
    case main
    case module
    case identifier(String)
}

public enum ImageRef: Hashable, Codable, Sendable {
    case asset(name: String, bundle: BundleRef = .main)
    case systemSymbol(name: String)
}

public enum SemanticColor: String, Codable, Sendable {
    case primary
    case secondary
    case accent
    case clear
    case black
    case white
    case gray
}

public enum SystemColor: String, Codable, Sendable {
    case blue
    case red
    case green
    case orange
    case yellow
    case teal
    case purple
    case pink
    case indigo
    case gray
    case background
    case secondaryBackground
    case tertiaryBackground
    case groupedBackground
    case secondaryGroupedBackground
    case tertiaryGroupedBackground
    case label
    case secondaryLabel
    case separator
}

public indirect enum ColorRef: Hashable, Codable, Sendable {
    case asset(name: String, bundle: BundleRef = .main)
    case rgba(red: Double, green: Double, blue: Double, alpha: Double = 1.0)
    case semantic(SemanticColor)
    case system(SystemColor)
    case dynamic(light: ColorRef, dark: ColorRef)

    static let defaultBackground: ColorRef = .system(.gray)
}
