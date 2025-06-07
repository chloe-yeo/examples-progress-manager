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

// Example 6: Observing value asynchronously, missing updates.
import Dispatch
import FoundationEssentials
import Observation
import Synchronization

private struct Completed: Error {}

func example6() async {
    print("observation should see fractions 0.0 and 1.0")
    print("but it doesn't, because the update to 1.0 is asynchronous")
    print("and races with the establishment of observation")

    // some utilities to show the bug
    let readyForCompletion = DispatchSemaphore(value: 0)
    let readyForObservation = DispatchSemaphore(value: 0)
    
    // a deterministic manager
    let manager = ProgressManager(totalCount: 1)
    
    await withDiscardingTaskGroup { group in
        group.addTask {
            do {
                while true {
                    // use observation to watch for new values
                    // this should be updated to use SE-0475 once available.
                    let mutex = Mutex(CheckedContinuation<Void, any Error>?.none)
                    try await withTaskCancellationHandler {
                        try await withCheckedThrowingContinuation { continuation in
                            let earlyExit: CheckedContinuation<Void, any Error>? = mutex.withLock {
                                if Task.isCancelled {
                                    return continuation
                                } else {
                                    $0 = continuation
                                    return nil
                                }
                            }
                            if let earlyExit {
                                earlyExit.resume(throwing: CancellationError())
                            }
                            // simulating SwiftUI:
                            withObservationTracking {
                                // call body, displaying the current value
                                let fractionCompleted = manager.fractionCompleted
                                print(fractionCompleted)
                                
                                // showing concurrent modification issue:
                                // trigger update to 1.0 *after* we read `fractionCompleted`
                                // and *before* we establish the observation.
                                // This example forces the case, but in general this can
                                // happen by accident of race condition.
                                readyForCompletion.signal()
                                readyForObservation.wait()
                                
                                // not simulating SwiftUI, just helping the example along:
                                // if fractionCompleted is >= 1.0, we're done.
                                if fractionCompleted >= 1.0 {
                                    mutex.withLock { $0.take() }?.resume(throwing: Completed())
                                }
                            } onChange: {
                                // something changed, reschedule the renderer
                                mutex.withLock { $0.take() }?.resume()
                            }
                        }
                    } onCancel: {
                        mutex.withLock { $0.take() }?.resume(throwing: CancellationError())
                    }
                }
            } catch is Completed {
                // good
            } catch {
                print("BUG: UI was cancelled early")
            }
        }
        group.addTask {
            { readyForCompletion.wait() }()
            manager.complete(count: 1)
            readyForObservation.signal()
        }
        
        // safety net — this whole thing shouldn't take more than like, 1s
        do {
            for _ in 0..<1 {
                try await Task.sleep(for: .seconds(2))
                // remove these prints if the example ever works:
                print("...")
            }
        } catch {
            print("UNEXPECTED: group was cancelled early")
        }
        group.cancelAll()
    }
}
