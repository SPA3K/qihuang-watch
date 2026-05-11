import Foundation
import SwiftUI

/// 主 ViewModel — 协调 HealthKit、评分、AI 服务
@MainActor
class QiHuangViewModel: ObservableObject {
    
    // MARK: - Published 状态
    
    @Published var currentSnapshot: HealthDataSnapshot?
    @Published var scores: QHHScores = .empty
    @Published var constitutionType: ConstitutionType = .balanced
    @Published var constitutionConfidence: Double = 0
    
    @Published var aiDiagnosis: AIDiagnosis?
    @Published var isAnalyzing: Bool = false
    @Published var isAILoading: Bool = false
    @Published var errorMessage: String?
    
    @Published var trends: [TrendDataPoint] = []
    @Published var journal: DailyJournal = .empty()
    @Published var healthAuthorized: Bool = false
    
    @Published var lastUpdate: Date?
    
    // MARK: - 服务
    
    private let healthKitService = HealthKitService()
    private let aiService = AIService.shared
    private let defaults = UserDefaults.standard
    
    // MARK: - 初始化
    
    init() {
        loadTrends()
        loadJournal()
    }
    
    // MARK: - 核心流程
    
    /// 请求 HealthKit 权限
    func requestAuthorization() async {
        do {
            try await healthKitService.requestAuthorization()
            healthAuthorized = true
        } catch {
            errorMessage = "健康数据权限获取失败: \(error.localizedDescription)"
            healthAuthorized = false
        }
    }
    
    /// 执行完整分析流程
    func performFullAnalysis() async {
        isAnalyzing = true
        errorMessage = nil
        aiDiagnosis = nil
        
        do {
            // 1. 采集健康数据
            let snapshot = try await healthKitService.fetchHealthSnapshot()
            currentSnapshot = snapshot
            
            // 2. 计算五维评分
            let newScores = ScoringEngine.calculateScores(from: snapshot)
            scores = newScores
            
            // 3. 推断体质
            let (type, confidence) = ScoringEngine.inferConstitution(scores: newScores)
            constitutionType = type
            constitutionConfidence = confidence
            
            // 4. 记录趋势
            let trendPoint = TrendDataPoint(date: Date(), scores: newScores, constitutionType: type)
            trends.append(trendPoint)
            saveTrends()
            
            lastUpdate = Date()
            isAnalyzing = false
            
        } catch {
            errorMessage = "数据采集失败: \(error.localizedDescription)"
            isAnalyzing = false
        }
    }
    
    /// 执行 AI 辨证 (需要联网)
    func performAIDiagnosis() async {
        guard let snapshot = currentSnapshot else { return }
        
        isAILoading = true
        
        do {
            let diagnosis = try await aiService.diagnose(
                snapshot: snapshot,
                scores: scores,
                constitutionType: constitutionType,
                journal: journal
            )
            aiDiagnosis = diagnosis
        } catch {
            errorMessage = "AI 分析失败: \(error.localizedDescription)"
        }
        
        isAILoading = false
    }
    
    // MARK: - 日记管理
    
    func saveJournal() {
        if let data = try? JSONEncoder().encode(journal) {
            defaults.set(data, forKey: "dailyJournal_\(dateKey(Date()))")
        }
    }
    
    private func loadJournal() {
        let key = "dailyJournal_\(dateKey(Date()))"
        if let data = defaults.data(forKey: key),
           let loaded = try? JSONDecoder().decode(DailyJournal.self, from: data) {
            journal = loaded
        }
    }
    
    // MARK: - 趋势持久化
    
    private func saveTrends() {
        // 只保留最近 90 天
        let cutoff = Calendar.current.date(byAdding: .day, value: -90, to: Date())!
        trends = trends.filter { $0.date >= cutoff }
        
        if let data = try? JSONEncoder().encode(trends) {
            defaults.set(data, forKey: "trends")
        }
    }
    
    private func loadTrends() {
        if let data = defaults.data(forKey: "trends"),
           let loaded = try? JSONDecoder().decode([TrendDataPoint].self, from: data) {
            trends = loaded
        }
    }
    
    // MARK: - 辅助
    
    private func dateKey(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        return fmt.string(from: date)
    }
}
