import Foundation
import HealthKit

// MARK: - 五维评分

/// 中医五维健康评分
struct QHHScores: Codable, Equatable {
    var qi: Double        // 气 — 元气充盈度 (0-100)
    var blood: Double     // 血 — 血脉通畅 (0-100)
    var yin: Double       // 阴 — 阴液滋润 (0-100)
    var yang: Double      // 阳 — 阳气温煦 (0-100)
    var shen: Double      // 神 — 神志安宁 (0-100)
    
    /// 综合岐黄健康指数 (加权平均)
    var total: Double {
        qi * 0.30 + blood * 0.20 + yin * 0.20 + yang * 0.15 + shen * 0.15
    }
    
    /// 健康等级
    var healthLevel: HealthLevel {
        switch total {
        case 90...100: return .harmonious    // 平和质
        case 70..<90:  return .suboptimal    // 偏颇质
        case 50..<70:  return .imbalanced    // 体质偏差
        default:       return .concerning    // 需要关注
        }
    }
    
    static let empty = QHHScores(qi: 0, blood: 0, yin: 0, yang: 0, shen: 0)
}

enum HealthLevel: String, Codable, CaseIterable {
    case harmonious = "平和质"
    case suboptimal = "偏颇质"
    case imbalanced = "体质偏差"
    case concerning = "需要关注"
    
    var color: String {
        switch self {
        case .harmonious: return "#4CAF50"
        case .suboptimal: return "#FFC107"
        case .imbalanced: return "#FF9800"
        case .concerning: return "#F44336"
        }
    }
    
    var emoji: String {
        switch self {
        case .harmonious: return "🟢"
        case .suboptimal: return "🟡"
        case .imbalanced: return "🟠"
        case .concerning: return "🔴"
        }
    }
}

// MARK: - 体质类型

enum ConstitutionType: String, Codable, CaseIterable {
    case balanced = "平和质"       // 平和质
    case qiDeficient = "气虚质"    // 气虚质
    case yangDeficient = "阳虚质"  // 阳虚质
    case yinDeficient = "阴虚质"   // 阴虚质
    case phlegmDamp = "痰湿质"     // 痰湿质
    case dampHeat = "湿热质"       // 湿热质
    case bloodStasis = "血瘀质"    // 血瘀质
    case qiStagnation = "气郁质"   // 气郁质
    case special = "特禀质"        // 特禀质
    
    var description: String {
        switch self {
        case .balanced:    return "阴阳气血调和，体质平和健康"
        case .qiDeficient: return "元气不足，容易疲乏、气短"
        case .yangDeficient: return "阳气不足，畏寒怕冷、手脚冰凉"
        case .yinDeficient: return "阴液亏虚，口干舌燥、手足心热"
        case .phlegmDamp: return "痰湿凝聚，体形肥胖、腹部肥满"
        case .dampHeat:    return "湿热内蕴，面垢油光、口苦口干"
        case .bloodStasis: return "血行不畅，肤色晦暗、易生色斑"
        case .qiStagnation: return "气机郁滞，情绪抑郁、胸胁胀满"
        case .special:     return "先天禀赋特异，易过敏"
        }
    }
    
    var emoji: String {
        switch self {
        case .balanced:    return "☯️"
        case .qiDeficient: return "💨"
        case .yangDeficient: return "❄️"
        case .yinDeficient: return "🔥"
        case .phlegmDamp: return "💧"
        case .dampHeat:    return "🌡️"
        case .bloodStasis: return "🩸"
        case .qiStagnation: return "😔"
        case .special:     return "🌸"
        }
    }
}

// MARK: - 健康数据快照

/// 单次采集的原始健康数据
struct HealthDataSnapshot: Codable {
    let timestamp: Date
    
    // 心率数据
    var heartRate: Double?           // 当前心率 BPM
    var restingHeartRate: Double?    // 静息心率
    var heartRateMin: Double?
    var heartRateMax: Double?
    var heartRateSamples: [Double]?  // 时间窗口内心率采样值
    
    // HRV 数据
    var hrvSDNN: Double?             // SDNN (ms)
    var hrvRMSSD: Double?            // RMSSD (ms)
    var hrvLFHFRatio: Double?       // LF/HF 比值
    
    // 呼吸
    var respiratoryRate: Double?     // 呼吸率 (次/分)
    
    // 血氧
    var oxygenSaturation: Double?    // SpO2 (0-1)
    
    // 睡眠
    var sleepDuration: Double?       // 睡眠时长 (小时)
    var sleepDeepRatio: Double?      // 深睡比例 (0-1)
    var sleepREMRatio: Double?       // REM 比例 (0-1)
    
    // 体温 (Series 8+)
    var wristTemperature: Double?    // 腕部温度
    
    // 活动
    var activityCalories: Double?    // 活动热量
    var exerciseMinutes: Double?     // 运动分钟数
    
    /// 数据完整度 (0-1)
    var completeness: Double {
        var total = 0
        var filled = 0
        let checks: [Any?] = [heartRate, restingHeartRate, hrvRMSSD, respiratoryRate, oxygenSaturation]
        for check in checks {
            total += 1
            if check != nil { filled += 1 }
        }
        return total > 0 ? Double(filled) / Double(total) : 0
    }
}

// MARK: - 脉象分析结果

struct PulseAnalysisResult: Codable {
    let timestamp: Date
    let scores: QHHScores
    let constitutionType: ConstitutionType
    let constitutionConfidence: Double  // 0-1
    let pulseTypes: [PulseType]         // 检测到的脉象
    let aiDiagnosis: AIDiagnosis?       // AI 辨证结果
    let recommendations: [String]       // 养生建议
}

struct PulseType: Codable {
    let name: String
    let chineseName: String
    let confidence: Double      // 0-1
    let description: String
    let associatedSyndrome: String
}

struct AIDiagnosis: Codable {
    let syndrome: String        // 证型
    let pathogenesis: String    // 病机分析
    let treatment: String       // 治法
    let dietaryAdvice: [String] // 饮食建议
    let lifestyleAdvice: [String] // 生活建议
    let rawResponse: String?    // 原始 AI 响应
}

// MARK: - 日记条目 (类 WHOOP Journal)

struct DailyJournal: Codable, Identifiable {
    let id: UUID
    let date: Date
    
    // 每日行为记录 (0-5 或布尔)
    var caffeineIntake: Int       // 咖啡因摄入 (0=无, 1=1杯, 2=2杯, 3=3+)
    var alcoholIntake: Int        // 酒精摄入 (0=无, 1=少量, 2=中量, 3=过量)
    var stressLevel: Int         // 压力水平 (1-5)
    var exerciseMinutes: Int     // 运动分钟数
    var screenTimeHours: Double  // 屏幕时间
    var sleepQuality: Int        // 自评睡眠 (1-5)
    var mood: Int                // 情绪 (1=很差, 5=很好)
    var dietQuality: Int         // 饮食质量 (1-5)
    var weather: String?         // 天气
    var notes: String?           // 备注
    
    static func empty() -> DailyJournal {
        DailyJournal(
            id: UUID(),
            date: Date(),
            caffeineIntake: 0,
            alcoholIntake: 0,
            stressLevel: 3,
            exerciseMinutes: 0,
            screenTimeHours: 0,
            sleepQuality: 3,
            mood: 3,
            dietQuality: 3,
            weather: nil,
            notes: nil
        )
    }
}

// MARK: - 趋势数据

struct TrendDataPoint: Codable, Identifiable {
    let id: UUID
    let date: Date
    let scores: QHHScores
    let constitutionType: ConstitutionType
    
    init(date: Date, scores: QHHScores, constitutionType: ConstitutionType) {
        self.id = UUID()
        self.date = date
        self.scores = scores
        self.constitutionType = constitutionType
    }
}
