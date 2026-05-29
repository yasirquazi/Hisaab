import SwiftUI

struct MetricInputSheet: View {
    let title: String
    let current: Double
    let onSave: (Double) -> Void

    @State private var amountText: String = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Drag handle
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.hBorder)
                .frame(width: 40, height: 5)
                .frame(maxWidth: .infinity)
                .padding(.top, 12)
                .padding(.bottom, 28)

            Text(title)
                .font(HisaabTheme.mono(22, weight: .bold))
                .foregroundStyle(Color.hPrimary)
                .padding(.bottom, 6)

            if current > 0 {
                Text("Currently \(current, format: .currency(code: "INR").presentation(.narrow))")
                    .font(HisaabTheme.mono(13))
                    .foregroundStyle(Color.hSecondary)
                    .padding(.bottom, 28)
            } else {
                Spacer().frame(height: 28)
            }

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("₹")
                    .font(HisaabTheme.mono(36, weight: .bold))
                    .foregroundStyle(Color.hPrimary)
                TextField("0", text: $amountText)
                    .font(HisaabTheme.mono(36, weight: .bold))
                    .foregroundStyle(Color.hPrimary)
                    .keyboardType(.numberPad)
                    .tint(Color.hAccent)
            }
            .padding(.bottom, 32)

            Button {
                let cleaned = amountText.replacingOccurrences(of: ",", with: "")
                if let value = Double(cleaned), value >= 0 {
                    onSave(value)
                }
                dismiss()
            } label: {
                Text("Save")
                    .font(HisaabTheme.mono(16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.hPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(PressScaleButtonStyle())

            Spacer()
        }
        .padding(.horizontal, 24)
        .background(Color.hBackground.ignoresSafeArea())
        .presentationDetents([.medium])
        .presentationDragIndicator(.hidden)
        .presentationBackground(Color.hBackground)
        .onAppear {
            if current > 0 { amountText = String(Int(current)) }
        }
    }
}
