import Foundation
import HealthKit

/// HealthKit 数据采集服务
class HealthKitService: ObservableObject {
    private let healthStore = HKHealthStore()
    
    // 需要请求的读取权限
    private let readTypes: Set<HKObjectType> = {
        var types = Set<HKObjectType>()
        let typeIds: [HKQuantityTypeIdentifier] = [
            .heartRate,
            .restingHeartRate,
            .heartRateVariabilitySDNN,
            .respiratoryRate,
            .oxygenSaturation,
            .activeEnergyBurned,
            .appleExerciseTime,
            .stepCount
        ]
        for id in typeIds {
            if let t = HKQuantityType.quantityType(forIdentifier: id) {
                types.insert(t)
            }
        }
        // 睡眠分析
        if let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) {
            types.insert(sleepType)
        }
        // ECG (如可用)
        if let ecgType = HKObjectType.electrocardiogramType() {
            types.insert(ecgType)
        }
        return types
    }()
    
    /// 请求 HealthKit 授权
    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }
        try await healthStore.requestAuthorization(toShare: Set(), read: readTypes)
    }
    
    /// 采集当前健康数据快照
    func fetchHealthSnapshot() async throws -> HealthDataSnapshot {
        var snapshot = HealthDataSnapshot(timestamp: Date())
        
        async let hr = fetchLatestHeartRate()
        async let rhr = fetchRestingHeartRate()
        async let hrv = fetchHRV()
        async let resp = fetchRespiratoryRate()
        async let spo2 = fetchOxygenSaturation()
        async let hrRange = fetchHeartRateRange()
        async let sleep = fetchLastNightSleep()
        
        snapshot.heartRate = try? await hr
        snapshot.restingHeartRate = try? await rhr
        snapshot.hrvSDNN = try? await hrv.sdnn
        snapshot.hrvRMSSD = try? await hrv.rmssd
        snapshot.respiratoryRate = try? await resp
        snapshot.oxygenSaturation = try? await spo2
        snapshot.heartRateMin = try? await hrRange.min
        snapshot.heartRateMax = try? await hrRange.max
        snapshot.sleepDuration = try? await sleep.duration
        snapshot.sleepDeepRatio = try? await sleep.deepRatio
        snapshot.sleepREMRatio = try? await sleep.remRatio
        
        return snapshot
    }
    
    // MARK: - 私有采集方法
    
    private func fetchLatestHeartRate() async throws -> Double {
        let type = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        return try await withCheckedThrowingContinuation { continuation in
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
            let query = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: 0)
                    return
                }
                let unit = HKUnit.count().unitDivided(by: .minute())
                let value = sample.quantity.doubleValue(for: unit)
                continuation.resume(returning: value)
            }
            healthStore.execute(query)
        }
    }
    
    private func fetchRestingHeartRate() async throws -> Double {
        let type = HKQuantityType.quantityType(forIdentifier: .restingHeartRate)!
        return try await withCheckedThrowingContinuation { continuation in
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
            let query = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: 0)
                    return
                }
                let value = sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
                continuation.resume(returning: value)
            }
            healthStore.execute(query)
        }
    }
    
    private func fetchHRV() async throws -> (sdnn: Double?, rmssd: Double?) {
        let type = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
        let (sdnn, rmssd) = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<(Double?, Double?), Error>) in
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
            let query = HKSampleQuery(sampleType: type, predicate: nil, limit: 5, sortDescriptors: [sortDescriptor]) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let quantitySamples = samples as? [HKQuantitySample], !quantitySamples.isEmpty else {
                    continuation.resume(returning: (nil, nil))
                    return
                }
                let unit = HKUnit.secondUnit(with: .milli)
                let values = quantitySamples.map { $0.quantity.doubleValue(for: unit) }
                let sdnn = values.reduce(0, +) / Double(values.count)
                // 近似估算 RMSSD ≈ SDNN * 0.8 (简化模型)
                let rmssd = sdnn * 0.8
                continuation.resume(returning: (sdnn, rmssd))
            }
            healthStore.execute(query)
        }
        return (sdnn, rmssd)
    }
    
    private func fetchRespiratoryRate() async throws -> Double {
        let type = HKQuantityType.quantityType(forIdentifier: .respiratoryRate)!
        return try await withCheckedThrowingContinuation { continuation in
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
            let query = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: 0)
                    return
                }
                let value = sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
                continuation.resume(returning: value)
            }
            healthStore.execute(query)
        }
    }
    
    private func fetchOxygenSaturation() async throws -> Double {
        let type = HKQuantityType.quantityType(forIdentifier: .oxygenSaturation)!
        return try await withCheckedThrowingContinuation { continuation in
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
            let query = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: 0)
                    return
                }
                let value = sample.quantity.doubleValue(for: HKUnit.percent())
                continuation.resume(returning: value / 100.0)
            }
            healthStore.execute(query)
        }
    }
    
    private func fetchHeartRateRange() async throws -> (min: Double, max: Double) {
        let type = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let now = Date()
        let start = Calendar.current.date(byAdding: .hour, value: -24, to: now)!
        let predicate = HKQuery.predicateForSamples(withStart: start, end: now, options: .strictStartDate)
        
        return try await withCheckedThrowingContinuation { continuation in
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
            let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let quantitySamples = samples as? [HKQuantitySample], !quantitySamples.isEmpty else {
                    continuation.resume(returning: (0, 0))
                    return
                }
                let unit = HKUnit.count().unitDivided(by: .minute())
                let values = quantitySamples.map { $0.quantity.doubleValue(for: unit) }
                let min = values.min() ?? 0
                let max = values.max() ?? 0
                continuation.resume(returning: (min, max))
            }
            healthStore.execute(query)
        }
    }
    
    private func fetchLastNightSleep() async throws -> (duration: Double, deepRatio: Double, remRatio: Double) {
        let type = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis)!
        let now = Date()
        let start = Calendar.current.date(byAdding: .day, value: -1, to: Calendar.current.startOfDay(for: now))!
        let predicate = HKQuery.predicateForSamples(withStart: start, end: now, options: .strictStartDate)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let sleepSamples = samples as? [HKCategorySample], !sleepSamples.isEmpty else {
                    continuation.resume(returning: (0, 0, 0))
                    return
                }
                
                var totalSeconds: TimeInterval = 0
                var deepSeconds: TimeInterval = 0
                var remSeconds: TimeInterval = 0
                
                for sample in sleepSamples {
                    let duration = sample.endDate.timeIntervalSince(sample.startDate)
                    totalSeconds += duration
                    
                    if #available(watchOS 10.0, *) {
                        switch sample.value {
                        case HKCategoryValueSleepAnalysis.asleepDeep.rawValue:
                            deepSeconds += duration
                        case HKCategoryValueSleepAnalysis.asleepREM.rawValue:
                            remSeconds += duration
                        default:
                            break
                        }
                    } else {
                        switch sample.value {
                        case HKCategoryValueSleepAnalysis.asleepDeep.rawValue:
                            deepSeconds += duration
                        case HKCategoryValueSleepAnalysis.asleepREM.rawValue:
                            remSeconds += duration
                        default:
                            break
                        }
                    }
                }
                
                let hours = totalSeconds / 3600.0
                let deepRatio = totalSeconds > 0 ? deepSeconds / totalSeconds : 0
                let remRatio = totalSeconds > 0 ? remSeconds / totalSeconds : 0
                
                continuation.resume(returning: (hours, deepRatio, remRatio))
            }
            healthStore.execute(query)
        }
    }
}

enum HealthKitError: LocalizedError {
    case notAvailable
    case authorizationDenied
    
    var errorDescription: String? {
        switch self {
        case .notAvailable: return "此设备不支持 HealthKit"
        case .authorizationDenied: return "健康数据访问权限被拒绝"
        }
    }
}
