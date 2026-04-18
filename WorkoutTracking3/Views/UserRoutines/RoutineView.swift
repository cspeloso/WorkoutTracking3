import SwiftUI

let weekdays = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]

private let routineTemplates: [RoutineTemplate] = [
    RoutineTemplate(
        title: "Full Body",
        subtitle: "Squat, press, row",
        weekday: "Monday",
        workouts: ["Squats", "Bench Press", "Bent Over Row"]
    ),
    RoutineTemplate(
        title: "Push",
        subtitle: "Chest, shoulders, triceps",
        weekday: "Tuesday",
        workouts: ["Bench Press", "Seated Overhead Press", "Tricep Pushdown"]
    ),
    RoutineTemplate(
        title: "Pull",
        subtitle: "Back and biceps",
        weekday: "Wednesday",
        workouts: ["Lat Pulldown", "Seated Row", "Bicep Curl"]
    ),
    RoutineTemplate(
        title: "Legs",
        subtitle: "Quads, hamstrings, calves",
        weekday: "Thursday",
        workouts: ["Squats", "Leg Press", "Leg Curl", "Calf Raise"]
    ),
    RoutineTemplate(
        title: "Upper",
        subtitle: "Balanced upper day",
        weekday: "Friday",
        workouts: ["Bench Press", "Bent Over Row", "Seated Overhead Press", "Lat Pulldown"]
    ),
    RoutineTemplate(
        title: "Lower",
        subtitle: "Squat and machine work",
        weekday: "Saturday",
        workouts: ["Squats", "Linear Leg Press", "Leg Extension", "Leg Curl"]
    )
]

struct RoutineView: View {
    @EnvironmentObject var userData: UserData
    @State private var activeRoutine: Routine?
    @State private var shouldOpenRoutine = false
    @State private var shouldAddRoutine = false
    @State private var shouldShowTemplates = false
    @State private var shouldShowArchived = false

    private var currentDayOfWeek: String {
        let df = DateFormatter()
        df.dateFormat = "EEEE"
        return df.string(from: Date())
    }

    private var sortedRoutineIndices: [Int] {
        userData.routines.indices.filter { !userData.routines[$0].isArchived }.sorted { a, b in
            let ra = userData.routines[a]
            let rb = userData.routines[b]

            if ra.weekday == currentDayOfWeek, rb.weekday != currentDayOfWeek { return true }
            if rb.weekday == currentDayOfWeek, ra.weekday != currentDayOfWeek { return false }

            let ia = weekdays.firstIndex(of: ra.weekday) ?? 999
            let ib = weekdays.firstIndex(of: rb.weekday) ?? 999
            return ia < ib
        }
    }

    private var archivedRoutineIndices: [Int] {
        userData.routines.indices.filter { userData.routines[$0].isArchived }.sorted { a, b in
            let ra = userData.routines[a]
            let rb = userData.routines[b]
            return routineDisplayName(ra) < routineDisplayName(rb)
        }
    }

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            List {
                Section {
                    HStack {
                        Text("Routines")
                            .font(.system(size: 42, weight: .black, design: .rounded))

                        Spacer()

                        Button {
                            shouldAddRoutine = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 28, weight: .regular))
                                .foregroundColor(.white)
                                .frame(width: 64, height: 64)
                                .background(AppColors.accent)
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 28)
                }
                .listRowInsets(EdgeInsets(top: 0, leading: 22, bottom: 6, trailing: 22))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)

                Section {
                    if sortedRoutineIndices.isEmpty {
                        EmptyTodayCard {
                            shouldAddRoutine = true
                        }
                    } else {
                        ForEach(Array(sortedRoutineIndices.enumerated()), id: \.element) { row, index in
                            Button {
                                activeRoutine = userData.routines[index]
                                shouldOpenRoutine = true
                            } label: {
                                RoutineCard(
                                    routine: userData.routines[index],
                                    accent: row == 0 && userData.routines[index].weekday == currentDayOfWeek ? AppColors.today : AppColors.accent,
                                    showDayBadge: true
                                )
                            }
                            .buttonStyle(.plain)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button {
                                    archiveRoutine(at: index)
                                } label: {
                                    Label("Archive", systemImage: "archivebox")
                                }
                                .tint(.secondary)

                                Button(role: .destructive) {
                                    deleteRoutine(at: index)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
                .listRowInsets(EdgeInsets(top: 7, leading: 22, bottom: 7, trailing: 22))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)

                Section {
                    Button {
                        shouldShowTemplates = true
                    } label: {
                        RoutineDestinationCard(
                            title: "Templates",
                            subtitle: "\(routineTemplates.count) ready-made routines",
                            systemImage: "sparkles",
                            color: AppColors.accent
                        )
                    }
                    .buttonStyle(.plain)

                    Button {
                        shouldShowArchived = true
                    } label: {
                        RoutineDestinationCard(
                            title: "Archived Routines",
                            subtitle: "\(archivedRoutineIndices.count) hidden from active lists",
                            systemImage: "archivebox.fill",
                            color: .secondary
                        )
                    }
                    .buttonStyle(.plain)
                } header: {
                    SectionTitle("More")
                }
                .listRowInsets(EdgeInsets(top: 7, leading: 22, bottom: 7, trailing: 22))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
            .listStyle(.plain)
            .hideScrollContentBackgroundIfAvailable()

            NavigationLink(destination: selectedRoutineDestination(), isActive: $shouldOpenRoutine) {
                EmptyView()
            }
            .hidden()

            NavigationLink(
                destination: TemplatesRoutineView(addTemplate: createRoutineFromTemplate),
                isActive: $shouldShowTemplates
            ) {
                EmptyView()
            }
            .hidden()

            NavigationLink(destination: ArchivedRoutinesView(), isActive: $shouldShowArchived) {
                EmptyView()
            }
            .hidden()
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $shouldAddRoutine) {
            NavigationView {
                AddRoutine(routines: $userData.routines)
            }
        }
    }

    func deleteRoutine(at offsets: IndexSet) {
        let originalIndexes = offsets.map { sortedRoutineIndices[$0] }
        userData.routines.remove(atOffsets: IndexSet(originalIndexes))
    }

    private func deleteRoutine(at index: Int) {
        guard userData.routines.indices.contains(index) else {
            return
        }

        userData.routines.remove(at: index)
    }

    private func archiveRoutine(at index: Int) {
        guard userData.routines.indices.contains(index) else {
            return
        }

        userData.routines[index].isArchived = true
    }

    private func openQuickWorkoutRoutine() {
        let index = quickWorkoutRoutineIndex()
        activeRoutine = userData.routines[index]
        shouldOpenRoutine = true
    }
    
    private func quickWorkoutRoutineIndex() -> Int {
        if let index = userData.routines.firstIndex(where: { $0.name == "Quick Workout" }) {
            userData.routines[index].isArchived = false
            return index
        }
        
        if let oldIndex = userData.routines.firstIndex(where: { $0.name == "Quick Workouts" }) {
            userData.routines[oldIndex].name = "Quick Workout"
            userData.routines[oldIndex].isArchived = false
            return oldIndex
        }
        
        let routine = Routine(name: "Quick Workout", weekday: currentDayOfWeek, workouts: [])
        userData.routines.insert(routine, at: 0)
        return 0
    }

    private func createRoutineFromTemplate(_ template: RoutineTemplate) {
        let workouts = template.workouts.map {
            Workout(name: $0, sets: [], loggedSets: [])
        }
        let routine = Routine(name: template.title, weekday: template.weekday, workouts: workouts)
        userData.routines.append(routine)
        activeRoutine = routine

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            shouldOpenRoutine = true
        }
    }
    
    private func routineDisplayName(_ routine: Routine) -> String {
        if !routine.name.isEmpty {
            return routine.name
        }

        return routine.weekday.isEmpty ? "Untitled Routine" : routine.weekday
    }
    
    @ViewBuilder
    private func selectedRoutineDestination() -> some View {
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

private struct TemplatesRoutineView: View {
    @Environment(\.presentationMode) private var mode
    let addTemplate: (RoutineTemplate) -> Void

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            List {
                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Templates")
                            .font(.system(size: 42, weight: .black, design: .rounded))
                        Text("Start with a structure, then tune it to fit.")
                            .font(.subheadline.weight(.bold))
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 18)
                }
                .listRowInsets(EdgeInsets(top: 0, leading: 22, bottom: 6, trailing: 22))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)

                Section {
                    ForEach(routineTemplates) { template in
                        Button {
                            addTemplate(template)
                            mode.wrappedValue.dismiss()
                        } label: {
                            TemplateCard(template: template)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .listRowInsets(EdgeInsets(top: 7, leading: 22, bottom: 7, trailing: 22))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
            .listStyle(.plain)
            .hideScrollContentBackgroundIfAvailable()
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct ArchivedRoutinesView: View {
    @EnvironmentObject private var userData: UserData
    @State private var activeRoutine: Routine?
    @State private var shouldOpenRoutine = false

    private var archivedRoutineIndices: [Int] {
        userData.routines.indices.filter { userData.routines[$0].isArchived }.sorted { a, b in
            routineDisplayName(userData.routines[a]) < routineDisplayName(userData.routines[b])
        }
    }

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            List {
                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Archived")
                            .font(.system(size: 42, weight: .black, design: .rounded))
                        Text("Hidden from active lists. History still counts.")
                            .font(.subheadline.weight(.bold))
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 18)
                }
                .listRowInsets(EdgeInsets(top: 0, leading: 22, bottom: 6, trailing: 22))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)

                Section {
                    if archivedRoutineIndices.isEmpty {
                        EmptyArchivedRoutinesCard()
                    } else {
                        ForEach(archivedRoutineIndices, id: \.self) { index in
                            Button {
                                activeRoutine = userData.routines[index]
                                shouldOpenRoutine = true
                            } label: {
                                RoutineCard(
                                    routine: userData.routines[index],
                                    accent: .secondary,
                                    showDayBadge: true
                                )
                                .opacity(0.72)
                            }
                            .buttonStyle(.plain)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button {
                                    unarchiveRoutine(at: index)
                                } label: {
                                    Label("Unarchive", systemImage: "archivebox.fill")
                                }
                                .tint(AppColors.today)

                                Button(role: .destructive) {
                                    deleteRoutine(at: index)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
                .listRowInsets(EdgeInsets(top: 7, leading: 22, bottom: 7, trailing: 22))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
            .listStyle(.plain)
            .hideScrollContentBackgroundIfAvailable()

            NavigationLink(destination: selectedRoutineDestination(), isActive: $shouldOpenRoutine) {
                EmptyView()
            }
            .hidden()
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func unarchiveRoutine(at index: Int) {
        guard userData.routines.indices.contains(index) else {
            return
        }

        userData.routines[index].isArchived = false
    }

    private func deleteRoutine(at index: Int) {
        guard userData.routines.indices.contains(index) else {
            return
        }

        userData.routines.remove(at: index)
    }

    private func routineDisplayName(_ routine: Routine) -> String {
        if !routine.name.isEmpty {
            return routine.name
        }

        return routine.weekday.isEmpty ? "Untitled Routine" : routine.weekday
    }

    @ViewBuilder
    private func selectedRoutineDestination() -> some View {
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

private struct RoutineTemplate: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let weekday: String
    let workouts: [String]
}

private struct HomeHeroCard: View {
    let hasRoutines: Bool
    let startWorkout: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(hasRoutines ? "Ready to train?" : "Start your first workout")
                    .font(.title2.weight(.bold))
                Text(hasRoutines ? "Jump into a workout now, or keep building your routine plan." : "Pick an exercise and begin logging sets right away.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Button(action: startWorkout) {
                Label("Start Workout", systemImage: "play.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .foregroundColor(.white)
                    .background(Color(red: 221/255, green: 69/255, blue: 36/255))
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)
            
            HStack(spacing: 8) {
                Label("No setup required", systemImage: "bolt.fill")
                Spacer()
                Label("Track sets now", systemImage: "checkmark.circle.fill")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding(18)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(8)
    }
}

private struct EmptyRoutineCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Build your own routine")
                .font(.headline)
            Text("Plan a repeatable day when you want more structure.")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("Create Routine")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(Color(red: 221/255, green: 69/255, blue: 36/255))
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(8)
    }
}

private struct TemplateRow: View {
    let template: RoutineTemplate
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "square.grid.2x2.fill")
                .font(.title3)
                .foregroundColor(Color(red: 221/255, green: 69/255, blue: 36/255))
                .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(template.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                Text(template.subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("\(template.workouts.count)")
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(UIColor.tertiarySystemGroupedBackground))
                .cornerRadius(8)
        }
        .padding(.vertical, 4)
    }
}

private struct TemplateCard: View {
    let template: RoutineTemplate

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.title3.weight(.bold))
                .foregroundColor(AppColors.accent)
                .frame(width: 48, height: 48)
                .background(AppColors.elevated)
                .cornerRadius(8)

            VStack(alignment: .leading, spacing: 4) {
                Text(template.title)
                    .font(.headline.weight(.black))
                Text("\(template.subtitle) · \(template.workouts.count) exercises")
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: "plus")
                .font(.headline.weight(.bold))
                .foregroundColor(.secondary)
        }
        .padding(18)
        .background(AppColors.card)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppColors.border))
        .cornerRadius(8)
    }
}

private struct RoutineDestinationCard: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let color: Color

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: systemImage)
                .font(.title3.weight(.bold))
                .foregroundColor(color)
                .frame(width: 48, height: 48)
                .background(AppColors.elevated)
                .cornerRadius(8)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline.weight(.black))
                    .foregroundColor(.primary)
                Text(subtitle)
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
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
}

private struct EmptyArchivedRoutinesCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("No archived routines")
                .font(.headline.weight(.black))
            Text("Archive old routines to keep your main list focused without losing their history.")
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

private struct RoutineRow: View {
    let routine: Routine
    let currentDayOfWeek: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(routine.name.isEmpty ? routine.weekday : routine.name)
                .font(.headline)
                .padding(.top, 6)
                .foregroundColor(
                    routine.name.isEmpty
                    ? (routine.weekday == currentDayOfWeek ? .green : .red)
                    : .primary
                )

            HStack {
                if !routine.name.isEmpty {
                    Text(routine.weekday)
                }
                
                Text("\(routine.workouts.count) workout\(routine.workouts.count == 1 ? "" : "s")")
            }
            .font(.subheadline)
            .foregroundColor(routine.weekday == currentDayOfWeek ? .green : .secondary)
            .padding(.bottom, 6)
        }
    }
}
