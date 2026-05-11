import Foundation

/// 硅基流动 DeepSeek-V4-Flash AI 辨证服务
class AIService {
    
    static let shared = AIService()
    
    private let session: URLSession
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 120
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - AI 辨证
    
    /// 调用 DeepSeek 进行四诊合参辨证
    func diagnose(snapshot: HealthDataSnapshot,
                  scores: QHHScores,
                  constitutionType: ConstitutionType,
                  journal: DailyJournal? = nil) async throws -> AIDiagnosis {
        
        let prompt = buildPrompt(snapshot: snapshot, scores: scores,
                                 constitutionType: constitutionType, journal: journal)
        
        let response = try await callLLM(systemPrompt: systemPrompt, userPrompt: prompt)
        
        return parseDiagnosis(from: response)
    }
    
    // MARK: - LLM 调用
    
    private func callLLM(systemPrompt: String, userPrompt: String) async throws -> String {
        let url = URL(string: "\(Secrets.siliconFlowBaseURL)/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(Secrets.siliconFlowAPIKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "model": Secrets.aiModel,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": userPrompt]
            ],
            "max_tokens": 2048,
            "temperature": 0.3
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIServiceError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown"
            throw AIServiceError.apiError(statusCode: httpResponse.statusCode, message: errorBody)
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let first = choices.first,
              let message = first["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw AIServiceError.parseError
        }
        
        return content
    }
    
    // MARK: - Prompt 构建
    
    private var systemPrompt: String {
        """
        你是「岐黄脉镜」AI 中医健康顾问，精通中医脉学、体质辨识和养生指导。
        
        你的职责：
        1. 根据 Apple Watch 采集的生理数据进行中医四诊合参
        2. 判断用户当前的中医证型
        3. 给出病机分析
        4. 提供个性化的饮食、起居、运动建议
        
        输出要求（严格 JSON 格式）：
        {
          "syndrome": "证型名称（如：肝郁气滞、心脾两虚等）",
          "pathogenesis": "简要病机分析（2-3句话）",
          "treatment": "治法（如：疏肝理气、养心安神等）",
          "dietaryAdvice": ["建议1", "建议2", "建议3"],
          "lifestyleAdvice": ["建议1", "建议2", "建议3"]
        }
        
        注意：
        - 基于数据客观分析，不要危言耸听
        - 建议要具体可执行，避免空泛
        - 如有异常指标，提醒用户咨询医生
        """
    }
    
    private func buildPrompt(snapshot: HealthDataSnapshot,
                             scores: QHHScores,
                             constitutionType: ConstitutionType,
                             journal: DailyJournal?) -> String {
        var parts: [String] = []
        
        parts.append("## 生理数据")
        parts.append("- 静息心率: \(snapshot.restingHeartRate.map { String(format: "%.0f", $0) } ?? "未知") BPM")
        parts.append("- HRV SDNN: \(snapshot.hrvSDNN.map { String(format: "%.1f", $0) } ?? "未知") ms")
        parts.append("- HRV RMSSD: \(snapshot.hrvRMSSD.map { String(format: "%.1f", $0) } ?? "未知") ms")
        parts.append("- 呼吸率: \(snapshot.respiratoryRate.map { String(format: "%.1f", $0) } ?? "未知") 次/分")
        parts.append("- 血氧: \(snapshot.oxygenSaturation.map { String(format: "%.1f", $0 * 100) } ?? "未知")%")
        
        if let hrMin = snapshot.heartRateMin, let hrMax = snapshot.heartRateMax {
            parts.append("- 24h心率范围: \(String(format: "%.0f", hrMin))-\(String(format: "%.0f", hrMax)) BPM")
        }
        
        if let duration = snapshot.sleepDuration {
            parts.append("- 昨晚睡眠: \(String(format: "%.1f", duration)) 小时")
        }
        if let deep = snapshot.sleepDeepRatio {
            parts.append("- 深睡比例: \(String(format: "%.0f", deep * 100))%")
        }
        
        parts.append("")
        parts.append("## 岐黄健康指数")
        parts.append("- 气: \(String(format: "%.0f", scores.qi))/100")
        parts.append("- 血: \(String(format: "%.0f", scores.blood))/100")
        parts.append("- 阴: \(String(format: "%.0f", scores.yin))/100")
        parts.append("- 阳: \(String(format: "%.0f", scores.yang))/100")
        parts.append("- 神: \(String(format: "%.0f", scores.shen))/100")
        parts.append("- 综合: \(String(format: "%.0f", scores.total))/100")
        parts.append("- 体质倾向: \(constitutionType.rawValue)")
        
        if let journal = journal {
            parts.append("")
            parts.append("## 今日行为")
            parts.append("- 压力: \(journal.stressLevel)/5")
            parts.append("- 咖啡因: \(journal.caffeineIntake) 杯")
            parts.append("- 运动: \(journal.exerciseMinutes) 分钟")
            parts.append("- 自评情绪: \(journal.mood)/5")
            parts.append("- 自评睡眠: \(journal.sleepQuality)/5")
            if let notes = journal.notes, !notes.isEmpty {
                parts.append("- 备注: \(notes)")
            }
        }
        
        parts.append("")
        parts.append("请根据以上数据进行中医辨证分析，返回严格 JSON 格式。")
        
        return parts.joined(separator: "\n")
    }
    
    // MARK: - 解析
    
    private func parseDiagnosis(from response: String) -> AIDiagnosis {
        // 尝试提取 JSON
        if let data = response.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            return AIDiagnosis(
                syndrome: json["syndrome"] as? String ?? "待分析",
                pathogenesis: json["pathogenesis"] as? String ?? "数据不足，建议补充更多生理指标后分析",
                treatment: json["treatment"] as? String ?? "调和阴阳",
                dietaryAdvice: json["dietaryAdvice"] as? [String] ?? ["饮食均衡", "少食辛辣"],
                lifestyleAdvice: json["lifestyleAdvice"] as? [String] ?? ["规律作息", "适度运动"],
                rawResponse: response
            )
        }
        
        // 降级：无法解析 JSON，返回原始文本
        return AIDiagnosis(
            syndrome: "待分析",
            pathogenesis: response.isEmpty ? "网络连接异常，请稍后重试" : String(response.prefix(200)),
            treatment: "建议保持良好的生活习惯",
            dietaryAdvice: ["饮食均衡", "多食蔬果", "少食油腻辛辣"],
            lifestyleAdvice: ["规律作息", "适度运动", "保持心情舒畅"],
            rawResponse: response
        )
    }
}

// MARK: - 错误

enum AIServiceError: LocalizedError {
    case invalidResponse
    case apiError(statusCode: Int, message: String)
    case parseError
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse: return "无效的网络响应"
        case .apiError(let code, let msg): return "API 错误 (\(code)): \(msg)"
        case .parseError: return "AI 响应解析失败"
        }
    }
}
