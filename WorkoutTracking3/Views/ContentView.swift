//
//  ContentView.swift
//  WorkoutTracking3
//
//  Created by Chris Peloso on 3/9/22.
//

import SwiftUI

struct ContentView: View {
    @AppStorage("HasCompletedWeightUnitPrompt") private var hasCompletedWeightUnitPrompt = false
    @State private var showWeightUnitPrompt = false

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
        .onAppear {
            AppReviewRequester.recordAppLaunch()

            guard !hasCompletedWeightUnitPrompt else {
                return
            }

            if UserData.hasSavedWeightUnitPreference() {
                hasCompletedWeightUnitPrompt = true
            } else {
                showWeightUnitPrompt = true
            }
        }
        .alert("Choose your weight unit", isPresented: $showWeightUnitPrompt) {
            Button("Pounds (lb)") {
                UserData.shared.setWeightUnitPreference(.pounds)
                hasCompletedWeightUnitPrompt = true
            }

            Button("Kilograms (kg)") {
                UserData.shared.setWeightUnitPreference(.kilograms)
                hasCompletedWeightUnitPrompt = true
            }
        } message: {
            Text("Which unit would you like to use for logging sets? You can change this later in Settings.")
        }
    }
}

struct HomeView: View {
    @EnvironmentObject private var userData: UserData
    @State private var activeRoutineID: Routine.ID?
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

    private var activeRoutineIndices: [Int] {
        userData.routines.indices.filter { !userData.routines[$0].isArchived }.sorted { lhs, rhs in
            let lhsRoutine = userData.routines[lhs]
            let rhsRoutine = userData.routines[rhs]
            let lhsDayIndex = weekdaySortIndex(lhsRoutine.weekday)
            let rhsDayIndex = weekdaySortIndex(rhsRoutine.weekday)

            if lhsDayIndex != rhsDayIndex {
                return lhsDayIndex < rhsDayIndex
            }

            return routineDisplayName(lhsRoutine) < routineDisplayName(rhsRoutine)
        }
    }

    private var todaysRoutineIndex: Int? {
        userData.routines.firstIndex { $0.weekday == currentDayOfWeek && !$0.isArchived }
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
                                activeRoutineID = userData.routines[todaysRoutineIndex].id
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

                    if !activeRoutineIndices.isEmpty {
                        VStack(alignment: .leading, spacing: 14) {
                            SectionTitle("Quick Start")
                            ForEach(activeRoutineIndices, id: \.self) { index in
                                Button {
                                    activeRoutineID = userData.routines[index].id
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
            if let activeRoutineID {
                RoutineDetailsRoute(routineID: activeRoutineID)
            } else {
                EmptyView()
            }
        }
    }

    private func weekdaySortIndex(_ weekday: String) -> Int {
        let orderedWeekdays = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
        return orderedWeekdays.firstIndex(of: weekday) ?? 999
    }

    private func routineDisplayName(_ routine: Routine) -> String {
        if !routine.name.isEmpty {
            return routine.name
        }

        return routine.weekday.isEmpty ? "Untitled Routine" : routine.weekday
    }
}

struct RoutineDetailsRoute: View {
    @EnvironmentObject private var userData: UserData
    let routineID: Routine.ID
    @State private var routine: Routine
    @State private var pendingSyncWorkItem: DispatchWorkItem?

    init(routineID: Routine.ID) {
        self.routineID = routineID
        let routine = UserData.shared.routines.first(where: { $0.id == routineID })
            ?? Routine(name: "Routine", weekday: "", workouts: [])
        self._routine = State(initialValue: routine)
    }

    var body: some View {
        RoutineDetailsView(routine: $routine)
            .onChange(of: routine) { updatedRoutine in
                scheduleSync(updatedRoutine)
            }
            .onAppear {
                refreshFromLiveRoutineIfNeeded()
            }
            .onDisappear {
                flushSync()
            }
    }

    private func refreshFromLiveRoutineIfNeeded() {
        guard let liveRoutine = userData.routines.first(where: { $0.id == routineID }),
              liveRoutine != routine else {
            return
        }

        routine = mergedRoutine(local: routine, live: liveRoutine)
    }

    private func scheduleSync(_ updatedRoutine: Routine) {
        pendingSyncWorkItem?.cancel()

        let workItem = DispatchWorkItem {
            sync(updatedRoutine)
        }

        pendingSyncWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15, execute: workItem)
    }

    private func flushSync() {
        pendingSyncWorkItem?.cancel()
        pendingSyncWorkItem = nil
        sync(routine)
    }

    private func sync(_ updatedRoutine: Routine) {
        guard let index = userData.routines.firstIndex(where: { $0.id == routineID }) else {
            return
        }

        let safeRoutine = routineForSync(local: updatedRoutine, live: userData.routines[index])
        if userData.routines[index] != safeRoutine {
            userData.routines[index] = safeRoutine
        }
    }

    private func routineForSync(local: Routine, live: Routine) -> Routine {
        var synced = local
        synced.workouts = local.workouts.map { localWorkout in
            guard let liveWorkout = live.workouts.first(where: { $0.id == localWorkout.id }) else {
                return localWorkout
            }

            var workout = localWorkout
            workout.sets = liveWorkout.sets
            workout.loggedSets = liveWorkout.loggedSets
            workout.startDate = liveWorkout.startDate
            return workout
        }

        return synced
    }

    private func mergedRoutine(local: Routine, live: Routine) -> Routine {
        var merged = local
        merged.workouts = local.workouts.map { localWorkout in
            guard let liveWorkout = live.workouts.first(where: { $0.id == localWorkout.id }) else {
                return localWorkout
            }

            return mergedWorkout(local: localWorkout, live: liveWorkout)
        }

        let localWorkoutIDs = Set(local.workouts.map(\.id))
        merged.workouts.append(contentsOf: live.workouts.filter { !localWorkoutIDs.contains($0.id) })
        return merged
    }

    private func mergedWorkout(local: Workout, live: Workout) -> Workout {
        var merged = local

        if live.sets.count > local.sets.count {
            merged.sets = live.sets
        }

        if live.loggedSets.count > local.loggedSets.count {
            merged.loggedSets = live.loggedSets
        }

        if live.startDate > local.startDate {
            merged.startDate = live.startDate
        }

        return merged
    }
}

private struct LiveRoutineDetailsRoute: View {
    @EnvironmentObject private var userData: UserData
    let routineID: Routine.ID

    var body: some View {
        if let binding {
            RoutineDetailsView(routine: binding)
        } else {
            Text("Routine not found.")
                .font(.headline.weight(.bold))
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var binding: Binding<Routine>? {
        guard let index = userData.routines.firstIndex(where: { $0.id == routineID }) else {
            return nil
        }

        return $userData.routines[index]
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

                    VStack(alignment: .leading, spacing: 14) {
                        SectionTitle("Lifetime Stats")

                        VStack(spacing: 12) {
                            HStack(spacing: 12) {
                                SummaryMetric(
                                    value: "\(stats.weightIncreaseCount)",
                                    label: "Weight Increases",
                                    systemImage: "arrow.up.circle.fill"
                                )

                                SummaryMetric(
                                    value: "\(stats.trackedExerciseCount)",
                                    label: "Exercises Tracked",
                                    systemImage: "figure.strengthtraining.traditional"
                                )
                            }

                            SummaryMetric(
                                value: "\(stats.setsThisWeek)",
                                label: "Sets Logged This Week",
                                systemImage: "calendar.badge.checkmark"
                            )
                        }
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
                            weightUnit: userData.weightUnit,
                            emptyText: "Complete workout logs to build your progress chart."
                        )
                    }

                    VStack(alignment: .leading, spacing: 14) {
                        SectionTitle("Top \(selectedMetric.title)")
                        ProgressBarChart(records: Array(filteredRecords.prefix(8)), metric: selectedMetric, weightUnit: userData.weightUnit)
                    }

                    VStack(spacing: 14) {
                        if filteredRecords.isEmpty {
                            EmptyRecordsCard()
                        } else {
                            ForEach(filteredRecords.prefix(25)) { record in
                                PersonalRecordCard(record: record, weightUnit: userData.weightUnit)
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

extension String {
    var normalizedExerciseName: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
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
    let systemImage: String?

    init(value: String, label: String, systemImage: String? = nil) {
        self.value = value
        self.label = label
        self.systemImage = systemImage
    }

    var body: some View {
        HStack(spacing: 12) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.headline.weight(.black))
                    .foregroundColor(AppColors.accent)
                    .frame(width: 34, height: 34)
                    .background(AppColors.elevated)
                    .cornerRadius(8)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(value)
                    .font(.system(size: 30, weight: .black, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text(label)
                    .font(.caption.weight(.bold))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
        .padding(14)
        .background(AppColors.card)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppColors.border))
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
        formattedValue(for: record, weightUnit: UserData.shared.weightUnit)
    }

    func formattedValue(for record: ExerciseRecord, weightUnit: WeightUnit) -> String {
        switch self {
        case .maxWeight:
            return weightUnit.formattedWeight(fromStoredPounds: record.maxWeight)
        case .estimatedOneRepMax:
            return weightUnit.formattedWeight(fromStoredPounds: record.estimatedOneRepMax)
        case .maxReps:
            return "\(record.maxReps)"
        case .bestVolume:
            return weightUnit.formattedVolume(fromStoredPoundVolume: record.bestVolume)
        }
    }

    func formattedRawValue(_ value: Double) -> String {
        formattedRawValue(value, weightUnit: UserData.shared.weightUnit)
    }

    func formattedRawValue(_ value: Double, weightUnit: WeightUnit) -> String {
        switch self {
        case .maxWeight:
            return weightUnit.formattedWeight(fromStoredPounds: value)
        case .estimatedOneRepMax:
            return weightUnit.formattedWeight(fromStoredPounds: value)
        case .maxReps:
            return "\(Int(value)) reps"
        case .bestVolume:
            return weightUnit.formattedVolume(fromStoredPoundVolume: value)
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
    var id: Date { date }
    let date: Date
    let value: Double
}

struct ProgressLineChart: View {
    let points: [ProgressPoint]
    let metric: ProgressMetric
    let weightUnit: WeightUnit
    let emptyText: String
    @State private var selectedPoint: ProgressPoint?

    private var sortedPoints: [ProgressPoint] {
        points.sorted { $0.date < $1.date }
    }

    private var maxValue: Double {
        sortedPoints.map(\.value).max() ?? 0
    }

    private var minValue: Double {
        sortedPoints.map(\.value).min() ?? 0
    }

    private var latestPoint: ProgressPoint? {
        sortedPoints.last
    }

    private var bestPoint: ProgressPoint? {
        sortedPoints.max { $0.value < $1.value }
    }

    private var chartBounds: (lower: Double, upper: Double) {
        let rawRange = maxValue - minValue
        let padding = rawRange == 0 ? max(maxValue * 0.1, 1) : rawRange * 0.14
        let lowerBound = max(0, minValue - padding)
        return (lowerBound, maxValue + padding)
    }

    private var highlightedPoints: [ProgressPoint] {
        guard sortedPoints.count > 45 else {
            return sortedPoints
        }

        var uniquePoints: [ProgressPoint] = []
        let candidates = [sortedPoints.first, bestPoint, sortedPoints.last].compactMap { $0 }
        for point in candidates where !uniquePoints.contains(where: { Calendar.current.isDate($0.date, inSameDayAs: point.date) }) {
            uniquePoints.append(point)
        }

        return uniquePoints
    }

    private var visiblePoints: [ProgressPoint] {
        selectedPoint == nil ? highlightedPoints : sortedPoints
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
                HStack(spacing: 12) {
                    ChartSummaryValue(
                        label: "Latest",
                        value: metric.formattedRawValue(latestPoint?.value ?? 0, weightUnit: weightUnit),
                        color: AppColors.accent
                    )
                    ChartSummaryValue(
                        label: "Best",
                        value: metric.formattedRawValue(bestPoint?.value ?? 0, weightUnit: weightUnit),
                        color: AppColors.accent
                    )
                }

                GeometryReader { proxy in
                    ZStack {
                        VStack(spacing: 0) {
                            ForEach(0..<4, id: \.self) { index in
                                Divider().background(AppColors.border)
                                if index < 3 {
                                    Spacer()
                                }
                            }
                        }

                        VStack {
                            Text(metric.formattedRawValue(chartBounds.upper, weightUnit: weightUnit))
                            Spacer()
                            Text(metric.formattedRawValue(chartBounds.lower, weightUnit: weightUnit))
                        }
                        .font(.caption2.weight(.bold))
                        .foregroundColor(.secondary.opacity(0.8))
                        .frame(maxWidth: .infinity, alignment: .leading)

                        if let selectedPoint {
                            let selectedLocation = chartLocation(for: selectedPoint, size: proxy.size)

                            Path { path in
                                path.move(to: CGPoint(x: selectedLocation.x, y: 8))
                                path.addLine(to: CGPoint(x: selectedLocation.x, y: proxy.size.height - 8))
                            }
                            .stroke(AppColors.border, style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                        }

                        if sortedPoints.count > 1 {
                            Path { path in
                                guard let firstPoint = sortedPoints.first,
                                      let lastPoint = sortedPoints.last else {
                                    return
                                }

                                let firstLocation = chartLocation(for: firstPoint, size: proxy.size)
                                let lastLocation = chartLocation(for: lastPoint, size: proxy.size)
                                path.move(to: firstLocation)

                                for point in sortedPoints.dropFirst() {
                                    path.addLine(to: chartLocation(for: point, size: proxy.size))
                                }

                                path.addLine(to: CGPoint(x: lastLocation.x, y: proxy.size.height))
                                path.addLine(to: CGPoint(x: firstLocation.x, y: proxy.size.height))
                                path.closeSubpath()
                            }
                            .fill(
                                LinearGradient(
                                    colors: [AppColors.accent.opacity(0.18), AppColors.accent.opacity(0.02)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        }

                        Path { path in
                            for (index, point) in sortedPoints.enumerated() {
                                let location = chartLocation(for: point, size: proxy.size)

                                if index == 0 {
                                    path.move(to: location)
                                } else {
                                    path.addLine(to: location)
                                }
                            }
                        }
                        .stroke(AppColors.accent, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))

                        ForEach(visiblePoints) { point in
                            Circle()
                                .fill(AppColors.accent)
                                .overlay(Circle().stroke(AppColors.card, lineWidth: 2))
                                .frame(width: pointSize(for: point), height: pointSize(for: point))
                                .position(chartLocation(for: point, size: proxy.size))
                        }

                        if let selectedPoint {
                            let selectedLocation = chartLocation(for: selectedPoint, size: proxy.size)

                            VStack(alignment: .leading, spacing: 3) {
                                Text(metric.formattedRawValue(selectedPoint.value, weightUnit: weightUnit))
                                    .font(.caption.weight(.black))
                                    .foregroundColor(AppColors.accent)
                                Text(shortDate(selectedPoint.date))
                                    .font(.caption2.weight(.bold))
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(AppColors.elevated)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppColors.border))
                            .cornerRadius(8)
                            .position(calloutLocation(for: selectedLocation, in: proxy.size))
                        }
                    }
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                selectedPoint = nearestPoint(to: value.location, size: proxy.size)
                            }
                    )
                }
                .frame(height: 210)
                .onChange(of: points) { _ in
                    selectedPoint = nil
                }

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

    private func chartLocation(for point: ProgressPoint, size: CGSize) -> CGPoint {
        let horizontalInset: CGFloat = 10
        let verticalInset: CGFloat = 16
        let usableWidth = max(size.width - (horizontalInset * 2), 1)
        let usableHeight = max(size.height - (verticalInset * 2), 1)
        let firstDate = sortedPoints.first?.date ?? point.date
        let lastDate = sortedPoints.last?.date ?? point.date
        let dateRange = max(lastDate.timeIntervalSince(firstDate), 1)
        let normalizedX = sortedPoints.count <= 1 ? 0.5 : point.date.timeIntervalSince(firstDate) / dateRange
        let x = horizontalInset + (usableWidth * CGFloat(normalizedX))
        let valueRange = max(chartBounds.upper - chartBounds.lower, 1)
        let normalizedY = (point.value - chartBounds.lower) / valueRange
        let y = verticalInset + usableHeight - (usableHeight * CGFloat(normalizedY))
        return CGPoint(x: x, y: min(max(y, 0), size.height))
    }

    private func nearestPoint(to location: CGPoint, size: CGSize) -> ProgressPoint? {
        sortedPoints.min { lhs, rhs in
            let lhsLocation = chartLocation(for: lhs, size: size)
            let rhsLocation = chartLocation(for: rhs, size: size)
            return distanceSquared(from: lhsLocation, to: location) < distanceSquared(from: rhsLocation, to: location)
        }
    }

    private func distanceSquared(from lhs: CGPoint, to rhs: CGPoint) -> CGFloat {
        let xDistance = lhs.x - rhs.x
        let yDistance = lhs.y - rhs.y
        return (xDistance * xDistance) + (yDistance * yDistance)
    }

    private func pointSize(for point: ProgressPoint) -> CGFloat {
        guard selectedPoint != point else {
            return 12
        }

        return selectedPoint == nil && sortedPoints.count > 45 ? 9 : 6
    }

    private func calloutLocation(for pointLocation: CGPoint, in size: CGSize) -> CGPoint {
        let calloutWidth: CGFloat = 96
        let calloutHeight: CGFloat = 48
        let x = min(max(pointLocation.x, calloutWidth / 2), size.width - (calloutWidth / 2))
        let preferredY = pointLocation.y - 42
        let y = preferredY < calloutHeight / 2 ? pointLocation.y + 42 : preferredY
        return CGPoint(x: x, y: min(max(y, calloutHeight / 2), size.height - (calloutHeight / 2)))
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

struct ChartSummaryValue: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label.uppercased())
                .font(.caption2.weight(.black))
                .foregroundColor(.secondary)
            Text(value)
                .font(.caption.weight(.black))
                .foregroundColor(color)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ProgressBarChart: View {
    let records: [ExerciseRecord]
    let metric: ProgressMetric
    let weightUnit: WeightUnit

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
                            Text(metric.formattedValue(for: record, weightUnit: weightUnit))
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
    let weightUnit: WeightUnit

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
                RecordMetric(systemImage: "dumbbell.fill", color: AppColors.accent, value: weightUnit.formattedWeight(fromStoredPounds: record.maxWeight), label: "Max Weight")
                RecordMetric(systemImage: "chart.line.uptrend.xyaxis", color: AppColors.accent, value: weightUnit.formattedWeight(fromStoredPounds: record.estimatedOneRepMax), label: "Est. 1RM")
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
    let trackedExerciseCount: Int
    let setCount: Int
    let setsThisWeek: Int
    let weightIncreaseCount: Int
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
        trackedExerciseCount = Set(allSets.map { $0.name.normalizedExerciseName }.filter { !$0.isEmpty }).count
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
        weightIncreaseCount = Self.countWeightIncreases(from: allSets)
        personalRecords = recordsByName.values.sorted {
            if $0.estimatedOneRepMax == $1.estimatedOneRepMax {
                return $0.name < $1.name
            }

            return $0.estimatedOneRepMax > $1.estimatedOneRepMax
        }
    }

    private static func countWeightIncreases(from sets: [(name: String, set: Workout.Set, date: Date)]) -> Int {
        var bestWeightByExercise: [String: Double] = [:]
        var increaseCount = 0

        let orderedSets = sets.sorted {
            if $0.date == $1.date {
                return $0.name < $1.name
            }

            return $0.date < $1.date
        }

        for item in orderedSets {
            let normalizedName = item.name.normalizedExerciseName
            guard !normalizedName.isEmpty else {
                continue
            }

            let previousBest = bestWeightByExercise[normalizedName]
            if let previousBest, item.set.weight > previousBest {
                increaseCount += 1
            }

            bestWeightByExercise[normalizedName] = max(previousBest ?? item.set.weight, item.set.weight)
        }

        return increaseCount
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
                datedSets(for: workout, includeActiveSets: true)
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
        range: ProgressRange,
        includeActiveSets: Bool = true
    ) -> [ProgressPoint] {
        points(
            datedSets: datedSets(for: workout, includeActiveSets: includeActiveSets),
            metric: metric,
            range: range
        )
    }

    static func points(
        forWorkoutName workoutName: String,
        in routines: [Routine],
        metric: ProgressMetric,
        range: ProgressRange,
        includeActiveSets: Bool = true,
        currentWorkout: Workout? = nil
    ) -> [ProgressPoint] {
        let normalizedWorkoutName = workoutName.normalizedExerciseName
        var matchingWorkouts = routines
            .flatMap(\.workouts)
            .filter { $0.name.normalizedExerciseName == normalizedWorkoutName }

        if let currentWorkout {
            matchingWorkouts.removeAll { $0.id == currentWorkout.id }
            matchingWorkouts.append(currentWorkout)
        }

        let matchingSets = matchingWorkouts.flatMap { workout in
            datedSets(for: workout, includeActiveSets: includeActiveSets)
        }

        return points(
            datedSets: matchingSets,
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
        let bucket = bucket(for: range, startDate: normalizedStart, endDate: normalizedEnd, calendar: calendar)

        let groupedSets = Dictionary(grouping: datedSets.filter { item in
            item.date >= normalizedStart && item.date < normalizedEnd
        }) { item in
            bucket.startDate(for: item.date, calendar: calendar)
        }

        return groupedSets.map { date, items in
            ProgressPoint(date: date, value: value(for: items.map(\.set), metric: metric))
        }
        .filter { $0.value > 0 }
        .sorted { $0.date < $1.date }
    }

    private static func datedSets(
        for workout: Workout,
        includeActiveSets: Bool
    ) -> [(date: Date, set: Workout.Set)] {
        let activeSets = includeActiveSets
            ? workout.sets.map { set in
                (date: workout.startDate, set: set)
            }
            : []
        
        let completedSets = workout.loggedSets.flatMap { loggedSet in
            loggedSet.sets.map { set in
                (date: loggedSet.loggedOnDate, set: set)
            }
        }
        
        return activeSets + completedSets
    }

    private static func bucket(
        for range: ProgressRange,
        startDate: Date,
        endDate: Date,
        calendar: Calendar
    ) -> ProgressBucket {
        let dayCount = calendar.dateComponents([.day], from: startDate, to: endDate).day ?? 0

        switch range {
        case .oneMonth, .threeMonths:
            return .day
        case .sixMonths:
            return dayCount > 120 ? .week : .day
        case .oneYear:
            return .week
        case .all:
            if dayCount > 540 {
                return .month
            }

            if dayCount > 120 {
                return .week
            }

            return .day
        }
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

    private enum ProgressBucket {
        case day
        case week
        case month

        func startDate(for date: Date, calendar: Calendar) -> Date {
            switch self {
            case .day:
                return calendar.startOfDay(for: date)
            case .week:
                return calendar.dateInterval(of: .weekOfYear, for: date)?.start ?? calendar.startOfDay(for: date)
            case .month:
                let components = calendar.dateComponents([.year, .month], from: date)
                return calendar.date(from: components) ?? calendar.startOfDay(for: date)
            }
        }
    }
}
