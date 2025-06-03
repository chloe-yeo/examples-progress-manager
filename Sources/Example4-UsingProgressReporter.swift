// Example 4: Using ProgressReporter as top-level property
import FoundationEssentials

struct Fruit {
    
    let name: String
    
    init(_ name: String) {
        self.name = name
    }
    
    func chop() async {}
}

public class Juicer {
    public var progressReporter: ProgressReporter {
        get {
            overallProgressManager.reporter
        }
    }
    
    private let overallProgressManager = ProgressManager(totalCount: 2)
    
    public func makeJuice() async {
        let choppedFruits = await chopFruits(fruits: [Fruit("Mango"), Fruit("Plums")], subprogress: overallProgressManager.subprogress(assigningCount: 1))
        
        await blendWithMilk(choppedFruits: choppedFruits, subprogress: overallProgressManager.subprogress(assigningCount: 1))
    }
    
    private func chopFruits(fruits: [Fruit], subprogress: consuming Subprogress? = nil) async -> [Fruit] {
        let progressManager = subprogress?.start(totalCount: fruits.count)
        for fruit in fruits {
            await fruit.chop()
            progressManager?.complete(count: 1)
        }
        return fruits
    }
    
    private func blendWithMilk(choppedFruits: [Fruit], subprogress: consuming Subprogress? = nil) async {
        let progressManager = subprogress?.start(totalCount: 2)
        
        await addMilk()
        progressManager?.complete(count: 1)
        
        await addChoppedFruits(choppedFruits)
        progressManager?.complete(count: 1)
    }
    
    private func addMilk() async {}
    
    private func addChoppedFruits(_ choppedFruits: [Fruit]) async {}
}


func example4() async {

    let juicer = Juicer()
    
    // We want to observer the progress of juicer
    let observedProgress = juicer.progressReporter
    
    // We want progress of juicer to be half of progress of dinner preparation
    let dinnerProgress = ProgressManager(totalCount: 2)
    dinnerProgress.assign(count: 1, to: juicer.progressReporter)
    
    // Calling make juice causes ProgressReporter of Juicer to finish
    await juicer.makeJuice()
    
    print("Juicer Progress: \(observedProgress.fractionCompleted)")
    print("Dinner Progress: \(dinnerProgress.fractionCompleted)")
}
