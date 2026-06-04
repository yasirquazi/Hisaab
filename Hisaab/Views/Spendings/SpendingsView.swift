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
        selectedCategory != nil || selectedSource != nil || period != .thisMonth || sortOrder != .newest
    }

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
        Color.hBackground.ignoresSafeArea()
            .overlay(
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        header
                        chartSection
                            .padding(.bottom, HisaabTheme.Layout.sectionGap)
                        if hasActiveFilters { filterChipsRow.padding(.bottom, HisaabTheme.Layout.itemGap) }
                        expenseList
                    }
                    .padding(.horizontal, HisaabTheme.Layout.pagePadding)
                    .padding(.bottom, 32)
                }
            )
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

    // MARK: - Header

    private var header: some View {
        HisaabHeader(
            title: "Spending Overview",
            rightAction: AnyView(
                Button { showFilter = true } label: {
                    ZStack(alignment: .topTrailing) {
                        Text("Filter")
                            .font(HisaabTheme.mono(HisaabTheme.FontSize.body))
                            .foregroundStyle(Color.hPrimary)
                            .padding(.horizontal, HisaabTheme.Layout.chipH)
                            .padding(.vertical, HisaabTheme.Layout.chipV)
                            .hOutline()
                        if hasActiveFilters {
                            Circle()
                                .fill(Color.hAccent)
                                .frame(width: 8, height: 8)
                                .offset(x: 4, y: -4)
                        }
                    }
                }
                .buttonStyle(PressScaleButtonStyle())
            )
        )
    }

    // MARK: - Chart section

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: HisaabTheme.Layout.itemGap) {
            VStack(alignment: .leading, spacing: 4) {
                Text(period.rawValue.uppercased())
                    .font(HisaabTheme.mono(HisaabTheme.FontSize.small, weight: .medium))
                    .foregroundStyle(Color.hSecondary)
                    .tracking(0.8)
                Text(totalSpent, format: .currency(code: "INR").presentation(.narrow))
                    .font(HisaabTheme.mono(HisaabTheme.FontSize.display, weight: .bold))
                    .foregroundStyle(Color.hPrimary)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.35, dampingFraction: 0.8), value: totalSpent)
            }

            if categoryTotals.isEmpty {
                Text("No expenses for this period")
                    .font(HisaabTheme.mono(HisaabTheme.FontSize.body))
                    .foregroundStyle(Color.hSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 24)
            } else {
                Chart(categoryTotals) { item in
                    BarMark(
                        x: .value("Category", item.emoji),
                        y: .value("Amount", item.total)
                    )
                    .foregroundStyle(item.color)
                    .annotation(position: .top, alignment: .center) {
                        Text(item.total, format: .currency(code: "INR").presentation(.narrow))
                            .font(HisaabTheme.mono(HisaabTheme.FontSize.caption))
                            .foregroundStyle(Color.hSecondary)
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
        .padding(HisaabTheme.Layout.cardPadding)
        .hOutline()
    }

    // MARK: - Active filter chips

    private var filterChipsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
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
        }
    }

    private func activeChip(_ label: String, onRemove: @escaping () -> Void) -> some View {
        Button(action: onRemove) {
            HStack(spacing: 4) {
                Text(label)
                    .font(HisaabTheme.mono(HisaabTheme.FontSize.small, weight: .medium))
                Text("×")
                    .font(HisaabTheme.mono(HisaabTheme.FontSize.body, weight: .regular))
            }
            .foregroundStyle(Color.hBackground)
            .padding(.horizontal, HisaabTheme.Layout.chipH)
            .padding(.vertical, HisaabTheme.Layout.chipV)
            .background(Color.hPrimary)
        }
        .buttonStyle(PressScaleButtonStyle())
    }

    // MARK: - Expense list

    @ViewBuilder
    private var expenseList: some View {
        if filtered.isEmpty {
            Text("No expenses found")
                .font(HisaabTheme.mono(HisaabTheme.FontSize.body))
                .foregroundStyle(Color.hSecondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 32)
        } else if sortOrder == .newest || sortOrder == .oldest {
            VStack(alignment: .leading, spacing: 24) {
                ForEach(dayGroups, id: \.label) { group in
                    VStack(alignment: .leading, spacing: 12) {
                        Text(group.label.uppercased())
                            .font(HisaabTheme.mono(HisaabTheme.FontSize.small, weight: .medium))
                            .foregroundStyle(Color.hSecondary)
                            .tracking(0.8)
                        VStack(spacing: HisaabTheme.Layout.itemGap) {
                            ForEach(group.items) { expense in
                                ExpenseRow(expense: expense)
                            }
                        }
                    }
                }
            }
        } else {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    Text((sortOrder == .highToLow ? "Highest first" : "Lowest first").uppercased())
                        .font(HisaabTheme.mono(HisaabTheme.FontSize.small, weight: .medium))
                        .foregroundStyle(Color.hSecondary)
                        .tracking(0.8)
                    VStack(spacing: HisaabTheme.Layout.itemGap) {
                        ForEach(filtered) { expense in
                            ExpenseRow(expense: expense)
                        }
                    }
                }
            }
        }
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
        VStack(spacing: 0) {
            HisaabHeader(
                title: "Filter & Sort",
                leftAction: AnyView(
                    Button("Reset") {
                        sortOrder = .newest
                        selectedCategory = nil
                        period = .thisMonth
                        selectedSource = nil
                    }
                    .font(HisaabTheme.mono(HisaabTheme.FontSize.body))
                    .foregroundStyle(Color.hSecondary)
                ),
                rightAction: AnyView(
                    Button("Done") { dismiss() }
                        .font(HisaabTheme.mono(HisaabTheme.FontSize.body, weight: .semibold))
                        .foregroundStyle(Color.hPrimary)
                )
            )
            .padding(.horizontal, HisaabTheme.Layout.pagePadding)

            ScrollView {
                VStack(alignment: .leading, spacing: HisaabTheme.Layout.sectionGap) {
                    filterSection("Sort by") {
                        chipRow(SpendingsView.SortOrder.allCases, selected: sortOrder, label: \.rawValue) {
                            sortOrder = $0
                        }
                    }
                    filterSection("Period") {
                        chipRow(SpendingsView.Period.allCases, selected: period, label: \.rawValue) {
                            period = $0
                        }
                    }
                    filterSection("Category") { categoryChips }
                    filterSection("Source") { sourceChips }
                }
                .padding(.horizontal, HisaabTheme.Layout.pagePadding)
                .padding(.bottom, 32)
            }
        }
        .background(Color.hBackground)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(Color.hBackground)
    }

    private func filterSection<C: View>(_ title: String, @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: HisaabTheme.Layout.itemGap) {
            Text(title.uppercased())
                .font(HisaabTheme.mono(HisaabTheme.FontSize.small, weight: .medium))
                .foregroundStyle(Color.hSecondary)
                .tracking(0.8)
            content()
        }
    }

    private func chipRow<T: Hashable>(
        _ options: [T],
        selected: T,
        label: KeyPath<T, String>,
        onSelect: @escaping (T) -> Void
    ) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(options, id: \.self) { option in
                    HisaabChip(label: option[keyPath: label], isSelected: option == selected) {
                        onSelect(option)
                    }
                }
            }
        }
    }

    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                HisaabChip(label: "All", isSelected: selectedCategory == nil) {
                    selectedCategory = nil
                }
                ForEach(categories) { cat in
                    HisaabChip(
                        label: "\(cat.emoji) \(cat.name)",
                        isSelected: selectedCategory == cat.name
                    ) {
                        selectedCategory = selectedCategory == cat.name ? nil : cat.name
                    }
                }
            }
        }
    }

    private var sourceChips: some View {
        let options: [(label: String, value: ExpenseSource?)] = [
            ("All", nil), ("Manual", .manual), ("Voice", .voice), ("Auto-import", .gmail)
        ]
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(options, id: \.label) { option in
                    HisaabChip(label: option.label, isSelected: selectedSource == option.value) {
                        selectedSource = selectedSource == option.value ? nil : option.value
                    }
                }
            }
        }
    }
}
