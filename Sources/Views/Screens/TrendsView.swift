import SwiftUI

/// 趋势页 — 7/30/90 天评分变化
struct TrendsView: View {
    @EnvironmentObject var vm: QiHuangViewModel
    @State private var selectedPeriod: TimePeriod = .week
    
    enum TimePeriod: String, CaseIterable {
        case week = "7天"
        case month = "30天"
        case quarter = "90天"
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // 时间段选择
                Picker("时间", selection: $selectedPeriod) {
                    ForEach(TimePeriod.allCases, id: \.self) { period in
                        Text(period.rawValue).tag(period)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 4)
                
                // 趋势折线图 (简化版)
                if filteredTrends.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "chart.line.downtrend.xyaxis")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text("暂无趋势数据")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("每次分析后数据将在此显示")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                } else {
                    // 评分趋势
                    TrendChartView(
                        dataPoints: filteredTrends,
                        valuePath: \.scores.total,
                        color: .orange,
                        title: "岐黄健康指数"
                    )
                    
                    // 五维分项趋势
                    TrendChartView(
                        dataPoints: filteredTrends,
                        valuePath: \.scores.qi,
                        color: .blue,
                        title: "气 (Qi)"
                    )
                    
                    TrendChartView(
                        dataPoints: filteredTrends,
                        valuePath: \.scores.shen,
                        color: .purple,
                        title: "神 (Shen)"
                    )
                    
                    // 体质变化
                    if filteredTrends.count > 1 {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("体质变化")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            ForEach(filteredTrends.suffix(5)) { point in
                                HStack {
                                    Text(point.date, style: .date)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(point.constitutionType.emoji)
                                    Text(point.constitutionType.rawValue)
                                        .font(.caption2)
                                }
                            }
                        }
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.gray.opacity(0.1))
                        )
                    }
                }
            }
            .padding(.horizontal, 4)
        }
        .navigationTitle("趋势")
    }
    
    private var filteredTrends: [TrendDataPoint] {
        let calendar = Calendar.current
        let cutoff: Date
        switch selectedPeriod {
        case .week:    cutoff = calendar.date(byAdding: .day, value: -7, to: Date())!
        case .month:   cutoff = calendar.date(byAdding: .day, value: -30, to: Date())!
        case .quarter: cutoff = calendar.date(byAdding: .day, value: -90, to: Date())!
        }
        return vm.trends.filter { $0.date >= cutoff }
    }
}

// MARK: - 简易趋势图

struct TrendChartView: View {
    let dataPoints: [TrendDataPoint]
    let valuePath: KeyPath<TrendDataPoint, Double>
    let color: Color
    let title: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(Int(dataPoints.last?.scores.total ?? 0))")
                    .font(.caption)
                    .foregroundColor(color)
            }
            
            // 简化的柱状图
            HStack(alignment: .bottom, spacing: 2) {
                ForEach(dataPoints.suffix(20)) { point in
                    let value = point[keyPath: valuePath]
                    RoundedRectangle(cornerRadius: 2)
                        .fill(value >= 70 ? color : value >= 50 ? color.opacity(0.6) : .red.opacity(0.6))
                        .frame(height: max(4, value * 1.2))
                        .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 60)
            
            // 最小/最大
            HStack {
                Text("最低 \(Int(dataPoints.map { $0[keyPath: valuePath] }.min() ?? 0))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
                Text("最高 \(Int(dataPoints.map { $0[keyPath: valuePath] }.max() ?? 0))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.gray.opacity(0.1))
        )
    }
}
