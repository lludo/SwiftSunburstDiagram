# Swift Sunburst Diagram

[![Swift Version](https://img.shields.io/badge/Swift-5.1-orange.svg)](https://swift.org/blog/5-1-release-process/)
[![License](http://img.shields.io/:license-mit-blue.svg)](http://doge.mit-license.org)
[![Swift Package Manager compatible](https://img.shields.io/badge/Swift%20Package%20Manager-✔-brightgreen.svg)](https://github.com/apple/swift-package-manager)
[![CocoaPods Compatible](https://img.shields.io/cocoapods/v/SunburstDiagram.svg)](https://img.shields.io/cocoapods/v/SunburstDiagram.svg)

Sunburst diagram is a library written with SwiftUI to easily render diagrams given a tree of objects. Similar to ring chart, sunburst chart, multilevel pie chart.

<img src="https://github.com/lludo/SwiftSunburstDiagram/blob/master/Docs/diagram-icons-only.png" alt="diagram with icons only" width="400"/> <img src="https://github.com/lludo/SwiftSunburstDiagram/blob/master/Docs/diagram-with-text.png" alt="diagram with icons and text" width="400"/>

This library requires Swift 5.1 and Xcode 11, some features available in the public API have not been implemented yet (see below).


## Requirements

- iOS 13.0+ / macOS 10.15+ / tvOS 13.0+ / watchOS 6.0+
- Xcode 11+
- Swift 5.1+


## Installation

### Swift Package Manager

The [Swift Package Manager](https://swift.org/package-manager/) is a tool for automating the distribution of Swift code and is integrated into the `swift` compiler. It is now integrated in Xcode 11.

Once you have your Swift package set up, adding SunburstDiagram as a dependency is as easy as adding it to the `dependencies` value of your `Package.swift`.

```swift
dependencies: [
    .package(url: "https://github.com/lludo/SwiftSunburstDiagram.git")
]
```


### Cocoapods

[CocoaPods](https://cocoapods.org) is a dependency manager for Cocoa projects. For usage and installation instructions, visit their website. To integrate Alamofire into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ruby
pod 'SunburstDiagram', '~> 1.1.0'
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
    Node(name: "Walking", value: 10.0, backgroundColor: .systemBlue),
    Node(name: "Restaurant", value: 30.0, backgroundColor: .systemRed, children: [
        Node(name: "Dessert", image: UIImage(named: "croissant"), value: 6.0),
        Node(name: "Dinner", image: UIImage(named: "poultry"), value: 10.0),
    ]),
    Node(name: "Transport", value: 10.0, backgroundColor: .systemPurple),
    Node(name: "Home", value: 50.0, backgroundColor: .systemTeal),
])

// Get the view controller for the SunburstView
let viewController = UIHostingController(rootView: SunburstView(configuration: configuration))
```


## Communication

If you **found a bug** or want to discuss a new **feature** do not hesitate to message me. If you **want to contribute**, all pull requests are always welcome. Thank you!


## Demo App

The demo app in this repo is also written with SwiftUI and allows to experience the API of this library in a grapical and reactive way.

<img src="https://github.com/lludo/SwiftSunburstDiagram/blob/master/Docs/demo-app-1.png" alt="iOS demo app first screenshot" width="260"/>  <img src="https://github.com/lludo/SwiftSunburstDiagram/blob/master/Docs/demo-app-2.png" alt="iOS demo app second screenshot" width="260"/>  <img src="https://github.com/lludo/SwiftSunburstDiagram/blob/master/Docs/demo-app-3.png" alt="iOS demo app third screenshot" width="260"/>

<img src="https://github.com/lludo/SwiftSunburstDiagram/blob/master/Docs/demo-app-mac.png" alt="macOS demo app screenshot" width="788"/>

## Todo

- [ ] Implement option for min arc percentage (if less, show data in grouped in "other")
- [ ] Compute arc colors if not provided by nodes
- [ ] Add option to show un-assigned if total of arcs is less than 100%
- [ ] Add rounded corners option for arcs with margins?


## Inspirations

This project has been inspired by the [DaisyDisk](https://daisydiskapp.com/) UI and the Apple SwiftUI [Building Custom Views with SwiftUI](https://developer.apple.com/videos/play/wwdc2019/237/) WWDC2019 session.
