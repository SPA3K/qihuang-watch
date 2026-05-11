import SwiftUI
import Charts

/// iPhone 首页 — 大屏版岐黄健康指数
struct iPhoneHomeView: View {
    @EnvironmentObject var vm: QiHuangViewModel
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 大评分环
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.12), lineWidth: 18)
                        
                        Circle()
                            .trim(from: 0, to: vm.scores.total / 100.0)
                            .stroke(
                                ringColor(for: vm.scores.total),
                                style: StrokeStyle(lineWidth: 18, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))
                            .animation(.easeInOut(duration: 1.2), value: vm.scores.total)
                        
                        VStack(spacing: 2) {
                            Text("\(Int(vm.scores.total))")
                                .font(.system(size: 56, weight: .bold, design: .rounded))
                            Text(vm.scores.healthLevel.rawValue)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(width: 200, height: 200)
                    .padding(.top, 10)
                    
                    // 体质标签
                    HStack {
                        Text(vm.constitutionType.emoji)
                            .font(.title2)
                        VStack(alignment: .leading) {
                            Text(vm.constitutionType.rawValue)
                                .font(.headline)
                            Text(vm.constitutionType.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color.orange.opacity(0.08)))
                    
                    // 五维雷达图 (用柱状图代替)
                    VStack(alignment: .leading, spacing: 10) {
                        Text("五维健康评分")
                            .font(.headline)
                        
                        HStack(alignment: .bottom, spacing: 12) {
                            DimensionBar(name: "气", value: vm.scores.qi, color: .blue)
                            DimensionBar(name: "血", value: vm.scores.blood, color: .red)
                            DimensionBar(name: "阴", value: vm.scores.yin, color: .orange)
                            DimensionBar(name: "阳", value: vm.scores.yang, color: .cyan)
                            DimensionBar(name: "神", value: vm.scores.shen, color: .purple)
                        }
                        .frame(height: 150)
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color.gray.opacity(0.05)))
                    
                    // AI 诊断
                    if let diagnosis = vm.aiDiagnosis {
                        VStack(alignment: .leading, spacing: 10) {
                            Label("AI 辨证", systemImage: "sparkles")
                                .font(.headline)
                                .foregroundColor(.purple)
                            
                            DiagnosisSection(title: "证型", content: diagnosis.syndrome)
                            DiagnosisSection(title: "病机", content: diagnosis.pathogenesis)
                            DiagnosisSection(title: "治法", content: diagnosis.treatment)
                            
                            if !diagnosis.dietaryAdvice.isEmpty {
                                Text("🍵 饮食建议").font(.subheadline).foregroundColor(.green)
                                ForEach(diagnosis.dietaryAdvice, id: \.self) { advice in
                                    Text("• \(advice)").font(.callout).foregroundColor(.secondary)
                                }
                            }
                            
                            if !diagnosis.lifestyleAdvice.isEmpty {
                                Text("🏠 生活建议").font(.subheadline).foregroundColor(.blue)
                                ForEach(diagnosis.lifestyleAdvice, id: \.self) { advice in
                                    Text("• \(advice)").font(.callout).foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 14).fill(Color.purple.opacity(0.05)))
                    } else {
                        Button(action: { Task { await vm.performAIDiagnosis() } }) {
                            HStack {
                                Image(systemName: "sparkles")
                                Text(vm.isAILoading ? "AI 辨证分析中..." : "AI 中医辨证分析")
                            }
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.purple)
                        .disabled(vm.isAILoading || vm.currentSnapshot == nil)
                    }
                    
                    // 原始数据
                    if let snapshot = vm.currentSnapshot {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("📊 健康数据").font(.headline)
                            
                            Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 8) {
                                GridRow { DataCell("静息心率", snapshot.restingHeartRate, "BPM") }
                                GridRow { DataCell("HRV SDNN", snapshot.hrvSDNN, "ms") }
                                GridRow { DataCell("HRV RMSSD", snapshot.hrvRMSSD, "ms") }
                                GridRow { DataCell("呼吸率", snapshot.respiratoryRate, "次/分") }
                                if let spo2 = snapshot.oxygenSaturation {
                                    GridRow { DataCell("血氧", spo2 * 100, "%") }
                                }
                                if let dur = snapshot.sleepDuration {
                                    GridRow { DataCell("睡眠时长", dur, "小时") }
                                }
                            }
                        }
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 14).fill(Color.gray.opacity(0.05)))
                    }
                }
                .padding()
            }
            .navigationTitle("岐黄脉镜")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { Task { await vm.performFullAnalysis() } }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
        .task {
            if vm.currentSnapshot == nil {
                await vm.requestAuthorization()
                await vm.performFullAnalysis()
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

// MARK: - 子组件

struct DimensionBar: View {
    let name: String
    let value: Double
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Spacer()
            RoundedRectangle(cornerRadius: 6)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [color.opacity(0.6), color]),
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .frame(height: value * 1.4)
            
            Text(name)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("\(Int(value))")
                .font(.caption2)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct DiagnosisSection: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(content)
                .font(.callout)
        }
    }
}

struct DataCell: View {
    let label: String
    let value: Double?
    let unit: String
    
    init(_ label: String, _ value: Double?, _ unit: String) {
        self.label = label
        self.value = value
        self.unit = unit
    }
    
    var body: some View {
        Text(label)
            .font(.callout)
            .foregroundColor(.secondary)
        if let v = value {
            Text("\(String(format: "%.1f", v)) \(unit)")
                .font(.callout)
        } else {
            Text("—")
                .foregroundColor(.secondary)
        }
    }
}
