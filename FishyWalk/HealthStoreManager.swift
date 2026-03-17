import Foundation
import HealthKit

class HealthStoreManager: ObservableObject {
    let healthStore = HKHealthStore()

    @Published var currentSteps: Int = 0
    @Published var averageSteps: Int = 0
    @Published var dailyHistory: [Date: Int] = [:]

    // 診断用プロパティ
    @Published var isHealthAvailable: Bool = false
    @Published var authStatus: String = "未確認"
    @Published var lastError: String = ""
    @Published var useMockData: Bool = false

    init() {
        checkAvailability()
    }

    func checkAvailability() {
        isHealthAvailable = HKHealthStore.isHealthDataAvailable()
        if !isHealthAvailable {
            lastError = "このデバイスではHealthKitが利用できません。"
            useMockData = true // 利用不可なら自動的にモックモードへ
        }
    }

    func requestAuthorization() {
        guard isHealthAvailable else { return }

        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!

        authStatus = "リクエスト中..."

        healthStore.requestAuthorization(toShare: [], read: [stepType]) { success, error in
            DispatchQueue.main.async {
                if success {
                    self.authStatus = "許可済み"
                    self.fetchAllData()
                } else {
                    self.authStatus = "拒否またはエラー"
                    self.lastError = error?.localizedDescription ?? "不明なエラー"
                    self.useMockData = true
                }
            }
        }
    }

    func fetchAllData() {
        if useMockData {
            generateMockData()
            return
        }
        fetchCurrentSteps()
        fetchHistory()
    }

    func fetchCurrentSteps() {
        guard isHealthAvailable else { return }
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
        guard isHealthAvailable else { return }
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let calendar = Calendar.current
        let now = Date()
        let endOfYesterday = calendar.startOfDay(for: now)
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: endOfYesterday)!

        let predicate = HKQuery.predicateForSamples(withStart: sevenDaysAgo, end: endOfYesterday, options: .strictStartDate)

        var interval = DateComponents()
        interval.day = 1

        let query = HKStatisticsCollectionQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum, anchorDate: sevenDaysAgo, intervalComponents: interval)

        query.initialResultsHandler = { _, results, _ in
            guard let results = results else { return }
            var history: [Date: Int] = [:]
            var total = 0
            var count = 0

            results.enumerateStatistics(from: sevenDaysAgo, to: endOfYesterday) { statistics, _ in
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

    // --- モックデータ用 ---

    func generateMockData() {
        // 開発・テスト用にダミーデータを生成
        self.currentSteps = 4500

        let calendar = Calendar.current
        let now = Date()
        var history: [Date: Int] = [:]
        var total = 0

        for i in 1...7 {
            let date = calendar.startOfDay(for: calendar.date(byAdding: .day, value: -i, to: now)!)
            let steps = Int.random(in: 3000...8000)
            history[date] = steps
            total += steps
        }

        self.dailyHistory = history
        self.averageSteps = total / 7
    }

    func setManualSteps(_ steps: Int) {
        self.currentSteps = steps
    }
}
