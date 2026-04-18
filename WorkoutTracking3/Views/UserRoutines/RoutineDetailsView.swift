//
//  RoutineDetailsView.swift
//  WorkoutTracking3
//
//  Created by Chris Peloso on 3/9/22.
//

import SwiftUI

struct RoutineDetailsView: View {
    
    @EnvironmentObject private var userData: UserData
    @Binding var routine: Routine
    @State private var createdWorkoutID: Workout.ID?
    @State private var activeWorkout: Workout?
    @State private var shouldShowAddWorkout = false
    @State private var shouldShowWorkout = false
    
    private let routineWeekdays = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday", ""]
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            List {
                Section {
                    HStack(alignment: .top, spacing: 14) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(routine.name.isEmpty ? "Routine" : routine.name)
                                .font(.system(size: 36, weight: .black, design: .rounded))
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                            Text(routine.weekday.isEmpty ? "No day" : routine.weekday)
                                .font(.title3.weight(.black))
                                .foregroundColor(AppColors.accent)
                        }

                        Spacer()

                        Button {
                            shouldShowAddWorkout = true
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
                }
                .listRowInsets(EdgeInsets(top: 18, leading: 22, bottom: 8, trailing: 22))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)

                Section {
                    SectionTitle("Routine Details")

                    TextField("Routine Name", text: $routine.name)
                        .font(.headline.weight(.bold))
                        .padding(16)
                        .background(AppColors.card)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppColors.border))
                        .cornerRadius(8)

                    Picker("Weekday", selection: $routine.weekday) {
                        ForEach(routineWeekdays, id: \.self) { weekday in
                            Text(weekday.isEmpty ? "No day" : weekday).tag(weekday)
                        }
                    }
                    .pickerStyle(.menu)
                    .font(.headline.weight(.bold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(AppColors.card)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppColors.border))
                    .cornerRadius(8)
                }
                .listRowInsets(EdgeInsets(top: 6, leading: 22, bottom: 6, trailing: 22))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)

                Section {
                    SectionTitle("Workouts")

                    if routine.workouts.isEmpty {
                        Button {
                            shouldShowAddWorkout = true
                        } label: {
                            EmptyWorkoutsCTA()
                        }
                        .buttonStyle(.plain)
                    } else {
                        ForEach(routine.workouts.indices, id: \.self) { index in
                            Button {
                                activeWorkout = routine.workouts[index]
                                shouldShowWorkout = true
                            } label: {
                                WorkoutCard(
                                    workout: routine.workouts[index],
                                    index: index + 1,
                                    loggedCount: loggedSetCount(for: routine.workouts[index])
                                )
                            }
                            .buttonStyle(.plain)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    routine.workouts.remove(at: index)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                        .onMove(perform: moveWorkout)
                    }
                }
                .listRowInsets(EdgeInsets(top: 7, leading: 22, bottom: 7, trailing: 22))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)

                Section {
                    SectionTitle("Manage")

                    Button {
                        routine.isArchived.toggle()
                    } label: {
                        Label(
                            routine.isArchived ? "Unarchive Routine" : "Archive Routine",
                            systemImage: routine.isArchived ? "archivebox.fill" : "archivebox"
                        )
                        .font(.headline.weight(.black))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .foregroundColor(routine.isArchived ? .white : AppColors.accent)
                        .background(routine.isArchived ? AppColors.today : AppColors.card)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppColors.border))
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
                .listRowInsets(EdgeInsets(top: 0, leading: 22, bottom: 24, trailing: 22))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
            .listStyle(.plain)
            .hideScrollContentBackgroundIfAvailable()
            
            NavigationLink(
                destination: AddWorkoutView(
                    workouts: $routine.workouts,
                    createdWorkoutID: $createdWorkoutID
                ),
                isActive: $shouldShowAddWorkout
            ) {
                EmptyView()
            }
            .hidden()
            
            NavigationLink(
                destination: activeWorkoutDestination(),
                isActive: $shouldShowWorkout
            ) {
                EmptyView()
            }
            .hidden()
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            EditButton()
        }
        .onChange(of: createdWorkoutID) { newID in
            guard let newID else {
                return
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                guard routine.workouts.contains(where: { $0.id == newID }) else {
                    createdWorkoutID = nil
                    return
                }
                
                activeWorkout = routine.workouts.first(where: { $0.id == newID })
                shouldShowWorkout = activeWorkout != nil
                createdWorkoutID = nil
            }
        }
    }

    @ViewBuilder
    private func activeWorkoutDestination() -> some View {
        if let activeWorkout {
            WorkoutDetailsRoute(routine: $routine, workout: activeWorkout)
        } else {
            EmptyView()
        }
    }
    
    func deleteWorkout(at offsets: IndexSet){
        routine.workouts.remove(atOffsets: offsets)
    }
    func moveWorkout(from source: IndexSet, to destination: Int){
        routine.workouts.move(fromOffsets: source, toOffset: destination)
    }

    private func loggedSetCount(for workout: Workout) -> Int {
        let normalizedWorkoutName = workout.name.normalizedExerciseName
        var matchingWorkouts = userData.routines
            .flatMap(\.workouts)
            .filter { $0.name.normalizedExerciseName == normalizedWorkoutName }

        matchingWorkouts.removeAll { localWorkout in
            routine.workouts.contains(where: { $0.id == localWorkout.id })
        }
        matchingWorkouts.append(contentsOf: routine.workouts.filter { $0.name.normalizedExerciseName == normalizedWorkoutName })

        return matchingWorkouts
            .flatMap(\.loggedSets)
            .reduce(0) { $0 + $1.sets.count }
    }
}

private struct WorkoutDetailsRoute: View {
    @Binding var routine: Routine
    let workoutID: Workout.ID
    @State private var workout: Workout

    init(routine: Binding<Routine>, workout: Workout) {
        self._routine = routine
        self.workoutID = workout.id
        self._workout = State(initialValue: workout)
    }

    var body: some View {
        WorkoutDetailsView(workout: $workout)
            .onChange(of: workout) { updatedWorkout in
                syncWorkout(updatedWorkout)
            }
            .onAppear {
                if let latestWorkout = routine.workouts.first(where: { $0.id == workoutID }),
                   latestWorkout != workout {
                    workout = latestWorkout
                }
            }
    }

    private func syncWorkout(_ updatedWorkout: Workout) {
        guard let index = routine.workouts.firstIndex(where: { $0.id == workoutID }) else {
            return
        }

        if routine.workouts[index] != updatedWorkout {
            routine.workouts[index] = updatedWorkout
        }
    }
}

private struct EmptyWorkoutsCTA: View {
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Add your first workout")
                    .font(.headline)
                
                Text("Choose an exercise, then start logging sets right away.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Label("Add Workout", systemImage: "plus.circle.fill")
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .foregroundColor(.white)
                .background(AppColors.success)
                .cornerRadius(8)
        }
        .padding(18)
        .background(AppColors.card)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppColors.border))
        .cornerRadius(8)
    }
}

private struct WorkoutCard: View {
    let workout: Workout
    let index: Int
    let loggedCount: Int

    var body: some View {
        HStack(spacing: 12) {
            Text("\(index)")
                .font(.title3.weight(.black))
                .foregroundColor(.secondary)
                .frame(width: 42, height: 52)
                .background(AppColors.elevated)
                .cornerRadius(8)

            VStack(alignment: .leading, spacing: 12) {
                Text(workout.name)
                    .font(.title3.weight(.black))
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)

                HStack(spacing: 8) {
                    WorkoutStatChip(
                        value: "\(workout.sets.count)",
                        label: "active",
                        systemImage: "square.stack.3d.up.fill",
                        color: AppColors.accent,
                        minWidth: 84
                    )

                    WorkoutStatChip(
                        value: "\(loggedCount)",
                        label: "logged",
                        systemImage: "checkmark",
                        color: .secondary,
                        minWidth: 98
                    )
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.headline.weight(.bold))
                .foregroundColor(.secondary.opacity(0.6))
        }
        .padding(16)
        .background(AppColors.card)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppColors.border))
        .cornerRadius(8)
    }
}

private struct WorkoutStatChip: View {
    let value: String
    let label: String
    let systemImage: String
    let color: Color
    let minWidth: CGFloat

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.caption.weight(.black))
                .foregroundColor(color)

            Text(value)
                .font(.caption.weight(.black))
                .foregroundColor(color == .secondary ? .secondary : color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(label)
                .font(.caption.weight(.bold))
                .foregroundColor(color == .secondary ? .secondary : color)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 7)
        .frame(minWidth: minWidth, alignment: .leading)
        .background(AppColors.elevated)
        .cornerRadius(8)
    }
}

struct RoutineDetailsView_Previews: PreviewProvider {
    
    @State static var routine = Routine(name: "", weekday: "asjdfk", workouts: [Workout(name: "asdf", sets: [Workout.Set(reps: 10, weight: 55)], loggedSets: [])])
    
    static var previews: some View {
        RoutineDetailsView(routine: $routine)
    }
}
