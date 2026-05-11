import Foundation

/// 中医五维评分算法引擎
struct ScoringEngine {
    
    /// 从健康数据快照计算五维评分
    static func calculateScores(from snapshot: HealthDataSnapshot) -> QHHScores {
        let qi = calculateQi(snapshot: snapshot)
        let blood = calculateBlood(snapshot: snapshot)
        let yin = calculateYin(snapshot: snapshot)
        let yang = calculateYang(snapshot: snapshot)
        let shen = calculateShen(snapshot: snapshot)
        
        return QHHScores(qi: qi, blood: blood, yin: yin, yang: yang, shen: shen)
    }
    
    /// 推断体质类型
    static func inferConstitution(scores: QHHScores) -> (type: ConstitutionType, confidence: Double) {
        // 平和质：所有维度均衡且偏高
        if scores.total >= 80 && isBalanced(scores) {
            return (.balanced, 0.9)
        }
        
        // 计算各偏颇体质的匹配度
        var candidates: [(ConstitutionType, Double)] = []
        
        // 气虚质：气分低
        if scores.qi < 50 {
            candidates.append((.qiDeficient, (50 - scores.qi) / 50.0))
        }
        
        // 阳虚质：阳分低
        if scores.yang < 50 {
            candidates.append((.yangDeficient, (50 - scores.yang) / 50.0))
        }
        
        // 阴虚质：阴分低，但阳分不低 (虚火)
        if scores.yin < 50 && scores.yang >= 50 {
            candidates.append((.yinDeficient, (50 - scores.yin) / 50.0 * 0.8))
        }
        
        // 血瘀质：血分低
        if scores.blood < 50 {
            candidates.append((.bloodStasis, (50 - scores.blood) / 50.0))
        }
        
        // 气郁质：神分低 + 气分中等偏低
        if scores.shen < 50 && scores.qi < 70 {
            candidates.append((.qiStagnation, (50 - scores.shen) / 50.0 * 0.7))
        }
        
        // 痰湿质：气低 + 阳低
        if scores.qi < 60 && scores.yang < 60 {
            candidates.append((.phlegmDamp, (120 - scores.qi - scores.yang) / 120.0))
        }
        
        // 湿热质：阳偏高但阴低 (实热)
        if scores.yang > 60 && scores.yin < 50 {
            candidates.append((.dampHeat, (60 - scores.yin) / 60.0 * 0.7))
        }
        
        // 取匹配度最高的
        if let best = candidates.max(by: { $0.1 < $1.1 }), best.1 > 0.3 {
            return (best.0, min(best.1, 0.95))
        }
        
        // 默认偏颇质
        if scores.total < 70 {
            return (.balanced, 0.4) // 低分但不确定类型
        }
        
        return (.balanced, 0.6)
    }
    
    // MARK: - 五维计算 (核心算法)
    
    /// 气 (Qi) — 基于心率稳定性 + HRV + 活动量
    /// 气虚则心率快且不稳定，HRV低
    private static func calculateQi(snapshot: HealthDataSnapshot) -> Double {
        var score = 50.0  // 基准分
        
        // 1. 静息心率 (权重30%)
        if let rhr = snapshot.restingHeartRate {
            // 理想范围: 55-70 BPM
            let rhrScore: Double = {
                switch rhr {
                case 50...70: return 90 + (70 - rhr) * 0.5  // 偏低心率=气足
                case 70...80: return 70 - (rhr - 70) * 2
                case 80...100: return 40 - (rhr - 80) * 1.5
                default: return rhr < 50 ? 75 : 10 // 过低也不好
                }
            }()
            score = score * 0.3 + rhrScore * 0.7
        }
        
        // 2. HRV RMSSD (权重40%)
        if let rmssd = snapshot.hrvRMSSD {
            // RMSSD 高 = 气充盈
            let hrvScore: Double = {
                switch rmssd {
                case 0..<20: return 20      // 极低 — 气虚严重
                case 20..<40: return 40     // 偏低
                case 40..<60: return 65     // 中等
                case 60..<80: return 80     // 良好
                case 80...: return 95       // 优秀
                default: return 50
                }
            }()
            score = score * 0.4 + hrvScore * 0.6
        }
        
        // 3. 运动量修正
        if let cal = snapshot.activityCalories, cal > 200 {
            score = min(100, score + 5)  // 有运动加分
        }
        
        return max(0, min(100, score))
    }
    
    /// 血 (Blood) — 基于心率变异性一致性 + R波振幅
    /// 血瘀则心律不齐、HRV低
    private static func calculateBlood(snapshot: HealthDataSnapshot) -> Double {
        var score = 55.0
        
        // 1. 心率稳定性 — 用 HR 采样变异系数评估
        if let samples = snapshot.heartRateSamples, samples.count > 5 {
            let mean = samples.reduce(0, +) / Double(samples.count)
            let variance = samples.map { ($0 - mean) * ($0 - mean) }.reduce(0, +) / Double(samples.count)
            let cv = sqrt(variance) / max(mean, 1)
            // CV 低 = 血脉通畅
            let stabilityScore: Double = {
                switch cv {
                case 0..<0.03: return 95     // 极稳定 — 血行通畅
                case 0.03..<0.05: return 80
                case 0.05..<0.08: return 60
                case 0.08..<0.12: return 40  // 波动大
                default: return 20           // 心律不齐 — 血瘀
                }
            }()
            score = score * 0.3 + stabilityScore * 0.7
        }
        
        // 2. SDNN — 整体自主神经功能
        if let sdnn = snapshot.hrvSDNN {
            let sdnnScore: Double = {
                switch sdnn {
                case 0..<30: return 25
                case 30..<50: return 50
                case 50..<100: return 75
                case 100...: return 90
                default: return 50
                }
            }()
            score = score * 0.5 + sdnnScore * 0.5
        }
        
        // 3. 血氧修正
        if let spo2 = snapshot.oxygenSaturation {
            if spo2 >= 0.95 { score = min(100, score + 5) }
            else if spo2 < 0.90 { score = max(0, score - 15) }
        }
        
        return max(0, min(100, score))
    }
    
    /// 阴 (Yin) — 基于 HRV 自主神经平衡 + 呼吸率
    /// 阴虚则交感兴奋、呼吸快
    private static func calculateYin(snapshot: HealthDataSnapshot) -> Double {
        var score = 55.0
        
        // 1. LF/HF 比值 (交感/副交感) — 阴虚则比值高
        if let lfHf = snapshot.hrvLFHFRatio {
            let balanceScore: Double = {
                switch lfHf {
                case 0..<1.0: return 90      // 副交感主导 — 阴充
                case 1.0..<2.0: return 75    // 平衡
                case 2.0..<3.0: return 50    // 偏向交感
                case 3.0..<5.0: return 30    // 交感兴奋 — 阴虚
                default: return 15           // 严重阴虚火旺
                }
            }()
            score = balanceScore
        }
        
        // 2. 呼吸率
        if let resp = snapshot.respiratoryRate {
            let respScore: Double = {
                switch resp {
                case 12...18: return 85      // 正常范围
                case 18...22: return 55      // 偏快 — 阴虚有热
                case 22...: return 30        // 过快
                case 8..<12: return 60       // 偏慢也不好
                default: return 50
                }
            }()
            score = score * 0.6 + respScore * 0.4
        }
        
        // 3. 睡眠质量修正 (阴虚则睡眠差)
        if let duration = snapshot.sleepDuration {
            if duration >= 7 && duration <= 9 { score = min(100, score + 5) }
            else if duration < 6 { score = max(0, score - 10) }
        }
        
        return max(0, min(100, score))
    }
    
    /// 阳 (Yang) — 基于心率恢复力 + 血氧 + 活动量
    /// 阳虚则心率恢复慢、怕冷(不可测)、血氧低
    private static func calculateYang(snapshot: HealthDataSnapshot) -> Double {
        var score = 55.0
        
        // 1. 血氧饱和度 — 阳气温煦、肺气充沛
        if let spo2 = snapshot.oxygenSaturation {
            let spo2Score: Double = {
                switch spo2 {
                case 0.97...1.0: return 95   // 极佳
                case 0.95..<0.97: return 80  // 正常
                case 0.93..<0.95: return 60  // 偏低
                case 0.90..<0.93: return 35  // 阳气不足
                default: return 15           // 严重低氧
                }
            }()
            score = spo2Score
        }
        
        // 2. 活动量 — 阳气充沛则运动有力
        if let cal = snapshot.activityCalories {
            let actScore: Double = {
                switch cal {
                case 0..<100: return 30      // 久坐 — 阳气不振
                case 100..<300: return 60    // 轻度活动
                case 300..<600: return 80    // 适度运动
                case 600...: return 90       // 充分活动
                default: return 50
                }
            }()
            score = score * 0.5 + actScore * 0.5
        }
        
        // 3. 静息心率修正 (阳虚则心率偏慢但无力)
        if let rhr = snapshot.restingHeartRate {
            if rhr >= 55 && rhr <= 70 { score = min(100, score + 5) }
            else if rhr < 50 { score = max(0, score - 10) }  // 过缓可能是阳虚
        }
        
        return max(0, min(100, score))
    }
    
    /// 神 (Shen) — 基于 HRV 自主神经平衡 + 睡眠质量
    /// 神不宁则 HRV低、睡眠差、交感兴奋
    private static func calculateShen(snapshot: HealthDataSnapshot) -> Double {
        var score = 55.0
        
        // 1. 整体 HRV 水平 — 神安则自主神经平衡
        if let rmssd = snapshot.hrvRMSSD {
            let shenScore: Double = {
                switch rmssd {
                case 0..<25: return 25       // 神不守舍
                case 25..<45: return 50      // 轻度不安
                case 45..<65: return 70      // 尚可
                case 65..<85: return 85      // 神安
                case 85...: return 95        #EXTLINE# 神定气闲
                default: return 50
                }
            }()
            score = shenScore
        }
        
        // 2. 睡眠质量
        if let duration = snapshot.sleepDuration {
            let deepRatio = snapshot.sleepDeepRatio ?? 0
            let remRatio = snapshot.sleepREMRatio ?? 0
            
            let sleepScore: Double = {
                var s = 50.0
                // 时长
                if duration >= 7 && duration <= 9 { s += 20 }
                else if duration >= 6 && duration < 7 { s += 10 }
                else if duration < 6 { s -= 10 }
                else { s += 5 } // 过长也不好
                
                // 深睡
                if deepRatio >= 0.15 && deepRatio <= 0.25 { s += 15 }
                else if deepRatio > 0.25 { s += 10 }
                
                // REM
                if remRatio >= 0.20 && remRatio <= 0.30 { s += 15 }
                else if remRatio > 0.30 { s += 10 }
                
                return s
            }()
            
            score = score * 0.5 + min(100, sleepScore) * 0.5
        }
        
        // 3. 呼吸率修正 (焦虑则呼吸急促)
        if let resp = snapshot.respiratoryRate {
            if resp <= 16 { score = min(100, score + 5) }
            else if resp > 20 { score = max(0, score - 5) }
        }
        
        return max(0, min(100, score))
    }
    
    // MARK: - 辅助
    
    private static func isBalanced(_ scores: QHHScores) -> Bool {
        let values = [scores.qi, scores.blood, scores.yin, scores.yang, scores.shen]
        let mean = values.reduce(0, +) / Double(values.count)
        let maxDeviation = values.map { abs($0 - mean) }.max() ?? 0
        return maxDeviation < 15 // 各维度偏差不超过15分
    }
}
