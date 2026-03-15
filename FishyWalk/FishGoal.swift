import Foundation

enum GoalType: String, Codable {
    case dailySteps = "Daily Steps"
    case relativeSteps = "Relative Steps" // Average + X
    case continuousSteps = "Continuous Days"
    case averageSteps = "Average Steps"
}

struct FishGoal: Identifiable, Codable {
    let id: UUID
    let name: String
    let iconName: String // SF Symbol name
    let type: GoalType

    // Requirements
    let appearanceThreshold: Int
    let maintenanceThreshold: Int
    let requiredDays: Int // For continuous goal

    var isPresent: Bool = false
    var lastCheckDate: Date?

    init(name: String, iconName: String, type: GoalType, appearanceThreshold: Int, maintenanceThreshold: Int, requiredDays: Int = 1) {
        self.id = UUID()
        self.name = name
        self.iconName = iconName
        self.type = type
        self.appearanceThreshold = appearanceThreshold
        self.maintenanceThreshold = maintenanceThreshold
        self.requiredDays = requiredDays
    }
}
