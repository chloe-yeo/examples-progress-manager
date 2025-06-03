// Example 3: Custom progress properties (struct) declared in children being accessible from top-level

import FoundationEssentials

struct MyXYZ : ProgressManager.Property {
    
    typealias Value = XYZ

    struct XYZ: Sendable, Hashable {
        var a: Int
        var b: Double
    }
    
    static var defaultValue: XYZ {
        .init(a: 3, b: 3.14159)
    }
    
    static func reduce(_ all: [XYZ?]) -> XYZ {
        var aggregated_xyz = XYZ(a: 0, b: 0.0)
        for element in all {
            if let el = element {
                aggregated_xyz.a += el.a
                aggregated_xyz.b += el.b
            }
        }
        return aggregated_xyz
    }
}

extension ProgressManager.Properties {
    var xyz: MyXYZ.Type { MyXYZ.self }
}

// Helper methods initializing xyz in children ProgressManager
func f1b(_ subprogress: consuming Subprogress? = nil) async {
    let p = subprogress?.start(totalCount: 3)
    p?.complete(count: 1)
    p?.withProperties {
        $0.xyz.a += 1
        $0.xyz.b += 1.0
    }

    p?.complete(count: 1)
    p?.withProperties {
        $0.xyz.a += 1
        $0.xyz.b += 1.0
    }

    p?.complete(count: 1)
    p?.withProperties {
        $0.xyz.a += 1
        $0.xyz.b += 1.0
    }
}

func f2b(_ subprogress: consuming Subprogress? = nil) async {
    let p = subprogress?.start(totalCount: 3)

    p?.complete(count: 1)
    p?.withProperties {
        $0.xyz.a += 1
        $0.xyz.b += 1.0
    }

    p?.complete(count: 1)
    p?.withProperties {
        $0.xyz.a += 1
        $0.xyz.b += 1.0
    }

    p?.complete(count: 1)
    p?.withProperties {
        $0.xyz.a += 1
        $0.xyz.b += 1.0
    }
}

func example3() async {
    // f1 and f2 both report values for "MyCustomCount". We also have a value for it ourselves.
    let p = ProgressManager(totalCount: 2)
    
    _ = await Task.detached {
        await f1b(p.subprogress(assigningCount: 1))
    }.value
    
    let v1 = p.withProperties {
        $0.xyz
    }
    print("XYZ Value is \(v1), fraction: \(p.fractionCompleted)")
    
    _ = await Task.detached {
        await f2b(p.subprogress(assigningCount: 1))
    }.value
    
    let v2 = p.withProperties {
        $0.xyz
    }
    print("XYZ Value is \(v2), fraction: \(p.fractionCompleted)")
    
    print("XYZ Values in Tree are \(p.values(of: MyXYZ.self))")
    print("Total of XYZ Values in Tree are \(MyXYZ.reduce(p.values(of: MyXYZ.self)))")
}
