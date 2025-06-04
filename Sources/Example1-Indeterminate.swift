//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

// Example 1: ProgressManager becoming determinate after being initialized as indeterminate

import FoundationEssentials

func doThing1(subprogress: consuming Subprogress) async throws {
    let myPart = subprogress.start(totalCount: 2)
    try await Task.sleep(for: .milliseconds(200))
    myPart.complete(count: 1)
    try await Task.sleep(for: .milliseconds(200))
    myPart.complete(count: 1)
}

func example1() async {
    // Structure: Overall indeterminate, 1 determinate child, then we determine total and complete the rest

    let p = ProgressManager(totalCount: nil)
    print("Indeterminate: \(p.isIndeterminate) fraction: \(p.fractionCompleted)")
    
    // Complete part of the work asynchronously
    Task.detached {
        try await doThing1(subprogress: p.subprogress(assigningCount: 5))
        print("Indeterminate: \(p.isIndeterminate) fraction: \(p.fractionCompleted)")
        
        // hack to make sure we don't finish early
        try await Task.sleep(for: .milliseconds(500))
    }
    
    // Discover total work, let's say it's 5, then we have the 5 we handed out earlier
    let discoveredTotal = 5 + 5
    
    p.withProperties { values in
        values.totalCount = discoveredTotal
    }
    print("Indeterminate: \(p.isIndeterminate) fraction: \(p.fractionCompleted)")
    
    // Complete the remainder of the work (our 5)
    p.complete(count: 5)
    print("Indeterminate: \(p.isIndeterminate) fraction: \(p.fractionCompleted)")
    
    // hack to make sure we don't finish early
    try! await Task.sleep(for: .milliseconds(500))
}
