//
//  Model.swift
//  SunburstDiagram
//
//  Created by Ludovic Landry on 6/10/19.
//  Copyright © 2019 Ludovic Landry. All rights reserved.
//

import Combine
import SwiftUI

public class Ring: BindableObject {

    public struct Arc: Equatable, Identifiable {
        public var id: ObjectIdentifier
        
        var width: Double
        var hue: Double
        var isTextHidden: Bool
        
        let text: String
        let image: UIImage?
        
        fileprivate(set) var childArcs: [Arc]?
        
        // The start location of the arc, as an angle in radians.
        fileprivate(set) var start = 0.0
        // The end location of the arc, as an angle in radians.
        fileprivate(set) var end = 0.0
        
        public init(text: String, image: UIImage? = nil, width: Double, hue: Double, childArcs: [Arc]? = nil, isTextHidden: Bool = false) {
            self.id = ObjectIdentifier(text as NSString)
            
            self.width = width
            self.hue = hue
            self.isTextHidden =  isTextHidden
            
            self.childArcs = childArcs
            
            self.image = image
            self.text = text
        }
    }
    
    private(set) var arcs: [Arc] = []
    
    // Trivial publisher for our changes.
    public let didChange = PassthroughSubject<Ring, Never>()
    
    public init(arcs: [Arc]) {
        self.arcs = arcs
        modelDidChange()
    }
    
    // Called after each change; updates derived model values and posts the notification.
    private func modelDidChange() {
        guard nestedUpdates == 0 else { return }
        
        // Recalculate locations, to pack within circle.
        
        let totalWidth = arcs.reduce(0.0) { $0 + $1.width }
        let scale = (.pi * 2) / max(.pi * 2, totalWidth)
        
        var location = 0.0
        for index in 0 ..< arcs.count {
            
            // TODO: HACK for now, need to be recursive, not just 1 more level down!
            var childLocation = location
            if let childArcs = arcs[index].childArcs {
                for childIndex in 0 ..< childArcs.count {
                    var childArc = childArcs[childIndex]
                    childArc.start = childLocation * scale
                    childLocation += childArc.width
                    childArc.end = childLocation * scale
                    arcs[index].childArcs![childIndex] = childArc
                }
            }
            
            arcs[index].start = location * scale
            location += arcs[index].width
            arcs[index].end = location * scale
        }
        
        didChange.send(self)
    }
    
    // Non-zero while a batch of updates is being processed.
    private var nestedUpdates = 0
    
    // Invokes `body()` such that any changes it makes to the model
    // will only post a single notification to observers.
    func batch(_ body: () -> Void) {
        nestedUpdates += 1
        defer {
            nestedUpdates -= 1
            if nestedUpdates == 0 {
                modelDidChange()
            }
        }
        body()
    }
    
    func add(arc: Arc) {
        arcs.append(arc)
        modelDidChange()
    }
    
    func remove(arc: Arc) {
        if let index = arcs.firstIndex(of: arc) {
            arcs.remove(at: index)
            modelDidChange()
        }
    }
    
    func reset() {
        if !arcs.isEmpty {
            arcs.removeAll()
            modelDidChange()
        }
    }
}

// MARK: - Random updates for testing

extension Ring {
    
    private static var _randomWalk = [String : Bool]()
    private static var _timer = [String : Timer]()
    
    private var timer: Timer? {
        get {
            let tmpAddress = String(format: "%p", unsafeBitCast(self, to: Int.self))
            return Ring._timer[tmpAddress]
        }
        set(newValue) {
            let tmpAddress = String(format: "%p", unsafeBitCast(self, to: Int.self))
            Ring._timer[tmpAddress] = newValue
            updateTimer()
        }
    }
    
    // When true, periodically updates the data with random changes.
    public var randomWalk: Bool {
        get {
            let tmpAddress = String(format: "%p", unsafeBitCast(self, to: Int.self))
            return Ring._randomWalk[tmpAddress] ?? false
        }
        set(newValue) {
            let tmpAddress = String(format: "%p", unsafeBitCast(self, to: Int.self))
            Ring._randomWalk[tmpAddress] = newValue
            updateTimer()
        }
    }
    
    // Randomly changes values of existing arcs.
    private func randomize() {
        withAnimation(.fluidSpring(stiffness: 10, dampingFraction: 0.5)) {
            for index in 0 ..< arcs.count {
                var arc = arcs[index]
                arc.width = .random(in: max(0.2, arc.width - 0.2) ... min(.pi, arc.width + 0.2))
                arcs[index] = arc
            }
            modelDidChange()
        }
    }
    
    // Ensures the random-walk timer has the correct state.
    private func updateTimer() {
        if randomWalk, timer == nil {
            randomize()
            timer = Timer.scheduledTimer(
                withTimeInterval: 1, repeats: true
            ) { [weak self] _ in
                self?.randomize()
            }
        } else if !randomWalk, let timer = self.timer {
            timer.invalidate()
            self.timer = nil
        }
        modelDidChange()
    }
}

// MARK: - Animation

// Extend the arc description to conform to the Animatable type to
// simplify creation of custom shapes using the arc.
extension Ring.Arc: Animatable {
    // Use a composition of pairs to merge the interpolated values into
    // a single type. AnimatablePair acts as a single interpolatable
    // values, given two interpolatable input types.
    
    // We'll interpolate the derived start/end angles, and the depth
    // and color values. The width parameter is not used for rendering,
    // and so doesn't need to be interpolated.
    
    public typealias AnimatableData = AnimatablePair<AnimatablePair<Double, Double>, Double>
    
    public var animatableData: AnimatableData {
        get {
            AnimatablePair(AnimatablePair(start, end), hue)
        }
        set {
            start = newValue.first.first
            end = newValue.first.second
            hue = newValue.second
        }
    }
}
