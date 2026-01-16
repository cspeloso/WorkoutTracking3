import SwiftUI

let weekdays = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]

struct RoutineView: View {
    @EnvironmentObject var userData: UserData

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

    var body: some View {
        NavigationStack {
            List {
                ForEach(sortedRoutineIndices, id: \.self) { index in
                    let routine = userData.routines[index]

                    NavigationLink {
                        RoutineDetailsView(routine: $userData.routines[index])
                    } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(routine.name.isEmpty ? routine.weekday : routine.name)
                                .font(.headline)

                            if !routine.name.isEmpty {
                                Text(routine.weekday)
                                    .font(.subheadline)
                                    .foregroundColor(routine.weekday == currentDayOfWeek ? .green : .red)
                            }
                        }
                        .padding(.vertical, 6)
                    }
                }
                .onDelete(perform: deleteRoutine)
            }
            .navigationTitle("Routines")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        AddRoutine(routines: $userData.routines)
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }

    func deleteRoutine(at offsets: IndexSet) {
        let originalIndexes = offsets.map { sortedRoutineIndices[$0] }
        userData.routines.remove(atOffsets: IndexSet(originalIndexes))
    }
}
