import SwiftUI
import Charts
import SwiftData

// MARK: - Spendings Tab

struct SpendingsView: View {
    @Query(sort: \Expense.date, order: .reverse) private var allExpenses: [Expense]
    @Query(sort: \ExpenseCategory.sortOrder) private var categories: [ExpenseCategory]

    @State private var showFilter = false
    @State private var sortOrder: SortOrder = .newest
    @State private var selectedCategory: String?
    @State private var period: Period = .thisMonth
    @State private var selectedSource: ExpenseSource?

    enum SortOrder: String, CaseIterable, Hashable {
        case newest    = "Newest"
        case oldest    = "Oldest"
        case highToLow = "Highest"
        case lowToHigh = "Lowest"
    }

    enum Period: String, CaseIterable, Hashable {
        case thisMonth   = "This Month"
        case lastMonth   = "Last Month"
        case last3Months = "3 Months"
        case allTime     = "All Time"
    }

    // MARK: - Filtered & sorted data

    private var filtered: [Expense] {
        let calendar = Calendar.current
        let now = Date.now
        var base = allExpenses

        switch period {
        case .thisMonth:
            base = base.filter { calendar.isDate($0.date, equalTo: now, toGranularity: .month) }
        case .lastMonth:
            if let last = calendar.date(byAdding: .month, value: -1, to: now) {
                base = base.filter { calendar.isDate($0.date, equalTo: last, toGranularity: .month) }
            }
        case .last3Months:
            if let cutoff = calendar.date(byAdding: .month, value: -3, to: now) {
                base = base.filter { $0.date >= cutoff }
            }
        case .allTime:
            break
        }

        if let cat = selectedCategory { base = base.filter { $0.category == cat } }
        if let src = selectedSource   { base = base.filter { $0.source == src } }

        switch sortOrder {
        case .newest:    return base.sorted { $0.date > $1.date }
        case .oldest:    return base.sorted { $0.date < $1.date }
        case .highToLow: return base.sorted { $0.amount > $1.amount }
        case .lowToHigh: return base.sorted { $0.amount < $1.amount }
        }
    }

    private var categoryTotals: [CategoryBreakdownChart.CategoryTotal] {
        var buckets: [String: Double] = [:]
        for e in filtered { buckets[e.category, default: 0] += e.amount }
        return buckets
            .map { name, amount in
                let emoji = ExpenseCategory.defaults.first { $0.name == name }?.emoji ?? "💸"
                return CategoryBreakdownChart.CategoryTotal(
                    name: name, emoji: emoji, total: amount,
                    color: CategoryBreakdownChart.color(for: name)
                )
            }
            .sorted { $0.total > $1.total }
    }

    private var totalSpent: Double { filtered.reduce(0) { $0 + $1.amount } }

    private var hasActiveFilters: Bool {
        selectedCategory != nil || selectedSource != nil || period != .thisMonth
    }

    // Day-grouped (used when sorting by date)
    private var dayGroups: [(label: String, items: [Expense])] {
        let calendar = Calendar.current
        var buckets: [String: [Expense]] = [:]
        var order: [String] = []
        for expense in filtered {
            let label = dayLabel(for: expense.date, calendar: calendar)
            if buckets[label] == nil { order.append(label) }
            buckets[label, default: []].append(expense)
        }
        return order.map { (label: $0, items: buckets[$0]!) }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    chartCard
                    filterRow
                    expenseList
                }
                .padding(16)
                .padding(.bottom, 24)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Spendings")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showFilter) {
                SpendingsFilterSheet(
                    sortOrder: $sortOrder,
                    selectedCategory: $selectedCategory,
                    period: $period,
                    selectedSource: $selectedSource,
                    categories: categories
                )
            }
        }
    }

    // MARK: - Chart card

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(period.rawValue)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(totalSpent, format: .currency(code: "INR").presentation(.narrow))
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.35, dampingFraction: 0.8), value: totalSpent)
            }

            if categoryTotals.isEmpty {
                Text("No expenses for this period")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 24)
            } else {
                Chart(categoryTotals) { item in
                    BarMark(
                        x: .value("Category", item.emoji),
                        y: .value("Amount", item.total)
                    )
                    .foregroundStyle(item.color)
                    .cornerRadius(8)
                    .annotation(position: .top, alignment: .center) {
                        Text(item.total, format: .currency(code: "INR").presentation(.narrow))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .chartYAxis(.hidden)
                .chartXAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            Text(value.as(String.self) ?? "").font(.title3)
                        }
                    }
                }
                .frame(height: 180)
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: categoryTotals.map(\.total))
            }
        }
        .padding(20)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - Filter row

    private var filterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Filter pill
                Button { showFilter = true } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "line.3.horizontal.decrease")
                            .font(.subheadline)
                        Text("Filter")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        if hasActiveFilters {
                            Circle()
                                .fill(Color.accentColor)
                                .frame(width: 6, height: 6)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .foregroundStyle(.primary)
                    .overlay(Capsule().stroke(Color(.separator), lineWidth: 1))
                }
                .buttonStyle(PressScaleButtonStyle())

                // Active filter chips (tap to dismiss)
                if period != .thisMonth {
                    activeChip(period.rawValue) { period = .thisMonth }
                }
                if let cat = selectedCategory {
                    activeChip(cat) { selectedCategory = nil }
                }
                if let src = selectedSource {
                    activeChip(src == .gmail ? "Auto-import" : src.rawValue.capitalized) { selectedSource = nil }
                }
                if sortOrder != .newest {
                    activeChip(sortOrder.rawValue) { sortOrder = .newest }
                }
            }
            .padding(.horizontal, 2)
        }
    }

    private func activeChip(_ label: String, onRemove: @escaping () -> Void) -> some View {
        Button(action: onRemove) {
            HStack(spacing: 4) {
                Text(label)
                    .font(.caption)
                    .fontWeight(.medium)
                Image(systemName: "xmark")
                    .font(.caption2)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(Color.accentColor.opacity(0.12))
            .foregroundStyle(Color.accentColor)
            .clipShape(Capsule())
        }
        .buttonStyle(PressScaleButtonStyle())
    }

    // MARK: - Expense list

    @ViewBuilder
    private var expenseList: some View {
        if filtered.isEmpty {
            Text("No expenses found")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 32)
        } else if sortOrder == .newest || sortOrder == .oldest {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(dayGroups.enumerated()), id: \.element.label) { index, group in
                    sectionLabel(group.label, topPad: index == 0 ? 16 : 20)
                    ForEach(group.items) { expense in
                        VStack(spacing: 0) {
                            ExpenseRow(expense: expense).padding(.horizontal, 20)
                            if group.items.last?.id != expense.id {
                                Divider().padding(.leading, 76)
                            }
                        }
                    }
                }
                Color.clear.frame(height: 16)
            }
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 20))
        } else {
            VStack(alignment: .leading, spacing: 0) {
                sectionLabel(sortOrder == .highToLow ? "Highest first" : "Lowest first", topPad: 16)
                ForEach(filtered) { expense in
                    VStack(spacing: 0) {
                        ExpenseRow(expense: expense).padding(.horizontal, 20)
                        if filtered.last?.id != expense.id {
                            Divider().padding(.leading, 76)
                        }
                    }
                }
                Color.clear.frame(height: 16)
            }
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
    }

    private func sectionLabel(_ text: String, topPad: CGFloat) -> some View {
        Text(text)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.top, topPad)
            .padding(.bottom, 8)
    }

    private func dayLabel(for date: Date, calendar: Calendar) -> String {
        if calendar.isDateInToday(date) { return "Today" }
        if calendar.isDateInYesterday(date) { return "Yesterday" }
        return date.formatted(.dateTime.weekday(.wide).day().month())
    }
}

// MARK: - Filter Bottom Sheet

private struct SpendingsFilterSheet: View {
    @Binding var sortOrder: SpendingsView.SortOrder
    @Binding var selectedCategory: String?
    @Binding var period: SpendingsView.Period
    @Binding var selectedSource: ExpenseSource?
    let categories: [ExpenseCategory]

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    filterSection("Sort by") {
                        pillRow(SpendingsView.SortOrder.allCases, selected: sortOrder, label: \.rawValue) {
                            sortOrder = $0
                        }
                    }

                    filterSection("Period") {
                        pillRow(SpendingsView.Period.allCases, selected: period, label: \.rawValue) {
                            period = $0
                        }
                    }

                    filterSection("Category") { categoryPills }

                    filterSection("Source") { sourcePills }
                }
                .padding(20)
                .padding(.bottom, 16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Filter & Sort")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Reset") {
                        sortOrder = .newest
                        selectedCategory = nil
                        period = .thisMonth
                        selectedSource = nil
                    }
                    .foregroundStyle(.secondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private func filterSection<C: View>(_ title: String, @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
            content()
        }
    }

    private func pillRow<T: Hashable>(_ options: [T], selected: T, label: KeyPath<T, String>, onSelect: @escaping (T) -> Void) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(options, id: \.self) { option in
                    let isSelected = option == selected
                    Button { onSelect(option) } label: {
                        Text(option[keyPath: label])
                            .font(.subheadline)
                            .fontWeight(isSelected ? .semibold : .regular)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 10)
                            .background(isSelected ? Color.accentColor : Color(.secondarySystemBackground))
                            .foregroundStyle(isSelected ? .white : .primary)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(isSelected ? Color.accentColor : Color(.separator), lineWidth: 1))
                    }
                    .buttonStyle(PressScaleButtonStyle())
                    .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isSelected)
                }
            }
            .padding(.horizontal, 2)
        }
    }

    private var categoryPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                pillButton(label: "All", isSelected: selectedCategory == nil) {
                    selectedCategory = nil
                }
                ForEach(categories) { cat in
                    let isSelected = selectedCategory == cat.name
                    pillButton(label: "\(cat.emoji) \(cat.name)", isSelected: isSelected) {
                        selectedCategory = isSelected ? nil : cat.name
                    }
                }
            }
            .padding(.horizontal, 2)
        }
    }

    private var sourcePills: some View {
        let options: [(label: String, value: ExpenseSource?)] = [
            ("All", nil), ("Manual", .manual), ("Voice", .voice), ("Auto-import", .gmail)
        ]
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(options, id: \.label) { option in
                    let isSelected = selectedSource == option.value
                    pillButton(label: option.label, isSelected: isSelected) {
                        selectedSource = isSelected ? nil : option.value
                    }
                }
            }
            .padding(.horizontal, 2)
        }
    }

    private func pillButton(label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(isSelected ? Color.accentColor : Color(.secondarySystemBackground))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(isSelected ? Color.accentColor : Color(.separator), lineWidth: 1))
        }
        .buttonStyle(PressScaleButtonStyle())
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isSelected)
    }
}
