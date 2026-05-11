import SwiftUI

/// 主内容视图 — Tab 导航
struct ContentView: View {
    @EnvironmentObject var vm: QiHuangViewModel
    @State private var hasRequestedAuth = false
    
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("健康", systemImage: "heart.circle.fill")
                }
            
            TrendsView()
                .tabItem {
                    Label("趋势", systemImage: "chart.line.uptrend.xyaxis")
                }
            
            JournalView()
                .tabItem {
                    Label("日记", systemImage: "book.circle")
                }
            
            ProfileView()
                .tabItem {
                    Label("体质", systemImage: "person.circle")
                }
        }
        .onAppear {
            if !hasRequestedAuth {
                hasRequestedAuth = true
                Task {
                    await vm.requestAuthorization()
                }
            }
        }
    }
}
