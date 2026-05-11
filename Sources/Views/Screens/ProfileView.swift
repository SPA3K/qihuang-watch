import SwiftUI

/// 体质分析页
struct ProfileView: View {
    @EnvironmentObject var vm: QiHuangViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // 体质类型卡片
                VStack(spacing: 6) {
                    Text(vm.constitutionType.emoji)
                        .font(.system(size: 40))
                    
                    Text(vm.constitutionType.rawValue)
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    Text(vm.constitutionType.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    // 置信度
                    HStack(spacing: 4) {
                        Text("置信度")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        ProgressView(value: vm.constitutionConfidence)
                            .frame(width: 60)
                        Text("\(Int(vm.constitutionConfidence * 100))%")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.orange.opacity(0.08))
                )
                
                // 详细 AI 建议
                if let diagnosis = vm.aiDiagnosis {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("AI 辨证", systemImage: "sparkles")
                            .font(.caption)
                            .foregroundColor(.purple)
                        
                        DiagnosisRow(label: "证型", value: diagnosis.syndrome)
                        DiagnosisRow(label: "治法", value: diagnosis.treatment)
                        
                        Divider()
                        
                        Text("📋 饮食建议")
                            .font(.caption2)
                            .foregroundColor(.green)
                        ForEach(diagnosis.dietaryAdvice, id: \.self) { advice in
                            Text("• \(advice)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        Divider()
                        
                        Text("🏠 生活建议")
                            .font(.caption2)
                            .foregroundColor(.blue)
                        ForEach(diagnosis.lifestyleAdvice, id: \.self) { advice in
                            Text("• \(advice)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.08))
                    )
                }
                
                // 健康数据摘要
                if let snapshot = vm.currentSnapshot {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("📊 原始数据")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        DataRow(label: "静息心率", value: snapshot.restingHeartRate, unit: "BPM")
                        DataRow(label: "HRV SDNN", value: snapshot.hrvSDNN, unit: "ms")
                        DataRow(label: "HRV RMSSD", value: snapshot.hrvRMSSD, unit: "ms")
                        DataRow(label: "呼吸率", value: snapshot.respiratoryRate, unit: "次/分")
                        if let spo2 = snapshot.oxygenSaturation {
                            DataRow(label: "血氧", value: spo2 * 100, unit: "%")
                        }
                        DataRow(label: "数据完整度", value: snapshot.completeness * 100, unit: "%")
                    }
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.08))
                    )
                }
            }
            .padding(.horizontal, 4)
        }
        .navigationTitle("体质")
    }
}

struct DiagnosisRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
                .frame(width: 32, alignment: .leading)
            Text(value)
                .font(.caption2)
        }
    }
}

struct DataRow: View {
    let label: String
    let value: Double?
    let unit: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
            Spacer()
            if let v = value {
                Text("\(String(format: "%.1f", v)) \(unit)")
                    .font(.caption2)
                    .foregroundColor(.primary)
            } else {
                Text("未知")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}
