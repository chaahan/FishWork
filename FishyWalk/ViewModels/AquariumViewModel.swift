import SwiftUI

class AquariumViewModel: ObservableObject {
    @Published var goals: [FishGoal] = []
    @Published var healthManager = HealthStoreManager()

    private var timer: Timer?

    init() {
        loadGoals()
        if goals.isEmpty {
            setupInitialGoals()
        }

        // 定期的に判定を更新
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            self.healthManager.fetchAllData()
            self.updateFishPresence()
        }
    }

    func setupInitialGoals() {
        goals = [
            FishGoal(name: "メダカ", iconName: "fish", type: .dailySteps, appearanceThreshold: 3000, maintenanceThreshold: 2000),
            FishGoal(name: "金魚", iconName: "fish.fill", type: .dailySteps, appearanceThreshold: 10000, maintenanceThreshold: 5000),
            FishGoal(name: "カメ", iconName: "tortoise.fill", type: .averageSteps, appearanceThreshold: 7000, maintenanceThreshold: 5000),
            FishGoal(name: "熱帯魚", iconName: "leaf.fill", type: .relativeSteps, appearanceThreshold: 5000, maintenanceThreshold: 2000),
            FishGoal(name: "タツノオトシゴ", iconName: "seal.fill", type: .continuousSteps, appearanceThreshold: 5000, maintenanceThreshold: 5000, requiredDays: 3)
        ]
    }

    func loadGoals() {
        if let data = UserDefaults.standard.data(forKey: "SavedGoals"),
           let decoded = try? JSONDecoder().decode([FishGoal].self, from: data) {
            self.goals = decoded
        }
    }

    func saveGoals() {
        if let encoded = try? JSONEncoder().encode(goals) {
            UserDefaults.standard.set(encoded, forKey: "SavedGoals")
        }
    }

    func updateFishPresence() {
        objectWillChange.send()
        let currentSteps = healthManager.currentSteps
        let average = healthManager.averageSteps
        let calendar = Calendar.current
        let now = Date()

        // 昨日の日付（0時0分）
        let yesterday = calendar.startOfDay(for: calendar.date(byAdding: .day, value: -1, to: now)!)
        let yesterdaySteps = healthManager.dailyHistory[yesterday] ?? 0

        for i in 0..<goals.count {
            let goal = goals[i]

            // 1. 維持判定 (日付が変わった後の最初のチェック)
            if let lastCheck = goal.lastCheckDate {
                if !calendar.isDate(lastCheck, inSameDayAs: now) {
                    // 日付が変わったので「昨日の歩数」で維持判定
                    if goal.isPresent {
                        let maintained: Bool
                        switch goal.type {
                        case .dailySteps:
                            maintained = yesterdaySteps >= goal.maintenanceThreshold
                        case .relativeSteps:
                            // 昨日の時点での平均を取得するのは難しいので、現在の平均で代用（簡易版）
                            maintained = yesterdaySteps >= (average + goal.maintenanceThreshold)
                        case .averageSteps:
                            maintained = average >= goal.maintenanceThreshold
                        case .continuousSteps:
                            // 継続は「昨日目標達成したか」で判定
                            maintained = yesterdaySteps >= goal.maintenanceThreshold
                        }

                        if !maintained {
                            goals[i].isPresent = false
                        }
                    }
                    goals[i].lastCheckDate = now
                }
            } else {
                // 初回チェック
                goals[i].lastCheckDate = now
            }

            // 2. 出現判定 (リアルタイム)
            if !goals[i].isPresent {
                switch goal.type {
                case .dailySteps:
                    if currentSteps >= goal.appearanceThreshold {
                        goals[i].isPresent = true
                    }
                case .relativeSteps:
                    if currentSteps >= (average + goal.appearanceThreshold) {
                        goals[i].isPresent = true
                    }
                case .averageSteps:
                    if average >= goal.appearanceThreshold {
                        goals[i].isPresent = true
                    }
                case .continuousSteps:
                    // 継続判定：直近N日分（今日を含む）がすべて閾値以上か
                    let isContinuous = checkContinuous(days: goal.requiredDays, threshold: goal.appearanceThreshold)
                    if isContinuous {
                        goals[i].isPresent = true
                    }
                }
            }
        }
        saveGoals()
    }

    private func checkContinuous(days: Int, threshold: Int) -> Bool {
        let calendar = Calendar.current
        let now = Date()

        // 今日が達成しているか
        if healthManager.currentSteps < threshold { return false }

        // 過去 (days-1) 日分をチェック
        for i in 1..<days {
            let date = calendar.startOfDay(for: calendar.date(byAdding: .day, value: -i, to: now)!)
            let steps = healthManager.dailyHistory[date] ?? 0
            if steps < threshold {
                return false
            }
        }
        return true
    }
}
