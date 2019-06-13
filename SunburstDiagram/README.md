# SunburstDiagram

Sunburst diagram library written with SwiftUI

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

- [x] Tree structure of arcs
- [x] Arcs have an optional label displayed (image & text)
- [x] Reactive with animated updates


## Communication

If you **found a bug** or want to discuss a new **feature** do not hesitate to message me. If you **want to contribute**, all pull requests are always welcome. Thank you!

## Todo

- [ ] Configure arcs with a percentage instead of a width
- [ ] Update arc computation to have infinite number of circles
- [ ] Add option for min arc percentage (if less, show data in grouped in "other")
- [ ] Add option to show un-assigned if total of arcs is less than 100%
- [ ] Add option to select an arc
- [ ] Add option to navigate by clicking an arc to see more detail
- [ ] Add option for max number of rings to display
- [ ] Add option to have collapsed rings (to show more layers with less data)
- [ ] Add option to configure the number of expanded / collapsed rings displayed
- [ ] Add option to configure the size of central / expended / collapsed rings
- [ ] Get currently selected ring
- [ ] Add selection callbacks
- [ ] Refactor arc color management to have better flexibility
- [ ] Add rounded corners option for arcs with margins?
