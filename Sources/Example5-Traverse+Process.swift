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

//DISCLAIMER: When this example is running, it may sometimes might hang due to a bug, we're working on tracking it down. Thank you for the patience. 

import FoundationEssentials
import FoundationInternationalization // for .formatted(.percent)
import Algorithms // for chunk
import ObservationSequence // temporary package for Observations
import AsyncAlgorithms
import Synchronization

// File "finding" function. Calls body each time it finds a file.
func findFiles(_ body: (String, Int) -> Void) async {
    for i in 0..<10 {
        // emulate finding files taking a while. This work is done serially, but the processing is done asynchronously. That way we discover work as we go and fire it off.
        try! await Task.sleep(for: .milliseconds(25))

        // We found a file!
        let fileSize = (50..<100).randomElement()!

        // file name is generated here, for demo purposes.
        body("File_\(i).gif", fileSize)
    }
}

final class ScanAndProcessOperation : Sendable {
    // Public progress reporting - not mutable, but observable
    public let progressReporter: ProgressReporter

    // Progress managed by this class, either assigned or completed itself.
    private let progressManager: ProgressManager

    func discoverAndProcessFiles() async {
        // We have 1 + n async tasks.
        // The first async task is to discover all of the files. When that is complete, we will know what the value of `n` is.
        // The `n` tasks are one async task each to do processing. They are performed in parallel using the group, even while we are still discovering files.
        await withTaskGroup { group in
            var totalFileSize = 0

            await findFiles { (fileName, fileSize) in
                // Find one file
                totalFileSize += fileSize

                // Let's process it in parallel. Some of these will finish before the overall progress discovers all files and becomes determinate.
                group.addTask { [self] in
                    // This will represent a portion of the total number of bytes of all files. We know the file size here, so we can use it for the count. The subprogress will be fileSize of totalFileSize units in `progressManager`.
                    let subprogress = progressManager.subprogress(assigningCount: fileSize)
                    await processFile(fileName: fileName, subprogress: subprogress)
                }
            }

            // We now know the total file size. Become determinate.
            print("Total size of the files is \(totalFileSize)")
            progressManager.withProperties {
                $0.totalCount = totalFileSize
            }

            // Return when all files have been processed
            await group.waitForAll()
        }
    }

    private func processFile(fileName: String, subprogress: consuming Subprogress) async {
        // Make a progress manager to track this one file. It can count progress in whatever way it thinks is appropriate. e.g., using file size, or maybe using some other algorithm. Here, we emulate processing in 25% chunks.
        let oneFileManager = subprogress.start(totalCount: 4)
        
        for _ in 1...4 {
            try! await Task.sleep(for: .milliseconds(10))
            // Complete some progress on this one file.
            oneFileManager.complete(count: 1)
        }
        print("Done with file \(fileName)")
    }

    init() {
        progressManager = ProgressManager(totalCount: nil) // indeterminate
        progressReporter = progressManager.reporter
    }
}

// MARK: -

@MainActor
func example5() async {
    let op = ScanAndProcessOperation()

    let o = Observations {
        (op.progressReporter.fractionCompleted, op.progressReporter.isFinished, op.progressReporter.isIndeterminate)
    }

    Task {
        await op.discoverAndProcessFiles()
    }

    for try await _ in o {
        if op.progressReporter.isIndeterminate {
            print("Indeterminate")
        } else {
            print("\(op.progressReporter.fractionCompleted.formatted(.percent)) - \(op.progressReporter.completedCount) / \(op.progressReporter.totalCount ?? 0)")
        }
        if op.progressReporter.isFinished {
            break
        }
    }

}
