//
//  SettingsView.swift
//  WorkoutTracking3
//
//  Created by Chris Peloso on 3/10/22.
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                Text("This app is designed to help you monitor your workouts. \n\nIt lets you create **routines**, which are comprised of one or several workouts. You can set the day of the week that routine falls on, and you can name it as well. If you don't name the routine, it will show the day of the week selected by default. \n\n**Workouts** are comprised of an exercise, as well as one or several sets. Once created, you can add new sets and log old sets by clicking the \"new log\" button. You can view old sets by clicking the \"History\" button. \n\n**Sets** track the weight used, and the number of reps performed.")
                    .padding(.horizontal, 20)
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        
                        UserData.getUserDataJson { data in
                            
                            if let data = data {
                                
                                let fileUrl = FileManager.default.temporaryDirectory.appendingPathComponent("WorkItOutUserData.json")
                                
                                do {
                                    try data.write(to: fileUrl)
                                    
                                    let activityViewController = UIActivityViewController(activityItems: [fileUrl], applicationActivities: nil)
                                    UIApplication.shared.windows.first?.rootViewController?.present(activityViewController, animated: true, completion: nil)
                                }catch {
                                    print("Error saving data to file: \(error)")
                                }
                            }
                            else {
                                print("No user data to download.")
                            }
                            
                        }
                    }){
                        Text("Click here to download your data")
                            .foregroundColor(Color.gray)
                            .frame(alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
                            .font(.callout)
                    }
                    Spacer()
                }
                .padding(.bottom, 20)
                
            }
//            .padding(0)
            .navigationTitle("Settings")
//            .background(.red)

        }
        .navigationViewStyle(.stack)
        .background(.blue)
        .ignoresSafeArea(.all)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
