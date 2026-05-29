import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: Tab = .home
    @State private var showAddExpense = false

    enum Tab { case home, spendings }

    var body: some View {
        Group {
            if selectedTab == .home {
                HomeView()
            } else {
                SpendingsView()
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            tabBar
        }
        .sheet(isPresented: $showAddExpense) { AddExpenseView() }
    }

    private var tabBar: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color.hPrimary.opacity(0.1))
                .frame(height: 1)

            HStack(spacing: 0) {
                tabButton(tab: .home, icon: "ri-home-line", activeIcon: "ri-home-2-fill")

                Button { showAddExpense = true } label: {
                    Image("ri-add-line")
                        .renderingMode(.template)
                        .foregroundStyle(.white)
                        .frame(width: 24, height: 24)
                        .padding(12)
                        .background(Color.hAccent)
                        .clipShape(Circle())
                }
                .buttonStyle(PressScaleButtonStyle())
                .frame(maxWidth: .infinity, minHeight: 56)

                tabButton(tab: .spendings, icon: "ri-bar-chart-2-line", activeIcon: "ri-bar-chart-2-line")
            }
            .frame(height: 56)
            .background(Color.hBackground)
        }
        .background(Color.hBackground)
    }

    private func tabButton(tab: Tab, icon: String, activeIcon: String) -> some View {
        Button { selectedTab = tab } label: {
            Image(selectedTab == tab ? activeIcon : icon)
                .renderingMode(.template)
                .foregroundStyle(selectedTab == tab ? Color.hPrimary : Color.hSecondary)
                .frame(width: 32, height: 32)
        }
        .buttonStyle(PressScaleButtonStyle())
        .frame(maxWidth: .infinity, minHeight: 56)
    }
}
