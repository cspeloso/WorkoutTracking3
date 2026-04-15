//
//  ContentView.swift
//  WorkoutTracking3
//
//  Created by Chris Peloso on 3/9/22.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            NavigationView { HomeView() }
                .tabItem { Label("Home", systemImage: "house.fill") }

            NavigationView { RoutineView() }
                .tabItem { Label("Routines", systemImage: "dumbbell.fill") }

            NavigationView { ProgressDashboardView() }
                .tabItem { Label("Progress", systemImage: "chart.bar.fill") }

            NavigationView { SettingsView() }
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .accentColor(AppColors.accent)
        .environmentObject(UserData.shared)
    }
}

struct HomeView: View {
    @EnvironmentObject private var userData: UserData
    @State private var activeRoutine: Routine?
    @State private var shouldOpenRoutine = false
    @State private var shouldCreateRoutine = false

    private var currentDayOfWeek: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: Date())
    }

    private var stats: TrainingStats {
        TrainingStats(routines: userData.routines)
    }

    private var todaysRoutineIndex: Int? {
        userData.routines.firstIndex { $0.weekday == currentDayOfWeek }
    }

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Work It Out")
                            .font(.system(size: 42, weight: .black, design: .rounded))
                        Text(currentDayOfWeek)
                            .font(.title3.weight(.semibold))
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 28)

                    VStack(alignment: .leading, spacing: 14) {
                        SectionTitle("Today's Workout")

                        if let todaysRoutineIndex,
                           userData.routines.indices.contains(todaysRoutineIndex) {
                            Button {
                                activeRoutine = userData.routines[todaysRoutineIndex]
                                shouldOpenRoutine = true
                            } label: {
                                RoutineCard(
                                    routine: userData.routines[todaysRoutineIndex],
                                    accent: .green,
                                    showDayBadge: true
                                )
                            }
                            .buttonStyle(.plain)
                        } else {
                            EmptyTodayCard {
                                shouldCreateRoutine = true
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 14) {
                        SectionTitle("Your Stats")
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                            StatTile(icon: "square.stack.3d.up.fill", value: "\(stats.routineCount)", label: "Routines", color: AppColors.accent)
                            StatTile(icon: "heart.text.square.fill", value: "\(stats.exerciseCount)", label: "Exercises", color: AppColors.accent)
                            StatTile(icon: "checkmark.circle.fill", value: "\(stats.setCount)", label: "Sets Logged", color: AppColors.accent)
                            StatTile(icon: "calendar.badge.checkmark", value: "\(stats.setsThisWeek)", label: "This Week", color: AppColors.accent)
                        }
                    }

                    if !userData.routines.isEmpty {
                        VStack(alignment: .leading, spacing: 14) {
                            SectionTitle("Quick Start")
                            ForEach(userData.routines.indices, id: \.self) { index in
                                Button {
                                    activeRoutine = userData.routines[index]
                                    shouldOpenRoutine = true
                                } label: {
                                    RoutineCard(
                                        routine: userData.routines[index],
                                        accent: AppColors.accent,
                                        showDayBadge: false
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 32)
            }

            NavigationLink(destination: selectedRoutineDestination(), isActive: $shouldOpenRoutine) {
                EmptyView()
            }
            .hidden()

            NavigationLink(destination: AddRoutine(routines: $userData.routines), isActive: $shouldCreateRoutine) {
                EmptyView()
            }
            .hidden()
        }
        .navigationBarHidden(true)
    }

    private func selectedRoutineDestination() -> some View {
        Group {
            if let activeRoutine {
                RoutineDetailsRoute(routine: activeRoutine) { updatedRoutine in
                    guard let index = userData.routines.firstIndex(where: { $0.id == updatedRoutine.id }) else {
                        return
                    }
                    
                    if userData.routines[index] != updatedRoutine {
                        userData.routines[index] = updatedRoutine
                    }
                }
            } else {
                EmptyView()
            }
        }
    }
}

struct RoutineDetailsRoute: View {
    @State private var routine: Routine
    @State private var pendingSyncWorkItem: DispatchWorkItem?
    let syncRoutine: (Routine) -> Void

    init(routine: Routine, syncRoutine: @escaping (Routine) -> Void) {
        self._routine = State(initialValue: routine)
        self.syncRoutine = syncRoutine
    }

    var body: some View {
        RoutineDetailsView(routine: $routine)
            .onChange(of: routine) { updatedRoutine in
                scheduleSync(updatedRoutine)
            }
            .onDisappear {
                pendingSyncWorkItem?.cancel()
                syncRoutine(routine)
            }
    }

    private func scheduleSync(_ updatedRoutine: Routine) {
        pendingSyncWorkItem?.cancel()

        let workItem = DispatchWorkItem {
            syncRoutine(updatedRoutine)
        }

        pendingSyncWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15, execute: workItem)
    }
}

struct ProgressDashboardView: View {
    @EnvironmentObject private var userData: UserData
    @State private var selectedMetric: ProgressMetric = .maxWeight
    @State private var selectedRange: ProgressRange = .threeMonths
    @State private var searchText = ""

    private var stats: TrainingStats {
        TrainingStats(routines: userData.routines)
    }

    private var filteredRecords: [ExerciseRecord] {
        let records = stats.personalRecords
        let searchedRecords = searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? records
            : records.filter { $0.name.localizedCaseInsensitiveContains(searchText) }

        return searchedRecords.sorted { lhs, rhs in
            let lhsValue = selectedMetric.value(for: lhs)
            let rhsValue = selectedMetric.value(for: rhs)
            if lhsValue == rhsValue {
                return lhs.name < rhs.name
            }

            return lhsValue > rhsValue
        }
    }

    private var progressPoints: [ProgressPoint] {
        ProgressDataBuilder.points(
            routines: userData.routines,
            metric: selectedMetric,
            range: selectedRange
        )
    }

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    Text("Progress")
                        .font(.system(size: 42, weight: .black, design: .rounded))
                        .padding(.top, 28)

                    HStack(spacing: 0) {
                        SummaryMetric(value: "\(stats.setCount)", label: "Sets")
                        Divider().background(AppColors.border)
                        SummaryMetric(value: "\(stats.exerciseCount)", label: "Exercises")
                        Divider().background(AppColors.border)
                        SummaryMetric(value: "\(stats.setsThisWeek)", label: "This Week")
                    }
                    .frame(height: 92)
                    .background(AppColors.card)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppColors.border))
                    .cornerRadius(8)

                    HStack(spacing: 12) {
                        ProgressPill(title: "Personal Records", systemImage: "trophy.fill", isActive: true)
                        ProgressPill(title: "History", systemImage: "clock.fill", isActive: false)
                    }

                    Picker("Metric", selection: $selectedMetric) {
                        ForEach(ProgressMetric.allCases) { metric in
                            Text(metric.title).tag(metric)
                        }
                    }
                    .pickerStyle(.segmented)

                    VStack(alignment: .leading, spacing: 14) {
                        SectionTitle("\(selectedMetric.title) Over Time")
                        ProgressRangeControls(selectedRange: $selectedRange)
                        ProgressLineChart(
                            points: progressPoints,
                            metric: selectedMetric,
                            emptyText: "Complete workout logs to build your progress chart."
                        )
                    }

                    VStack(alignment: .leading, spacing: 14) {
                        SectionTitle("Top \(selectedMetric.title)")
                        ProgressBarChart(records: Array(filteredRecords.prefix(8)), metric: selectedMetric)
                    }

                    VStack(spacing: 14) {
                        if filteredRecords.isEmpty {
                            EmptyRecordsCard()
                        } else {
                            ForEach(filteredRecords.prefix(25)) { record in
                                PersonalRecordCard(record: record)
                            }
                        }
                    }
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 32)
            }
        }
        .navigationBarHidden(true)
        .searchable(text: $searchText, prompt: "Search exercises")
    }
}

enum AppColors {
    static let background = Color(UIColor.systemGroupedBackground)
    static let card = Color(UIColor.secondarySystemGroupedBackground)
    static let elevated = Color(UIColor.tertiarySystemGroupedBackground)
    static let border = Color.primary.opacity(0.10)
    static let accent = Color(red: 221/255, green: 69/255, blue: 36/255)
    static let success = accent
    static let today = Color(red: 0.08, green: 0.62, blue: 0.38)
}

extension View {
    @ViewBuilder
    func hideScrollContentBackgroundIfAvailable() -> some View {
        if #available(iOS 16.0, *) {
            self.scrollContentBackground(.hidden)
        } else {
            self
        }
    }
}

struct SectionTitle: View {
    let title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title.uppercased())
            .font(.caption.weight(.black))
            .tracking(1.5)
            .foregroundColor(.secondary)
    }
}

struct StatTile: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Image(systemName: icon)
                .font(.title3.weight(.semibold))
                .foregroundColor(color)
            Spacer(minLength: 4)
            Text(value)
                .font(.system(size: 34, weight: .black, design: .rounded))
            Text(label)
                .font(.subheadline.weight(.bold))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 122, alignment: .leading)
        .padding(18)
        .background(AppColors.card)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppColors.border))
        .cornerRadius(8)
    }
}

struct RoutineCard: View {
    let routine: Routine
    let accent: Color
    let showDayBadge: Bool

    var body: some View {
        HStack(spacing: 16) {
            if showDayBadge {
                Text(dayAbbreviation)
                    .font(.caption.weight(.black))
                    .tracking(2)
                    .foregroundColor(.white)
                    .frame(width: 58, height: 42)
                    .background(accent)
                    .cornerRadius(8)
            } else {
                Image(systemName: "dumbbell.fill")
                    .font(.title3.weight(.bold))
                    .foregroundColor(AppColors.accent)
                    .frame(width: 48, height: 48)
                    .background(AppColors.elevated)
                    .cornerRadius(8)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(routineTitle)
                    .font(.title3.weight(.black))
                    .lineLimit(1)
                Text("\(routine.weekday.isEmpty ? "No day" : routine.weekday) · \(routine.workouts.count) exercise\(routine.workouts.count == 1 ? "" : "s")")
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.title3.weight(.bold))
                .foregroundColor(.secondary)
        }
        .padding(18)
        .background(AppColors.card)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppColors.border))
        .cornerRadius(8)
    }

    private var routineTitle: String {
        if !routine.name.isEmpty {
            return routine.name
        }

        return routine.weekday.isEmpty ? "Untitled Routine" : routine.weekday
    }

    private var dayAbbreviation: String {
        String((routine.weekday.isEmpty ? "Any" : routine.weekday).prefix(3)).uppercased()
    }
}

struct EmptyTodayCard: View {
    let createRoutine: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "calendar")
                .font(.system(size: 36, weight: .semibold))
                .foregroundColor(.secondary)

            Text("No routine scheduled for today")
                .font(.headline.weight(.bold))
                .foregroundColor(.secondary)

            Button(action: createRoutine) {
                Text("Create Routine")
                    .font(.headline.weight(.black))
                    .foregroundColor(.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 14)
                    .background(AppColors.accent)
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, minHeight: 190)
        .background(AppColors.card)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                .foregroundColor(AppColors.border)
        )
        .cornerRadius(8)
    }
}

struct SummaryMetric: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.system(size: 30, weight: .black, design: .rounded))
            Text(label)
                .font(.subheadline.weight(.bold))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct ProgressPill: View {
    let title: String
    let systemImage: String
    let isActive: Bool

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.subheadline.weight(.black))
            .foregroundColor(isActive ? .primary : .secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(isActive ? AppColors.elevated : AppColors.card.opacity(0.55))
            .cornerRadius(8)
    }
}

enum ProgressMetric: String, CaseIterable, Identifiable {
    case maxWeight
    case estimatedOneRepMax
    case maxReps
    case bestVolume

    var id: String { rawValue }

    var title: String {
        switch self {
        case .maxWeight:
            return "Weight"
        case .estimatedOneRepMax:
            return "Est. 1RM"
        case .maxReps:
            return "Reps"
        case .bestVolume:
            return "Volume"
        }
    }

    func value(for record: ExerciseRecord) -> Double {
        switch self {
        case .maxWeight:
            return record.maxWeight
        case .estimatedOneRepMax:
            return record.estimatedOneRepMax
        case .maxReps:
            return Double(record.maxReps)
        case .bestVolume:
            return record.bestVolume
        }
    }

    func formattedValue(for record: ExerciseRecord) -> String {
        switch self {
        case .maxWeight:
            return UserData.shared.weightUnit.formattedWeight(fromStoredPounds: record.maxWeight)
        case .estimatedOneRepMax:
            return UserData.shared.weightUnit.formattedWeight(fromStoredPounds: record.estimatedOneRepMax)
        case .maxReps:
            return "\(record.maxReps)"
        case .bestVolume:
            return UserData.shared.weightUnit.formattedVolume(fromStoredPoundVolume: record.bestVolume)
        }
    }

    func formattedRawValue(_ value: Double) -> String {
        switch self {
        case .maxWeight:
            return UserData.shared.weightUnit.formattedWeight(fromStoredPounds: value)
        case .estimatedOneRepMax:
            return UserData.shared.weightUnit.formattedWeight(fromStoredPounds: value)
        case .maxReps:
            return "\(Int(value)) reps"
        case .bestVolume:
            return UserData.shared.weightUnit.formattedVolume(fromStoredPoundVolume: value)
        }
    }
}

enum ProgressRange: String, CaseIterable, Identifiable {
    case oneMonth
    case threeMonths
    case sixMonths
    case oneYear
    case all

    var id: String { rawValue }

    var title: String {
        switch self {
        case .oneMonth:
            return "1M"
        case .threeMonths:
            return "3M"
        case .sixMonths:
            return "6M"
        case .oneYear:
            return "1Y"
        case .all:
            return "All"
        }
    }

    func startDate(relativeTo date: Date = Date()) -> Date? {
        switch self {
        case .oneMonth:
            return Calendar.current.date(byAdding: .month, value: -1, to: date)
        case .threeMonths:
            return Calendar.current.date(byAdding: .month, value: -3, to: date)
        case .sixMonths:
            return Calendar.current.date(byAdding: .month, value: -6, to: date)
        case .oneYear:
            return Calendar.current.date(byAdding: .year, value: -1, to: date)
        case .all:
            return nil
        }
    }
}

struct ProgressRangeControls: View {
    @Binding var selectedRange: ProgressRange

    var body: some View {
        HStack(spacing: 8) {
            ForEach(ProgressRange.allCases) { range in
                Button {
                    selectedRange = range
                } label: {
                    Text(range.title)
                        .font(.caption.weight(.black))
                        .foregroundColor(selectedRange == range ? .white : .primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(selectedRange == range ? AppColors.accent : AppColors.card)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppColors.border))
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct ProgressPoint: Identifiable, Equatable {
    let id = UUID()
    let date: Date
    let value: Double
}

struct ProgressLineChart: View {
    let points: [ProgressPoint]
    let metric: ProgressMetric
    let emptyText: String

    private var sortedPoints: [ProgressPoint] {
        points.sorted { $0.date < $1.date }
    }

    private var maxValue: Double {
        sortedPoints.map(\.value).max() ?? 0
    }

    private var minValue: Double {
        sortedPoints.map(\.value).min() ?? 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if sortedPoints.isEmpty {
                Text(emptyText)
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(18)
                    .background(AppColors.card)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppColors.border))
                    .cornerRadius(8)
            } else {
                HStack {
                    Text(metric.formattedRawValue(maxValue))
                        .font(.caption.weight(.black))
                        .foregroundColor(AppColors.accent)
                    Spacer()
                    Text("\(sortedPoints.count) entries")
                        .font(.caption.weight(.bold))
                        .foregroundColor(.secondary)
                }

                GeometryReader { proxy in
                    ZStack {
                        VStack(spacing: proxy.size.height / 3) {
                            Divider().background(AppColors.border)
                            Divider().background(AppColors.border)
                            Divider().background(AppColors.border)
                        }

                        Path { path in
                            for (index, point) in sortedPoints.enumerated() {
                                let location = chartLocation(
                                    for: point,
                                    index: index,
                                    count: sortedPoints.count,
                                    size: proxy.size
                                )

                                if index == 0 {
                                    path.move(to: location)
                                } else {
                                    path.addLine(to: location)
                                }
                            }
                        }
                        .stroke(AppColors.accent, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))

                        ForEach(Array(sortedPoints.enumerated()), id: \.element.id) { index, point in
                            Circle()
                                .fill(AppColors.accent)
                                .frame(width: 7, height: 7)
                                .position(chartLocation(
                                    for: point,
                                    index: index,
                                    count: sortedPoints.count,
                                    size: proxy.size
                                ))
                        }
                    }
                }
                .frame(height: 180)

                HStack {
                    Text(shortDate(sortedPoints.first?.date))
                    Spacer()
                    Text(shortDate(sortedPoints.last?.date))
                }
                .font(.caption.weight(.bold))
                .foregroundColor(.secondary)
            }
        }
        .padding(18)
        .background(AppColors.card)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppColors.border))
        .cornerRadius(8)
    }

    private func chartLocation(for point: ProgressPoint, index: Int, count: Int, size: CGSize) -> CGPoint {
        let x = count <= 1 ? size.width / 2 : size.width * CGFloat(index) / CGFloat(count - 1)
        let valueRange = max(maxValue - minValue, 1)
        let normalizedY = (point.value - minValue) / valueRange
        let y = size.height - (size.height * CGFloat(normalizedY))
        return CGPoint(x: x, y: min(max(y, 0), size.height))
    }

    private func shortDate(_ date: Date?) -> String {
        guard let date else {
            return ""
        }

        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("MMM d")
        return formatter.string(from: date)
    }
}

struct ProgressBarChart: View {
    let records: [ExerciseRecord]
    let metric: ProgressMetric

    private var maxValue: Double {
        records.map { metric.value(for: $0) }.max() ?? 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if records.isEmpty {
                Text("Log sets to build your chart.")
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(.secondary)
                    .padding(18)
            } else {
                ForEach(records) { record in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(record.name)
                                .font(.caption.weight(.bold))
                                .lineLimit(1)
                            Spacer()
                            Text(metric.formattedValue(for: record))
                                .font(.caption.weight(.black))
                                .foregroundColor(AppColors.accent)
                        }

                        GeometryReader { proxy in
                            RoundedRectangle(cornerRadius: 4)
                                .fill(AppColors.elevated)
                                .overlay(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(AppColors.accent)
                                        .frame(width: barWidth(totalWidth: proxy.size.width, value: metric.value(for: record)))
                                }
                        }
                        .frame(height: 10)
                    }
                }
            }
        }
        .padding(18)
        .background(AppColors.card)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppColors.border))
        .cornerRadius(8)
    }

    private func barWidth(totalWidth: CGFloat, value: Double) -> CGFloat {
        guard maxValue > 0 else {
            return 0
        }

        return totalWidth * CGFloat(value / maxValue)
    }
}

struct PersonalRecordCard: View {
    let record: ExerciseRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text(record.name)
                    .font(.title3.weight(.black))
                Spacer()
                Text("\(record.setCount) set\(record.setCount == 1 ? "" : "s")")
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(.secondary)
            }

            HStack {
                RecordMetric(systemImage: "dumbbell.fill", color: AppColors.accent, value: UserData.shared.weightUnit.formattedWeight(fromStoredPounds: record.maxWeight), label: "Max Weight")
                RecordMetric(systemImage: "chart.line.uptrend.xyaxis", color: AppColors.accent, value: UserData.shared.weightUnit.formattedWeight(fromStoredPounds: record.estimatedOneRepMax), label: "Est. 1RM")
                RecordMetric(systemImage: "arrow.left.arrow.right", color: AppColors.accent, value: "\(record.maxReps)", label: "Max Reps")
            }
        }
        .padding(18)
        .background(AppColors.card)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppColors.border))
        .cornerRadius(8)
    }
}

struct RecordMetric: View {
    let systemImage: String
    let color: Color
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: systemImage)
                .foregroundColor(color)
            Text(value)
                .font(.headline.weight(.black))
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            Text(label)
                .font(.caption.weight(.bold))
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }
}

struct EmptyRecordsCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("No personal records yet")
                .font(.headline.weight(.black))
            Text("Log sets in a workout and your best weight, reps, and estimated strength will appear here.")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(AppColors.card)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppColors.border))
        .cornerRadius(8)
    }
}

struct TrainingStats {
    let routineCount: Int
    let exerciseCount: Int
    let setCount: Int
    let setsThisWeek: Int
    let totalVolume: Double
    let personalRecords: [ExerciseRecord]

    init(routines: [Routine]) {
        routineCount = routines.count

        var exerciseNames = Set<String>()
        var recordsByName: [String: ExerciseRecord] = [:]
        var allSets: [(name: String, set: Workout.Set, date: Date)] = []

        for routine in routines {
            for workout in routine.workouts {
                exerciseNames.insert(workout.name)

                for set in workout.sets {
                    allSets.append((workout.name, set, workout.startDate))
                }

                for loggedSet in workout.loggedSets {
                    for set in loggedSet.sets {
                        allSets.append((workout.name, set, loggedSet.loggedOnDate))
                    }
                }
            }
        }

        for item in allSets {
            let volume = item.set.weight * Double(item.set.reps)
            let estimatedOneRepMax = item.set.weight * (1 + Double(item.set.reps) / 30)
            var record = recordsByName[item.name] ?? ExerciseRecord(name: item.name)
            record.setCount += 1
            record.maxWeight = max(record.maxWeight, item.set.weight)
            record.maxReps = max(record.maxReps, item.set.reps)
            record.estimatedOneRepMax = max(record.estimatedOneRepMax, estimatedOneRepMax)
            record.bestVolume = max(record.bestVolume, volume)
            record.totalVolume += volume
            recordsByName[item.name] = record
        }

        exerciseCount = exerciseNames.count
        setCount = allSets.count
        totalVolume = allSets.reduce(0) { $0 + ($1.set.weight * Double($1.set.reps)) }
        let calendar = Calendar.current
        let weekInterval = calendar.dateInterval(of: .weekOfYear, for: Date())
        setsThisWeek = allSets.filter { item in
            guard let weekInterval else {
                return false
            }

            return item.date >= weekInterval.start && item.date < weekInterval.end
        }.count
        personalRecords = recordsByName.values.sorted {
            if $0.estimatedOneRepMax == $1.estimatedOneRepMax {
                return $0.name < $1.name
            }

            return $0.estimatedOneRepMax > $1.estimatedOneRepMax
        }
    }

    var compactVolume: String {
        if totalVolume >= 1000 {
            return "\((totalVolume / 1000).formatted(.number.precision(.fractionLength(0...1))))k"
        }

        return totalVolume.formatted(.number.precision(.fractionLength(0...0)))
    }
}

struct ExerciseRecord: Identifiable {
    var id: String { name }
    let name: String
    var setCount = 0
    var maxWeight = 0.0
    var estimatedOneRepMax = 0.0
    var maxReps = 0
    var bestVolume = 0.0
    var totalVolume = 0.0
}

enum ProgressDataBuilder {
    static func points(
        routines: [Routine],
        metric: ProgressMetric,
        range: ProgressRange
    ) -> [ProgressPoint] {
        let loggedSets = routines.flatMap { routine in
            routine.workouts.flatMap { workout in
                datedSets(for: workout)
            }
        }

        return points(
            datedSets: loggedSets,
            metric: metric,
            range: range
        )
    }

    static func points(
        for workout: Workout,
        metric: ProgressMetric,
        range: ProgressRange
    ) -> [ProgressPoint] {
        points(
            datedSets: datedSets(for: workout),
            metric: metric,
            range: range
        )
    }

    private static func points(
        datedSets: [(date: Date, set: Workout.Set)],
        metric: ProgressMetric,
        range: ProgressRange
    ) -> [ProgressPoint] {
        let calendar = Calendar.current
        let endDate = range == .all
            ? (datedSets.map(\.date).max() ?? Date())
            : Date()
        let startDate = range == .all
            ? (datedSets.map(\.date).min() ?? Date.distantPast)
            : (range.startDate(relativeTo: endDate) ?? Date.distantPast)
        let normalizedStart = calendar.startOfDay(for: min(startDate, endDate))
        let normalizedEnd = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: max(startDate, endDate))) ?? endDate

        let groupedSets = Dictionary(grouping: datedSets.filter { item in
            item.date >= normalizedStart && item.date < normalizedEnd
        }) { item in
            calendar.startOfDay(for: item.date)
        }

        return groupedSets.map { date, items in
            ProgressPoint(date: date, value: value(for: items.map(\.set), metric: metric))
        }
        .filter { $0.value > 0 }
        .sorted { $0.date < $1.date }
    }

    private static func datedSets(for workout: Workout) -> [(date: Date, set: Workout.Set)] {
        let activeSets = workout.sets.map { set in
            (date: workout.startDate, set: set)
        }
        
        let completedSets = workout.loggedSets.flatMap { loggedSet in
            loggedSet.sets.map { set in
                (date: loggedSet.loggedOnDate, set: set)
            }
        }
        
        return activeSets + completedSets
    }

    private static func value(for sets: [Workout.Set], metric: ProgressMetric) -> Double {
        switch metric {
        case .maxWeight:
            return sets.map(\.weight).max() ?? 0
        case .estimatedOneRepMax:
            return sets.map { $0.weight * (1 + Double($0.reps) / 30) }.max() ?? 0
        case .maxReps:
            return Double(sets.map(\.reps).max() ?? 0)
        case .bestVolume:
            return sets.reduce(0) { $0 + ($1.weight * Double($1.reps)) }
        }
    }
}
