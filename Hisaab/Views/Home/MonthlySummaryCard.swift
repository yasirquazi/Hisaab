import SwiftUI

struct MonthlySummaryCard: View {
    let totalSpent: Double
    let budget: Double?

    private var progress: Double? {
        guard let budget, budget > 0 else { return nil }
        return min(totalSpent / budget, 1.0)
    }

    private var monthLabel: String {
        Date.now.formatted(.dateTime.month(.wide).year())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: HisaabTheme.Layout.itemGap) {
            VStack(alignment: .leading, spacing: 6) {
                Text(monthLabel.uppercased())
                    .font(HisaabTheme.mono(HisaabTheme.FontSize.small, weight: .medium))
                    .foregroundStyle(Color.hSecondary)
                    .tracking(0.8)

                Text(totalSpent, format: .currency(code: "INR").presentation(.narrow))
                    .font(HisaabTheme.mono(HisaabTheme.FontSize.hero, weight: .bold))
                    .foregroundStyle(Color.hPrimary)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.35, dampingFraction: 0.8), value: totalSpent)

                if let budget {
                    Text("of \(budget, format: .currency(code: "INR").presentation(.narrow)) budget")
                        .font(HisaabTheme.mono(HisaabTheme.FontSize.body))
                        .foregroundStyle(Color.hSecondary)
                }
            }

            if let progress {
                VStack(alignment: .leading, spacing: 6) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.hBorder)
                                .frame(height: 6)
                            Rectangle()
                                .fill(progress > 0.9 ? Color.red : Color.hAccent)
                                .frame(width: geo.size.width * progress, height: 6)
                                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: progress)
                        }
                    }
                    .frame(height: 6)

                    Text("\(Int(progress * 100))% of budget used")
                        .font(HisaabTheme.mono(HisaabTheme.FontSize.caption))
                        .foregroundStyle(progress > 0.9 ? .red : Color.hSecondary)
                }
            }
        }
        .padding(HisaabTheme.Layout.cardPadding)
        .hOutline()
    }
}
