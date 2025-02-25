//
//  SettingsView.swift
//  WorkoutTracking3
//
//  Created by Chris Peloso on 3/10/22.
//

import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    
    @ObservedObject var userData = UserData()
    
    @State private var isFileImporterPresented = false
    @State private var importError: String?
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                Text("This app is designed to help you monitor your workouts. \n\nIt lets you create **routines**, which are comprised of one or several workouts. You can set the day of the week that routine falls on, and you can name it as well. If you don't name the routine, it will show the day of the week selected by default. \n\n**Workouts** are comprised of an exercise, as well as one or several sets. Once created, you can add new sets and log old sets by clicking the \"new log\" button. You can view old sets by clicking the \"History\" button. \n\n**Sets** track the weight used, and the number of reps performed.")
                    .padding(.horizontal, 20)
                
                Spacer()
                
                HStack {
                    Spacer()
                    
                    // Button to download user data
                    Button(action: {
                        UserData.getUserDataJson { data in
                            if let data = data {
                                let fileUrl = FileManager.default.temporaryDirectory.appendingPathComponent("WorkItOutUserData.json")
                                do {
                                    try data.write(to: fileUrl)
                                    let activityViewController = UIActivityViewController(activityItems: [fileUrl], applicationActivities: nil)
                                    UIApplication.shared.windows.first?.rootViewController?.present(activityViewController, animated: true, completion: nil)
                                } catch {
                                    print("Error saving data to file: \(error)")
                                }
                            } else {
                                print("No user data to download.")
                            }
                        }
                    }) {
                        Text("Click here to download your data")
                            .foregroundColor(Color.gray)
                            .frame(alignment: .center)
                            .font(.callout)
                    }
                    
                    Spacer()
                }
                .padding(.bottom, 10)
                
                // Button to upload JSON file
                HStack {
                    Spacer()
                    
                    Button(action: {
                        isFileImporterPresented.toggle()
                    }) {
                        Text("Upload JSON to overwrite routines")
                            .foregroundColor(Color.blue)
                            .frame(alignment: .center)
                            .font(.callout)
                    }
                    
                    Spacer()
                }
                .padding(.bottom, 20)
                
                if let importError = importError {
                    Text(importError)
                        .foregroundColor(.red)
                        .font(.footnote)
                        .padding()
                }
            }
            .navigationTitle("Settings")
        }
        .navigationViewStyle(.stack)
        .background(.blue)
        .ignoresSafeArea(.all)
        .fileImporter(
            isPresented: $isFileImporterPresented,
            allowedContentTypes: [UTType.json],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let fileUrl = urls.first {
                    
                    let didStartAccessing = fileUrl.startAccessingSecurityScopedResource()
                    defer { if didStartAccessing { fileUrl.stopAccessingSecurityScopedResource() } }
                    
                    do {
                        let tempUrl = FileManager.default.temporaryDirectory.appendingPathComponent(fileUrl.lastPathComponent)
                        
                        if FileManager.default.fileExists(atPath: tempUrl.path) {
                            try FileManager.default.removeItem(at: tempUrl)
                        }
                        
                        try FileManager.default.copyItem(at: fileUrl, to: tempUrl)
                        let data = try Data(contentsOf: tempUrl)
                        
                        // 🔹 Try decoding as an array of routines (since your JSON is an array)
                        let decodedRoutines = try JSONDecoder().decode([Routine].self, from: data)
                        
                        DispatchQueue.main.async {
                            userData.routines = decodedRoutines
                            userData.saveToCloud()
                        }
                        
                        print("✅ Successfully replaced UserData from JSON file (array format).")
                        importError = nil
                        
                    } catch {
                        print("❌ Error loading JSON file: \(error)")
                        importError = "Error: Invalid JSON file. Check console for details."
                    }
                }
            case .failure(let error):
                print("❌ File import failed: \(error)")
                importError = "Error: Failed to import file."
            }
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
