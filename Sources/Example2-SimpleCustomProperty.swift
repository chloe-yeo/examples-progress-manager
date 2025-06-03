// Example 2: Custom progress properties (Int) declared in children being accessible from top-level

import FoundationEssentials

// Declaring new custom property
struct MyCustomCount : ProgressManager.Property {
    static var defaultValue: Int { 0 }
}

extension ProgressManager.Properties {
    var customCount: MyCustomCount.Type { MyCustomCount.self }
}

// Helper methods initializing customCount in children ProgressManager
func f1(_ subprogress: consuming Subprogress) async {
    let p = subprogress.start(totalCount: 3)
    p.complete(count: 1)
    p.withProperties { $0.customCount += 1 }

    p.complete(count: 1)
    p.withProperties { $0.customCount += 1 }

    p.complete(count: 1)
    p.withProperties { $0.customCount += 1 }
}

func f2(_ subprogress: consuming Subprogress) async {
    let p = subprogress.start(totalCount: 3)

    p.complete(count: 1)
    p.withProperties { $0.customCount += 1 }

    p.complete(count: 1)
    p.withProperties { $0.customCount += 1 }

    p.complete(count: 1)
    p.withProperties { $0.customCount += 1 }
}

func example2() async {
    // f1 and f2 both report values for "MyCustomCount". We also have a value for it ourselves.
    let p = ProgressManager(totalCount: 2)
    
    _ = await Task.detached {
        await f1(p.subprogress(assigningCount: 1))
    }.value
    
    let v1 = p.withProperties {
        $0.customCount
    }
    print("CustomCount Value is \(v1), fraction: \(p.fractionCompleted)")
    
    _ = await Task.detached {
        await f2(p.subprogress(assigningCount: 1))
    }.value
    
    let v2 = p.withProperties {
        $0.customCount
    }
    print("CustomCount Value is \(v2), fraction: \(p.fractionCompleted)")
    
    print("Values of CustomCount are \(p.values(of: MyCustomCount.self))")
    print("Total of CustomCount Value is \(p.total(of: MyCustomCount.self))")
}
