import SwiftUI

/// iPhone 配套 App 入口
@main
struct QiHuangiPhoneApp: App {
    @StateObject private var viewModel = QiHuangViewModel()
    
    var body: some Scene {
        WindowGroup {
            iPhoneHomeView()
                .environmentObject(viewModel)
        }
    }
}
