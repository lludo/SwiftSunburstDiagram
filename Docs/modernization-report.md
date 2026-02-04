# Modernization Report (2026-02-04)

## Scope
- Updated the SwiftUI library and demo app to modern SwiftUI patterns.
- Kept the library multi-platform (iOS, macOS, tvOS, watchOS) and restored macOS/tvOS/watchOS demo targets.
- Replaced platform UI types in the model with pure references for images/colors.

## Key Changes
- Library
  - `SunburstConfiguration` and `Sunburst` are now `@MainActor` and use simpler update flows.
  - Selection cleanup when nodes change to avoid stale `selectedNode`/`focusedNode` references.
  - Fixed arc cache updates so animations reflect the latest geometry and child removal.
  - Fixed parent-dependent validation to ensure **all** nodes have values (not just leaves).
  - Added `Node` identity initializer and equality by `id` for stable selection semantics.
  - Improved arc hit-testing (`contentShape`) and animation wiring.
  - Guarded against divide-by-zero for empty node trees in ordinal modes.
  - Introduced `ImageRef` and `ColorRef` (pure, platform-agnostic references) and removed UIKit/AppKit types from the model.
  - Added `AppearanceRef+SwiftUI` resolvers that react to the environment (including `ColorScheme`) for light/dark handling.
  - Removed legacy `PlatformTypes.swift` typealiases.
- Sample app
  - Migrated to SwiftUI `@main` App lifecycle.
  - Removed `SceneDelegate` and its project references.
  - Removed deprecated `NavigationView` usage in favor of `NavigationStack`.
  - Removed legacy `IfLet` view helper and deprecated `edgesIgnoringSafeArea` usage.
  - Refined form labels, value formatting, and spacing for the configuration UI.
- Added tvOS-safe settings UI fallback (`List` instead of `Form`).
- tvOS settings sliders are read-only placeholders (no Slider/Stepper support in SwiftUI).
  - Added macOS/tvOS/watchOS demo targets with shared assets and platform-specific AppIcon catalogs.
- Tests
  - Added unit coverage for all calculation modes and selection cleanup.
  - Marked `Sunburst.Arc` geometry helpers as `@MainActor` to satisfy isolation checks during iOS simulator builds.

## Updated Targets
- Swift tools: 6.2
- iOS/macOS/tvOS/watchOS deployment target: 26.0

## Known Limitations / Follow-ups
- `BundleRef.module` currently resolves to `.main` because the package does not yet define SPM resources (so `Bundle.module` is unavailable).
- Unimplemented features (pre-existing)
  - Minimum arc angle grouping/hiding.
  - Automatic color generation for nodes without explicit colors.
  - Unassigned/remaining slice when total does not equal 100%.
  - Rounded arc corners when margins are used.
## Concurrency Note
- No `@unchecked Sendable` usage. If any remaining sendability warnings appear in downstream apps, we should review actor isolation and data ownership as a follow-up.

## Test Run (iOS Simulator)
- Command: `xcodebuild -scheme SunburstDiagram -destination 'platform=iOS Simulator,name=iPhone 17' test -derivedDataPath /tmp/SunburstDiagramDerivedData`
- Result: ✅ 7 tests passed (2026-02-03)
- xcresult: `/tmp/SunburstDiagramDerivedData/Logs/Test/Test-SunburstDiagram-2026.02.03_22-33-54--0800.xcresult`

## Demo App Builds
- ✅ iOS Simulator: `xcodebuild -project Example/SunburstDiagramDemo.xcodeproj -scheme SunburstDiagramDemo -destination 'generic/platform=iOS Simulator' build`
- ✅ macOS: `xcodebuild -project Example/SunburstDiagramDemo.xcodeproj -scheme SunburstDiagramDemo-macOS -destination 'generic/platform=macOS' build`
- ✅ tvOS Simulator: `xcodebuild -project Example/SunburstDiagramDemo.xcodeproj -scheme SunburstDiagramDemo-tvOS -destination 'generic/platform=tvOS Simulator' build`
- ✅ watchOS Simulator: `xcodebuild -project Example/SunburstDiagramDemo.xcodeproj -scheme SunburstDiagramDemo-watchOS -destination 'generic/platform=watchOS Simulator' build`

## TODO (Tracked for later)
- Consider richer asset naming helpers (optional; current `ImageRef`/`ColorRef` cover system and asset cases).
- Switch `BundleRef.module` to the SPM resource bundle if/when resources are added.
- Revisit any sendability warnings with an explicit concurrency plan.
- Replace placeholder app icons for macOS/tvOS/watchOS demo targets.
- Decide whether tvOS should support editable settings (custom focusable controls) or stay read-only.
- Implement minimum arc angle grouping/hiding behaviors.
- Compute default colors for nodes when none are provided.
- Add an “unassigned” slice when total < 100% in value-based modes.
- Consider rounded arc corners (especially when margins are enabled).
