# Swift Sunburst Diagram

[![Swift Version](https://img.shields.io/badge/Swift-6.2-orange.svg)](https://swift.org/blog/)
[![License](http://img.shields.io/:license-mit-blue.svg)](http://doge.mit-license.org)
[![Swift Package Manager compatible](https://img.shields.io/badge/Swift%20Package%20Manager-✔-brightgreen.svg)](https://github.com/apple/swift-package-manager)
[![CocoaPods Compatible](https://img.shields.io/cocoapods/v/SunburstDiagram.svg)](https://img.shields.io/cocoapods/v/SunburstDiagram.svg)

Sunburst diagram is a library written with SwiftUI to easily render diagrams given a tree of objects. Similar to ring chart, sunburst chart, multilevel pie chart.

<img src="https://github.com/lludo/SwiftSunburstDiagram/blob/master/Docs/diagram-icons-only.png" alt="diagram with icons only" width="400"/> <img src="https://github.com/lludo/SwiftSunburstDiagram/blob/master/Docs/diagram-with-text.png" alt="diagram with icons and text" width="400"/>

This library targets modern SwiftUI on iOS, macOS, tvOS, and watchOS and requires Swift 6.2+ and Xcode 17+ (some public API features are still TODO; see below).


## Requirements

- iOS 26.0+ / macOS 26.0+ / tvOS 26.0+ / watchOS 26.0+
- Xcode 17+
- Swift 6.2+


## Installation

### Swift Package Manager

The [Swift Package Manager](https://swift.org/package-manager/) is a tool for automating the distribution of Swift code and is integrated into the `swift` compiler. It is integrated in Xcode.

Once you have your Swift package set up, adding SunburstDiagram as a dependency is as easy as adding it to the `dependencies` value of your `Package.swift`.

```swift
dependencies: [
    .package(url: "https://github.com/lludo/SwiftSunburstDiagram.git", from: "1.5.0")
]
```


### CocoaPods

[CocoaPods](https://cocoapods.org) is a dependency manager for Cocoa projects. For usage and installation instructions, visit their website. To integrate SunburstDiagram into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ruby
pod 'SunburstDiagram', '~> 1.5'
```


### Manually

If you prefer not to use the Swift Package Manager, you can integrate SunburstDiagram into your project manually.


## Features

- [x] Configure with a tree of node objects
- [x] Nodes have an optional label displayed (image & text)
- [x] Reactive UI with animated updates
- [x] Optionally configure nodes with a value (4 different rendering modes)
- [x] Infinite number of layers (circles) support
- [x] Option to configure margin, size, sort and initial positions of arcs
- [x] Option to collapse arcs beyond a certain layer (to show more layers with less data)
- [x] Ability to select a node and focus on a node to see more details or disable selection
- [x] Option for maximum number of rings to display (like a window moving as you focus on nodes)

## Usage

```swift
// Create your configuration model
let configuration = SunburstConfiguration(nodes: [
    Node(name: "Walking", value: 10.0, backgroundColor: .system(.blue)),
    Node(name: "Restaurant", value: 30.0, backgroundColor: .system(.red), children: [
        Node(name: "Dessert", image: .asset(name: "croissant"), value: 6.0),
        Node(name: "Dinner", image: .asset(name: "poultry"), value: 10.0),
    ]),
    Node(name: "Transport", value: 10.0, backgroundColor: .system(.purple)),
    Node(name: "Home", value: 50.0, backgroundColor: .system(.teal)),
])

// Use directly in SwiftUI
struct ContentView: View {
    @StateObject private var configuration = SunburstConfiguration(nodes: sampleNodes())

    var body: some View {
        SunburstView(configuration: configuration)
    }
}
```

To embed in UIKit, wrap `SunburstView` in a `UIHostingController`.

### Colors and Images

`Node` uses lightweight references instead of platform types:
- `ImageRef.asset(name:)` or `ImageRef.systemSymbol(name:)`
- `ColorRef.system(_)`, `ColorRef.asset(name:)`, `ColorRef.rgba(...)`, or `ColorRef.dynamic(light:dark:)`


## Communication

If you **found a bug** or want to discuss a new **feature** do not hesitate to message me. If you **want to contribute**, all pull requests are always welcome. Thank you!


## Showcase App

The demo app in this repo is written with SwiftUI and includes:

- `SunburstDiagramDemo` multi-platform target (iOS, macOS, tvOS, visionOS)
- `SunburstDiagramDemoWatch` standalone watchOS app target (with watch extension)

The iOS showcase app is also [available on the App Store](https://apps.apple.com/us/app/id1468995506) for free.

<img src="https://github.com/lludo/SwiftSunburstDiagram/blob/master/Docs/demo-app-1.png" alt="iOS demo app first screenshot" width="260"/>  <img src="https://github.com/lludo/SwiftSunburstDiagram/blob/master/Docs/demo-app-2.png" alt="iOS demo app second screenshot" width="260"/>  <img src="https://github.com/lludo/SwiftSunburstDiagram/blob/master/Docs/demo-app-3.png" alt="iOS demo app third screenshot" width="260"/>

<img src="https://github.com/lludo/SwiftSunburstDiagram/blob/master/Docs/demo-app-mac.png" alt="macOS demo app screenshot" width="788"/>

## Todo

### Framework

- [ ] Implement option for min arc percentage (if less, show data grouped in "other")
- [ ] Compute arc colors if no color is provided by nodes
- [ ] Add option to show unassigned if total of arcs is less than 100%
- [ ] Add rounded corners option for arcs with margins
- [ ] Switch `BundleRef.module` from `.main` to a real SPM resource bundle when package resources are added
- [ ] Revisit any remaining sendability/concurrency warnings with an explicit ownership/actor isolation plan

### Demo Apps

- [ ] Replace placeholder app icons for demo targets (watchOS `AppIcon` still has unassigned sizes)
- [ ] Resolve duplicate asset warnings between `Assets.xcassets` and `Assets-Shared.xcassets` (`croissant`, `eating`, `house`, `poultry`, `sailing`, `walking`)
- [ ] Decide whether tvOS settings remain read-only or move to custom focusable editable controls


## Inspirations

This project has been inspired by the [DaisyDisk](https://daisydiskapp.com/) UI and the Apple SwiftUI [Building Custom Views with SwiftUI](https://developer.apple.com/videos/play/wwdc2019/237/) WWDC2019 session.
