import Foundation
import HealthKit

class HealthStoreManager: ObservableObject {
    let healthStore = HKHealthStore()
    @Published var currentSteps: Int = 0
    @Published var averageSteps: Int = 0
    @Published var dailyHistory: [Date: Int] = [:]

    init() {
        requestAuthorization()
    }

    func requestAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else { return }

        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!

        healthStore.requestAuthorization(toShare: [], read: [stepType]) { success, error in
            if success {
                self.fetchCurrentSteps()
                self.fetchHistory()
            }
        }
    }

    func fetchCurrentSteps() {
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)

        let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            guard let result = result, let sum = result.sumQuantity() else { return }
            DispatchQueue.main.async {
                self.currentSteps = Int(sum.doubleValue(for: HKUnit.count()))
            }
        }
        healthStore.execute(query)
    }

    func fetchHistory() {
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let calendar = Calendar.current
        let now = Date()
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: calendar.startOfDay(for: now))!

        let predicate = HKQuery.predicateForSamples(withStart: sevenDaysAgo, end: now, options: .strictStartDate)

        var interval = DateComponents()
        interval.day = 1

        let query = HKStatisticsCollectionQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum, anchorDate: sevenDaysAgo, intervalComponents: interval)

        query.initialResultsHandler = { _, results, _ in
            guard let results = results else { return }
            var history: [Date: Int] = [:]
            var total = 0
            var count = 0

            results.enumerateStatistics(from: sevenDaysAgo, to: now) { statistics, _ in
                let steps = Int(statistics.sumQuantity()?.doubleValue(for: HKUnit.count()) ?? 0)
                history[statistics.startDate] = steps
                total += steps
                count += 1
            }

            DispatchQueue.main.async {
                self.dailyHistory = history
                if count > 0 {
                    self.averageSteps = total / count
                }
            }
        }
        healthStore.execute(query)
    }
}
