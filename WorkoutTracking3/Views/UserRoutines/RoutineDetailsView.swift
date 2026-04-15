//
//  RoutineDetailsView.swift
//  WorkoutTracking3
//
//  Created by Chris Peloso on 3/9/22.
//

import SwiftUI

struct RoutineDetailsView: View {
    
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
                } header: {
                    SectionTitle("Routine Details")
                }
                .listRowInsets(EdgeInsets(top: 6, leading: 22, bottom: 6, trailing: 22))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)

                Section {
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
                                WorkoutCard(workout: routine.workouts[index], index: index + 1)
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
                } header: {
                    SectionTitle("Workouts")
                }
                .listRowInsets(EdgeInsets(top: 7, leading: 22, bottom: 7, trailing: 22))
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

    private var loggedCount: Int {
        workout.sets.count + workout.loggedSets.reduce(0) { $0 + $1.sets.count }
    }

    var body: some View {
        HStack(spacing: 16) {
            Text("\(index)")
                .font(.title3.weight(.black))
                .foregroundColor(.secondary)
                .frame(width: 48, height: 48)
                .background(AppColors.elevated)
                .cornerRadius(8)

            VStack(alignment: .leading, spacing: 6) {
                Text(workout.name)
                    .font(.title3.weight(.black))
                    .lineLimit(1)

                HStack(spacing: 14) {
                    Label("\(workout.sets.count) active", systemImage: "square.stack.3d.up.fill")
                        .foregroundColor(AppColors.accent)
                    Label("\(loggedCount) logged", systemImage: "checkmark")
                        .foregroundColor(.secondary)
                }
                .font(.subheadline.weight(.bold))
            }

            Spacer()
        }
        .padding(18)
        .background(AppColors.card)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppColors.border))
        .cornerRadius(8)
    }
}

struct RoutineDetailsView_Previews: PreviewProvider {
    
    @State static var routine = Routine(name: "", weekday: "asjdfk", workouts: [Workout(name: "asdf", sets: [Workout.Set(reps: 10, weight: 55)], loggedSets: [])])
    
    static var previews: some View {
        RoutineDetailsView(routine: $routine)
    }
}
