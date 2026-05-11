import SwiftUI

/// 每日日记页 — 类 WHOOP Journal
struct JournalView: View {
    @EnvironmentObject var vm: QiHuangViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                Text("今日状态")
                    .font(.headline)
                    .padding(.top, 4)
                
                // 压力
                StepperRow(
                    title: "压力",
                    value: $vm.journal.stressLevel,
                    range: 1...5,
                    emoji: "😤",
                    labels: ["很低", "低", "中", "高", "很高"]
                )
                
                // 情绪
                StepperRow(
                    title: "情绪",
                    value: $vm.journal.mood,
                    range: 1...5,
                    emoji: "😊",
                    labels: ["很差", "不好", "一般", "好", "很好"]
                )
                
                // 咖啡因
                StepperRow(
                    title: "咖啡",
                    value: $vm.journal.caffeineIntake,
                    range: 0...3,
                    emoji: "☕",
                    labels: ["无", "1杯", "2杯", "3+"]
                )
                
                // 酒精
                StepperRow(
                    title: "饮酒",
                    value: $vm.journal.alcoholIntake,
                    range: 0...3,
                    emoji: "🍷",
                    labels: ["无", "少量", "中量", "过量"]
                )
                
                // 运动
                StepperRow(
                    title: "运动",
                    value: $vm.journal.exerciseMinutes,
                    range: 0...180,
                    step: 15,
                    emoji: "🏃",
                    labels: nil
                )
                
                // 自评睡眠
                StepperRow(
                    title: "睡眠",
                    value: $vm.journal.sleepQuality,
                    range: 1...5,
                    emoji: "😴",
                    labels: ["很差", "不好", "一般", "好", "很好"]
                )
                
                // 饮食质量
                StepperRow(
                    title: "饮食",
                    value: $vm.journal.dietQuality,
                    range: 1...5,
                    emoji: "🥗",
                    labels: ["很差", "不好", "一般", "好", "很好"]
                )
                
                // 保存按钮
                Button("保存日记") {
                    vm.saveJournal()
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .padding(.top, 4)
            }
            .padding(.horizontal, 4)
        }
        .navigationTitle("日记")
    }
}

// MARK: - 自定义 Stepper 行

struct StepperRow: View {
    let title: String
    @Binding var value: Int
    let range: Range<Int>
    let emoji: String
    let labels: [String]?
    var step: Int = 1
    
    var body: some View {
        HStack(spacing: 6) {
            Text(emoji)
                .font(.caption)
            
            Text(title)
                .font(.caption)
                .frame(width: 32, alignment: .leading)
            
            Button(action: { if value > range.lowerBound { value -= step } }) {
                Image(systemName: "minus.circle.fill")
                    .foregroundColor(.gray)
            }
            .buttonStyle(.plain)
            
            if let labels = labels, value < labels.count {
                Text(labels[value])
                    .font(.caption2)
                    .frame(width: 36)
            } else {
                Text("\(value)")
                    .font(.caption)
                    .frame(width: 36)
            }
            
            Button(action: { if value < range.upperBound - 1 { value += step } }) {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(.blue)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 2)
    }
}
