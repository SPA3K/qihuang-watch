import SwiftUI

/// 首页 — 岐黄健康指数评分环
struct HomeView: View {
    @EnvironmentObject var vm: QiHuangViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // 健康指数圆环
                ScoreRingView(score: vm.scores.total, level: vm.scores.healthLevel)
                    .frame(width: 140, height: 140)
                    .padding(.top, 8)
                
                // 体质标签
                HStack {
                    Text(vm.constitutionType.emoji)
                    Text(vm.constitutionType.rawValue)
                        .font(.headline)
                        .foregroundColor(.primary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.orange.opacity(0.15))
                )
                
                // 五维小指标
                FiveDimensionBar(scores: vm.scores)
                    .padding(.horizontal, 4)
                
                // AI 诊断按钮 / 结果
                if let diagnosis = vm.aiDiagnosis {
                    DiagnosisCard(diagnosis: diagnosis)
                } else {
                    Button(action: {
                        Task { await vm.performAIDiagnosis() }
                    }) {
                        HStack {
                            if vm.isAILoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "sparkles")
                            }
                            Text(vm.isAILoading ? "AI 辨证中..." : "AI 辨证分析")
                        }
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(.purple)
                    .disabled(vm.isAILoading || vm.currentSnapshot == nil)
                }
                
                // 刷新按钮
                Button(action: {
                    Task { await vm.performFullAnalysis() }
                }) {
                    HStack {
                        if vm.isAnalyzing {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                        Text(vm.isAnalyzing ? "采集中..." : "刷新数据")
                    }
                    .font(.caption)
                }
                .buttonStyle(.bordered)
                .tint(.blue)
                .disabled(vm.isAnalyzing)
                
                // 最后更新时间
                if let last = vm.lastUpdate {
                    Text("更新于 \(last, style: .relative) 前")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 4)
        }
        .navigationTitle("岐黄脉镜")
        .task {
            if vm.currentSnapshot == nil {
                await vm.performFullAnalysis()
            }
        }
    }
}

// MARK: - 评分圆环

struct ScoreRingView: View {
    let score: Double
    let level: HealthLevel
    
    var body: some View {
        ZStack {
            // 背景圆环
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 12)
            
            // 评分圆环
            Circle()
                .trim(from: 0, to: score / 100.0)
                .stroke(
                    ringColor(for: score),
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 1.0), value: score)
            
            // 中心数字
            VStack(spacing: 0) {
                Text("\(Int(score))")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text(level.rawValue)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func ringColor(for score: Double) -> Color {
        switch score {
        case 90...100: return .green
        case 70..<90:  return .yellow
        case 50..<70:  return .orange
        default:       return .red
        }
    }
}

// MARK: - 五维指标条

struct FiveDimensionBar: View {
    let scores: QHHScores
    
    var body: some View {
        VStack(spacing: 6) {
            DimensionRow(name: "气", value: scores.qi, emoji: "💨", color: .blue)
            DimensionRow(name: "血", value: scores.blood, emoji: "🩸", color: .red)
            DimensionRow(name: "阴", value: scores.yin, emoji: "🔥", color: .orange)
            DimensionRow(name: "阳", value: scores.yang, emoji: "❄️", color: .cyan)
            DimensionRow(name: "神", value: scores.shen, emoji: "🧘", color: .purple)
        }
    }
}

struct DimensionRow: View {
    let name: String
    let value: Double
    let emoji: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 6) {
            Text(emoji)
                .font(.caption2)
            Text(name)
                .font(.caption2)
                .frame(width: 16, alignment: .leading)
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.gray.opacity(0.15))
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(color)
                        .frame(width: geo.size.width * value / 100.0, height: 8)
                        .animation(.easeInOut(duration: 0.8), value: value)
                }
            }
            .frame(height: 8)
            
            Text("\(Int(value))")
                .font(.system(size: 10, design: .monospaced))
                .frame(width: 24, alignment: .trailing)
        }
    }
}

// MARK: - AI 诊断卡片

struct DiagnosisCard: View {
    let diagnosis: AIDiagnosis
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.purple)
                Text(diagnosis.syndrome)
                    .font(.headline)
                    .foregroundColor(.purple)
            }
            
            Text(diagnosis.pathogenesis)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(3)
            
            if !diagnosis.dietaryAdvice.isEmpty {
                Text("🍵 " + diagnosis.dietaryAdvice[0])
                    .font(.caption2)
                    .foregroundColor(.green)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.purple.opacity(0.08))
        )
    }
}
