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

// Example 5: Observing values(of:)
import FoundationEssentials
import Observation
import Synchronization

private struct Completed: Error {}

func example5() async {
    print("observation should see numbered files, eventually seeing file #9.")
    print("it's allowed to skip some values along the way (but it probably won't)")
    
    // an indeterminate manager
    let manager = ProgressManager(totalCount: nil)
    
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
                                let total = manager.total(of: ProgressManager.Properties.CompletedFileCount.self)
                                print(total)
                                // not simulating SwiftUI, just helping the example along:
                                // if we've received the 10th file, the progress is complete.
                                // exit this loop.
                                if total == 9 {
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
            } catch {
                print("BUG: UI was cancelled early")
            }
        }
        group.addTask {
            do {
                for i in 0..<10 {
                    try await Task.sleep(for: .seconds(1))
                    // indicate indeterminate progress by setting
                    // a user-defined property:
                    manager.withProperties { values in
                        values.completedFileCount = i
                    }
                }
            } catch is Completed {
                // good
            } catch {
                print("BUG: progress was cancelled early")
            }
        }
        
        // safety net — this whole thing shouldn't take more than like, 11s
        do {
            for _ in 0..<6 {
                try await Task.sleep(for: .seconds(2))
                // remove these prints when the example works:
                print("...")
            }
        } catch {
            print("UNEXPECTED: group was cancelled early")
        }
        group.cancelAll()
    }
}
