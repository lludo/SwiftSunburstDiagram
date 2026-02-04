//
//  AppearanceRef+SwiftUI.swift
//  SunburstDiagram
//
//  Created by Ludovic Landry on 6/13/19.
//  Copyright © 2019 Ludovic Landry. All rights reserved.
//

import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

extension BundleRef {
    public func resolve() -> Bundle {
        switch self {
        case .main:
            return .main
        case .module:
            return .main
        case .identifier(let id):
            return Bundle(identifier: id) ?? .main
        }
    }
}

extension ImageRef {
    public func resolve(bundleResolver: (BundleRef) -> Bundle = { $0.resolve() }) -> Image {
        switch self {
        case .asset(let name, let bundle):
            return Image(name, bundle: bundleResolver(bundle))
        case .systemSymbol(let name):
            return Image(systemName: name)
        }
    }
}

extension SemanticColor {
    var color: Color {
        switch self {
        case .primary:
            return .primary
        case .secondary:
            return .secondary
        case .accent:
            return .accentColor
        case .clear:
            return .clear
        case .black:
            return .black
        case .white:
            return .white
        case .gray:
            return .gray
        }
    }
}

extension SystemColor {
    func resolve() -> Color {
        #if canImport(UIKit)
        return Color(uiColor: uiColor)
        #elseif canImport(AppKit)
        return Color(nsColor: nsColor)
        #else
        return fallbackColor
        #endif
    }

    #if canImport(UIKit)
    private var uiColor: UIColor {
        switch self {
        case .blue:
#if os(watchOS)
            return .blue
#else
            return .systemBlue
#endif
        case .red:
#if os(watchOS)
            return .red
#else
            return .systemRed
#endif
        case .green:
#if os(watchOS)
            return .green
#else
            return .systemGreen
#endif
        case .orange:
#if os(watchOS)
            return .orange
#else
            return .systemOrange
#endif
        case .yellow:
#if os(watchOS)
            return .yellow
#else
            return .systemYellow
#endif
        case .teal:
#if os(watchOS)
            return .cyan
#else
            return .systemTeal
#endif
        case .purple:
#if os(watchOS)
            return .purple
#else
            return .systemPurple
#endif
        case .pink:
#if os(watchOS)
            return .magenta
#else
            return .systemPink
#endif
        case .indigo:
#if os(watchOS)
            return .blue
#else
            return .systemIndigo
#endif
        case .gray:
#if os(watchOS)
            return .gray
#else
            return .systemGray
#endif
        case .background:
#if os(tvOS) || os(watchOS)
            return .black
#else
            return .systemBackground
#endif
        case .secondaryBackground:
#if os(tvOS) || os(watchOS)
            return .darkGray
#else
            return .secondarySystemBackground
#endif
        case .tertiaryBackground:
#if os(tvOS) || os(watchOS)
            return .gray
#else
            return .tertiarySystemBackground
#endif
        case .groupedBackground:
#if os(tvOS) || os(watchOS)
            return .black
#else
            return .systemGroupedBackground
#endif
        case .secondaryGroupedBackground:
#if os(tvOS) || os(watchOS)
            return .darkGray
#else
            return .secondarySystemGroupedBackground
#endif
        case .tertiaryGroupedBackground:
#if os(tvOS) || os(watchOS)
            return .gray
#else
            return .tertiarySystemGroupedBackground
#endif
        case .label:
#if os(watchOS)
            return .white
#else
            return .label
#endif
        case .secondaryLabel:
#if os(watchOS)
            return .lightGray
#else
            return .secondaryLabel
#endif
        case .separator:
#if os(watchOS)
            return .darkGray
#else
            return .separator
#endif
        }
    }
    #elseif canImport(AppKit)
    private var nsColor: NSColor {
        switch self {
        case .blue:
            return .systemBlue
        case .red:
            return .systemRed
        case .green:
            return .systemGreen
        case .orange:
            return .systemOrange
        case .yellow:
            return .systemYellow
        case .teal:
            return .systemTeal
        case .purple:
            return .systemPurple
        case .pink:
            return .systemPink
        case .indigo:
            return .systemIndigo
        case .gray:
            return .systemGray
        case .background:
            return .windowBackgroundColor
        case .secondaryBackground:
            return .underPageBackgroundColor
        case .tertiaryBackground:
            return .controlBackgroundColor
        case .groupedBackground:
            return .windowBackgroundColor
        case .secondaryGroupedBackground:
            return .underPageBackgroundColor
        case .tertiaryGroupedBackground:
            return .controlBackgroundColor
        case .label:
            return .labelColor
        case .secondaryLabel:
            return .secondaryLabelColor
        case .separator:
            return .separatorColor
        }
    }
    #endif

    private var fallbackColor: Color {
        switch self {
        case .blue:
            return .blue
        case .red:
            return .red
        case .green:
            return .green
        case .orange:
            return .orange
        case .yellow:
            return .yellow
        case .teal:
            return .teal
        case .purple:
            return .purple
        case .pink:
            return .pink
        case .indigo:
            return .indigo
        case .gray:
            return .gray
        case .background:
            return .black
        case .secondaryBackground:
            return .black.opacity(0.9)
        case .tertiaryBackground:
            return .black.opacity(0.8)
        case .groupedBackground:
            return .black
        case .secondaryGroupedBackground:
            return .black.opacity(0.9)
        case .tertiaryGroupedBackground:
            return .black.opacity(0.8)
        case .label:
            return .primary
        case .secondaryLabel:
            return .secondary
        case .separator:
            return .secondary
        }
    }
}

extension ColorRef {
    public func resolve(in colorScheme: ColorScheme, bundleResolver: (BundleRef) -> Bundle = { $0.resolve() }) -> Color {
        switch self {
        case .asset(let name, let bundle):
            return Color(name, bundle: bundleResolver(bundle))
        case .rgba(let red, let green, let blue, let alpha):
            return Color(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
        case .semantic(let semantic):
            return semantic.color
        case .system(let system):
            return system.resolve()
        case .dynamic(let light, let dark):
            return (colorScheme == .dark ? dark : light).resolve(in: colorScheme, bundleResolver: bundleResolver)
        }
    }
}
