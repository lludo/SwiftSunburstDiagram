# Swift Sunburst Diagram

Sunburst diagram is a library written with SwiftUI to easily render diagrams given a tree of objects. Similar to ring chart, sunburst chart, multilevel pie chart.

<img src="https://github.com/lludo/SwiftSunburstDiagram/blob/master/diagram-icons-only.png" alt="diagram with icons only" width="400"/><img src="https://github.com/lludo/SwiftSunburstDiagram/blob/master/diagram-with-text.png" alt="diagram with icons and text" width="400"/>

**⚠️ WARNING ⚠️** This is an early version of this library that requires Swift 5.1 and  Xcode 11 that are currently still in beta, some features available in the public API have not been implemented yet (see below).


## Requirements

- iOS 13.0+ / macOS 10.15+ / tvOS 13.0+ / watchOS 6.0+
- Xcode 11+
- Swift 5.1+


## Installation

The [Swift Package Manager](https://swift.org/package-manager/) is a tool for automating the distribution of Swift code and is integrated into the `swift` compiler. It is now integrated in Xcode 11.

Once you have your Swift package set up, adding SunburstDiagram as a dependency is as easy as adding it to the `dependencies` value of your `Package.swift`.

```swift
dependencies: [
    .package(url: "https://github.com/lludo/SwiftSunburstDiagram.git")
]
```

If you prefer not to use the Swift Package Manager, you can integrate SunburstDiagram into your project manually.


## Features

- [x] Configure with a tree of node objects
- [x] Nodes have an optional label displayed (image & text)
- [x] Reactive UI with animated updates
- [x] Optionally configure nodes with a value (4 different rendering modes: `.ordinalFromRoot`, `.ordinalFromLeaves`,`.parentDependent`,`.parentIndependent`)
- [x] Infinite number of layers (circles) support

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

// Get the view controller for the RingView
let viewController = UIHostingController(rootView: SunburstView.configureWith(configuration))
```


## Communication

If you **found a bug** or want to discuss a new **feature** do not hesitate to message me. If you **want to contribute**, all pull requests are always welcome. Thank you!


## Todo

- [ ] Implement arc margin configuration property
- [ ] Add option to select an arc
- [ ] Add option to navigate by clicking an arc to see more detail
- [ ] Implement option for max number of rings to display
- [ ] Implement option to have collapsed rings (to show more layers with less data)
- [ ] Implement option to configure the number of expanded / collapsed rings displayed
- [ ] Implement option to configure the size of central / expended / collapsed rings
- [ ] Implement option for min arc percentage (if less, show data in grouped in "other")
- [ ] Add option to get currently selected ring
- [ ] Add selection callbacks
- [ ] Compute arc colors if not provided by nodes
- [ ] Add option to show un-assigned if total of arcs is less than 100%
- [ ] Add rounded corners option for arcs with margins?


## Inspirations

This project has been inspired by the [DaisyDisk](https://daisydiskapp.com/) UI and the Apple SwiftUI [Building Custom Views with SwiftUI](https://developer.apple.com/videos/play/wwdc2019/237/) WWDC2019 session.
