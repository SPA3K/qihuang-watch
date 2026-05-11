import SwiftUI

/// Watch App 入口
@main
struct QiHuangWatchApp: App {
    @StateObject private var viewModel = QiHuangViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
        }
    }
}
