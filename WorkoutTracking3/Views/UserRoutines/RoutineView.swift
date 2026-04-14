import SwiftUI

let weekdays = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]

struct RoutineView: View {
    @EnvironmentObject var userData: UserData
    @State private var selectedRoutineIndex: Int?
    @State private var shouldOpenRoutine = false

    private var currentDayOfWeek: String {
        let df = DateFormatter()
        df.dateFormat = "EEEE"
        return df.string(from: Date())
    }

    private var sortedRoutineIndices: [Int] {
        userData.routines.indices.sorted { a, b in
            let ra = userData.routines[a]
            let rb = userData.routines[b]

            if ra.weekday == currentDayOfWeek, rb.weekday != currentDayOfWeek { return true }
            if rb.weekday == currentDayOfWeek, ra.weekday != currentDayOfWeek { return false }

            let ia = weekdays.firstIndex(of: ra.weekday) ?? 999
            let ib = weekdays.firstIndex(of: rb.weekday) ?? 999
            return ia < ib
        }
    }
    
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

    var body: some View {
        NavigationView {
            List {
                Section {
                    HomeHeroCard(
                        hasRoutines: !userData.routines.isEmpty,
                        startWorkout: openQuickWorkoutRoutine
                    )
                    .listRowInsets(EdgeInsets(top: 12, leading: 0, bottom: 8, trailing: 0))
                    .listRowBackground(Color(UIColor.systemGroupedBackground))
                    .listRowSeparator(.hidden)
                }

                if !userData.routines.isEmpty {
                    Section {
                        ForEach(sortedRoutineIndices, id: \.self) { index in
                            let routine = userData.routines[index]
                            
                            NavigationLink(destination: RoutineDetailsView(routine: $userData.routines[index])) {
                                RoutineRow(routine: routine, currentDayOfWeek: currentDayOfWeek)
                            }
                        }
                        .onDelete(perform: deleteRoutine)
                    } header: {
                        Text("Your routines")
                    }
                }
                
                if userData.routines.isEmpty {
                    Section {
                        NavigationLink(destination: AddRoutine(routines: $userData.routines)) {
                            EmptyRoutineCard()
                        }
                    } header: {
                        Text("Create Routine")
                    }
                }
                
                Section {
                    ForEach(routineTemplates) { template in
                        Button {
                            addTemplate(template)
                        } label: {
                            TemplateRow(template: template)
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text("Start from a template")
                }
                
                NavigationLink(
                    destination: selectedRoutineDestination(),
                    isActive: $shouldOpenRoutine
                ) {
                    EmptyView()
                }
                .hidden()
                .listRowSeparator(.hidden)
                .listRowBackground(Color(UIColor.systemGroupedBackground))
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Today")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: AddRoutine(routines: $userData.routines)) {
                        Text("Add routine")
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
    }

    func deleteRoutine(at offsets: IndexSet) {
        let originalIndexes = offsets.map { sortedRoutineIndices[$0] }
        userData.routines.remove(atOffsets: IndexSet(originalIndexes))
    }
    
    private func openQuickWorkoutRoutine() {
        let index = quickWorkoutRoutineIndex()
        selectedRoutineIndex = index
        shouldOpenRoutine = true
    }
    
    private func quickWorkoutRoutineIndex() -> Int {
        if let index = userData.routines.firstIndex(where: { $0.name == "Quick Workout" }) {
            return index
        }
        
        if let oldIndex = userData.routines.firstIndex(where: { $0.name == "Quick Workouts" }) {
            userData.routines[oldIndex].name = "Quick Workout"
            return oldIndex
        }
        
        let routine = Routine(name: "Quick Workout", weekday: currentDayOfWeek, workouts: [])
        userData.routines.insert(routine, at: 0)
        return 0
    }
    
    private func addTemplate(_ template: RoutineTemplate) {
        let workouts = template.workouts.map {
            Workout(name: $0, sets: [], loggedSets: [])
        }
        let routine = Routine(name: template.title, weekday: template.weekday, workouts: workouts)
        userData.routines.append(routine)
        selectedRoutineIndex = userData.routines.count - 1
        shouldOpenRoutine = true
    }
    
    @ViewBuilder
    private func selectedRoutineDestination() -> some View {
        if let selectedRoutineIndex,
           userData.routines.indices.contains(selectedRoutineIndex) {
            RoutineDetailsView(routine: $userData.routines[selectedRoutineIndex])
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

private struct QuickStartExerciseView: View {
    @Binding var routines: [Routine]
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var selectedRoutineIndex: Int?
    @State private var selectedWorkoutIndex: Int?
    @State private var shouldOpenWorkout = false
    
    private let exercises: [Exercise] = Bundle.main.decode("exercises.json")
    
    private var filteredExercises: [Exercise] {
        guard !searchText.isEmpty else {
            return exercises
        }
        
        return exercises.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Choose an exercise")
                        .font(.title3.weight(.bold))
                    Text("Your quick workout will be saved automatically, so you can keep logging from your phone or watch.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
            
            Section {
                ForEach(filteredExercises) { exercise in
                    Button {
                        startWorkout(named: exercise.name)
                    } label: {
                        HStack {
                            Text(exercise.name)
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(Color(red: 221/255, green: 69/255, blue: 36/255))
                        }
                    }
                    .buttonStyle(.plain)
                }
            } header: {
                Text("Exercises")
            }
            
            NavigationLink(
                destination: selectedWorkoutDestination(),
                isActive: $shouldOpenWorkout
            ) {
                EmptyView()
            }
            .hidden()
        }
        .searchable(text: $searchText, prompt: "Search exercises")
        .navigationTitle("Start Workout")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
    }
    
    private func startWorkout(named exerciseName: String) {
        let routineIndex = quickWorkoutRoutineIndex()
        let workoutIndex = quickWorkoutIndex(in: routineIndex, exerciseName: exerciseName)
        selectedRoutineIndex = routineIndex
        selectedWorkoutIndex = workoutIndex
        
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        
        shouldOpenWorkout = true
    }
    
    private func quickWorkoutRoutineIndex() -> Int {
        if let index = routines.firstIndex(where: { $0.name == "Quick Workout" }) {
            return index
        }
        
        if let oldIndex = routines.firstIndex(where: { $0.name == "Quick Workouts" }) {
            routines[oldIndex].name = "Quick Workout"
            return oldIndex
        }
        
        let routine = Routine(name: "Quick Workout", weekday: currentWeekday(), workouts: [])
        routines.insert(routine, at: 0)
        return 0
    }
    
    private func quickWorkoutIndex(in routineIndex: Int, exerciseName: String) -> Int {
        if let existingWorkoutIndex = routines[routineIndex].workouts.firstIndex(where: { $0.name == exerciseName }) {
            return existingWorkoutIndex
        }
        
        routines[routineIndex].workouts.insert(
            Workout(name: exerciseName, sets: [], loggedSets: []),
            at: 0
        )
        return 0
    }
    
    private func currentWeekday() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: Date())
    }
    
    @ViewBuilder
    private func selectedWorkoutDestination() -> some View {
        if let selectedRoutineIndex,
           let selectedWorkoutIndex,
           routines.indices.contains(selectedRoutineIndex),
           routines[selectedRoutineIndex].workouts.indices.contains(selectedWorkoutIndex) {
            WorkoutDetailsView(workout: $routines[selectedRoutineIndex].workouts[selectedWorkoutIndex])
        } else {
            EmptyView()
        }
    }
}
