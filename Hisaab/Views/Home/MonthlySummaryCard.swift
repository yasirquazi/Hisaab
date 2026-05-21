import SwiftUI

struct MonthlySummaryCard: View {
    let totalSpent: Double
    let familyTransferTotal: Double
    let budget: Double?

    private var progress: Double? {
        guard let budget, budget > 0 else { return nil }
        return min(totalSpent / budget, 1.0)
    }

    private var monthLabel: String {
        Date.now.formatted(.dateTime.month(.wide).year())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 6) {
                Text(monthLabel)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(totalSpent, format: .currency(code: "INR").presentation(.narrow))
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.35, dampingFraction: 0.8), value: totalSpent)

                if let budget {
                    Text("of \(budget, format: .currency(code: "INR").presentation(.narrow)) budget")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            if let progress {
                VStack(alignment: .leading, spacing: 6) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(.tertiarySystemFill))
                                .frame(height: 6)

                            RoundedRectangle(cornerRadius: 4)
                                .fill(progress > 0.9 ? Color.red : Color.accentColor)
                                .frame(width: geo.size.width * progress, height: 6)
                                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: progress)
                        }
                    }
                    .frame(height: 6)

                    Text("\(Int(progress * 100))% of budget used")
                        .font(.caption)
                        .foregroundStyle(progress > 0.9 ? .red : .secondary)
                }
            }

            if familyTransferTotal > 0 {
                Divider()

                HStack {
                    Label("Sent home", systemImage: "house.fill")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Text(familyTransferTotal, format: .currency(code: "INR").presentation(.narrow))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                        .contentTransition(.numericText())
                }
            }
        }
        .padding(20)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}
