import SwiftUI

struct AquariumView: View {
    @StateObject var viewModel = AquariumViewModel()
    @State private var showGoalList = false

    var body: some View {
        ZStack {
            // 背景：水槽（青いグラデーションと砂・泡の演出）
            ZStack {
                LinearGradient(gradient: Gradient(colors: [Color(red: 0, green: 0.5, blue: 0.8), Color(red: 0, green: 0.2, blue: 0.5)]), startPoint: .top, endPoint: .bottom)

                // 砂地
                VStack {
                    Spacer()
                    Rectangle()
                        .fill(Color(red: 0.8, green: 0.7, blue: 0.5))
                        .frame(height: 50)
                }
            }
            .ignoresSafeArea()

            // 魚たちの表示
            ForEach(viewModel.goals.filter { $0.isPresent }) { goal in
                FishView(iconName: goal.iconName, color: .orange)
            }

            // 上部UI
            VStack {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("TODAY'S STEPS")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(.white.opacity(0.8))
                        Text("\(viewModel.healthManager.currentSteps)")
                            .font(.system(size: 34, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(20)

                    Spacer()

                    Button(action: { showGoalList.toggle() }) {
                        Image(systemName: "checklist")
                            .font(.title)
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .background(Color.black.opacity(0.3))
                            .clipShape(Circle())
                    }
                }
                .padding()

                Spacer()
            }
        }
        .sheet(isPresented: $showGoalList) {
            GoalListView(viewModel: viewModel)
        }
        .onAppear {
            viewModel.updateFishPresence()
        }
    }
}

// iPad Swift Playgrounds 用のエントリポイント
struct ContentView: View {
    var body: some View {
        AquariumView()
    }
}

struct FishView: View {
    let iconName: String
    let color: Color

    @State private var position: CGPoint = CGPoint(x: 100, y: 100)
    @State private var isFacingRight: Bool = true
    @State private var swimSpeed: Double = Double.random(in: 4...8)

    let timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()

    var body: some View {
        Image(systemName: iconName)
            .resizable()
            .scaledToFit()
            .frame(width: 40, height: 40)
            .foregroundColor(color)
            .scaleEffect(x: isFacingRight ? 1 : -1, y: 1)
            .position(position)
            .animation(.easeInOut(duration: swimSpeed), value: position)
            .onAppear {
                randomizePosition()
            }
            .onReceive(timer) { _ in
                randomizePosition()
            }
    }

    func randomizePosition() {
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height

        let newX = CGFloat.random(in: 50...(screenWidth - 50))
        let newY = CGFloat.random(in: 150...(screenHeight - 150))

        isFacingRight = newX > position.x
        position = CGPoint(x: newX, y: newY)
        swimSpeed = Double.random(in: 4...8)
    }
}

struct GoalListView: View {
    @ObservedObject var viewModel: AquariumViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            List(viewModel.goals) { goal in
                HStack(spacing: 15) {
                    Image(systemName: goal.iconName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30, height: 30)
                        .foregroundColor(goal.isPresent ? .orange : .gray)

                    VStack(alignment: .leading) {
                        Text(goal.name)
                            .font(.headline)
                        Text(goalDescription(goal))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    if goal.isPresent {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    } else {
                        progressView(goal)
                    }
                }
                .padding(.vertical, 4)
            }
            .navigationTitle("目標と魚たち")
            .toolbar {
                Button("閉じる") { dismiss() }
            }
        }
    }

    func goalDescription(_ goal: FishGoal) -> String {
        switch goal.type {
        case .dailySteps:
            return "1日 \(goal.appearanceThreshold) 歩 (維持: \(goal.maintenanceThreshold)歩)"
        case .averageSteps:
            return "7日間平均 \(goal.appearanceThreshold) 歩"
        case .relativeSteps:
            return "平均 + \(goal.appearanceThreshold) 歩"
        case .continuousSteps:
            return "\(goal.requiredDays)日間連続 \(goal.appearanceThreshold) 歩"
        }
    }

    @ViewBuilder
    func progressView(_ goal: FishGoal) -> some View {
        let current = viewModel.healthManager.currentSteps
        let threshold = goal.appearanceThreshold
        let progress = min(Double(current) / Double(threshold), 1.0)

        VStack(alignment: .trailing) {
            Text("\(Int(progress * 100))%")
                .font(.caption2)
                .foregroundColor(.blue)
            ProgressView(value: progress)
                .frame(width: 50)
        }
    }
}
