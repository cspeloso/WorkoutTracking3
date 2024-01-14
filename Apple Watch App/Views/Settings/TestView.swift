//
//  TestView.swift
//  Work It Out Apple Watch Watch App
//
//  Created by Chris Peloso on 1/12/24.
//

import SwiftUI


struct TestView: View {
    
    @State private var userData: UserData = UserData()
    
    var body: some View {
        VStack {
            Image("WorkItOutBanner")
                .resizable()
                .scaledToFit()
                .frame(width: 200, alignment: .center)
            
            Spacer()
            
            ForEach(userData.routines) { routine in
                getRoutineTextView(routine: routine)
            }
            
        }
    }
    
    func getRoutineTextView(routine: Routine) -> some View {
        return Text(routine.name != "" ? routine.name : routine.weekday)
                    .foregroundColor(.primary)
                    .border(.yellow)
    }
}

struct TestView_Previews: PreviewProvider {
    
    static var previews: some View {
        TestView()
    }
}
