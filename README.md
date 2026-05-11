# 岐黄脉镜 — Apple Watch App

> 基于 Apple Watch 健康数据的中医智能脉诊系统

## 功能特性

- 🫀 **实时健康数据采集** — 心率、HRV、呼吸率、血氧、睡眠
- ☯️ **五维健康评分** — 气·血·阴·阳·神，直观了解身体状态
- 🧬 **体质自动推断** — 基于王琦九种体质辨识理论
- 🤖 **AI 辨证论治** — 接入 DeepSeek-V4-Flash 进行中医四诊合参
- 📊 **趋势追踪** — 7/30/90 天健康数据变化
- 📓 **每日日记** — 记录压力、情绪、咖啡因、运动等行为因子

## 项目结构

```
Sources/
├── App/                          # App 入口
│   └── QiHuangWatchApp.swift
├── Models/
│   └── HealthModels.swift        # 数据模型 (五维评分、体质、快照、日记)
├── Services/
│   ├── HealthKitService.swift    # HealthKit 数据采集
│   ├── ScoringEngine.swift       # 五维评分算法
│   └── AIService.swift           # DeepSeek AI 辨证服务
├── ViewModels/
│   └── QiHuangViewModel.swift    # 主 ViewModel
├── Views/
│   ├── ContentView.swift         # Tab 导航
│   └── Screens/
│       ├── HomeView.swift        # 首页 — 评分环 + 五维条
│       ├── TrendsView.swift      # 趋势图
│       ├── JournalView.swift     # 每日日记
│       └── ProfileView.swift     # 体质分析
├── Config/
│   └── Secrets.swift             # ⚠️ API 密钥 (gitignore)
└── Resources/
    ├── Info.plist
    └── QiHuangWatch.entitlements
```

## 环境要求

- macOS + Xcode 15+
- Apple Watch Series 6+ (推荐 Series 8+ 以获取更多传感器)
- watchOS 10.0+
- Apple Developer Program 会员

## 构建步骤

```bash
# 1. 安装 xcodegen
brew install xcodegen

# 2. 生成 Xcode 项目
cd qihuang-watch
xcodegen generate

# 3. 打开项目
open QiHuangWatch.xcodeproj

# 4. 在 Xcode 中选择 Apple Watch 目标设备 → Build & Run
```

## API 配置

编辑 `Sources/Config/Secrets.swift` 填入你的硅基流动 API Key：

```swift
static let siliconFlowAPIKey = "sk-your-api-key-here"
```

## 技术栈

| 组件 | 技术 |
|------|------|
| UI 框架 | SwiftUI (watchOS 10) |
| 健康数据 | HealthKit |
| 评分算法 | 基于中医体质辨识理论的规则引擎 |
| AI 辨证 | 硅基流动 DeepSeek-V4-Flash |
| 项目生成 | xcodegen |
| 数据持久化 | UserDefaults + JSON 编码 |

## 评分体系

**岐黄健康指数 (QHHI)** = 气×0.30 + 血×0.20 + 阴×0.20 + 阳×0.15 + 神×0.15

| 评分 | 等级 | 建议 |
|------|------|------|
| 90-100 | 🟢 平和质 | 保持良好习惯 |
| 70-89 | 🟡 偏颇质 | 适当调理 |
| 50-69 | 🟠 体质偏差 | 建议咨询 |
| <50 | 🔴 需要关注 | 建议就医 |

## 隐私

- 所有健康数据仅存储在本地设备
- AI 分析仅传输匿名化生理数据，不包含个人身份信息
- API Key 仅存储在本地 Secrets.swift，已加入 .gitignore
