//
//  SettingsView.swift
//  WorkoutTracking3
//
//  Created by Chris Peloso on 3/10/22.
//

import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    
//    @ObservedObject var userData = UserData()
    @EnvironmentObject var userData: UserData

    
    @State private var isFileImporterPresented = false
    @State private var importError: String?
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Text("Work It Out helps you start logging quickly and keep your routines organized.")
                } header: {
                    Text("Overview")
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Tap **Start Workout** to open your **Quick Workout** routine.")
                        Text("Use **Add Workout** to choose an exercise. The workout is saved as soon as you pick it.")
                        Text("Open a workout to add sets, log progress, and review history.")
                    }
                } header: {
                    Text("Fast Start")
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("**Routine**: a collection of workouts, usually for a day.")
                        Text("**Workout**: one exercise inside a routine.")
                        Text("**Set**: reps and weight.")
                        Text("**History**: previously logged sets for a workout.")
                    }
                } header: {
                    Text("Terms")
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Routines sync between iPhone and Apple Watch.")
                        Text("Edits to workouts, sets, and history are saved automatically.")
                    }
                } header: {
                    Text("Sync")
                }
                
                Section {
                    Button(action: {
                        UserData.getUserDataJson { data in
                            if let data = data {
                                let fileUrl = FileManager.default.temporaryDirectory.appendingPathComponent("WorkItOutUserData.json")
                                do {
                                    try data.write(to: fileUrl)
                                    let activityViewController = UIActivityViewController(activityItems: [fileUrl], applicationActivities: nil)
                                    present(activityViewController)
                                } catch {
                                    print("Error saving data to file: \(error)")
                                }
                            } else {
                                print("No user data to download.")
                            }
                        }
                    }) {
                        Text("Download your data")
                    }
                    
                    Button(action: {
                        isFileImporterPresented.toggle()
                    }) {
                        Text("Upload JSON to overwrite routines")
                    }
                } header: {
                    Text("Data")
                }
                                
                if let importError = importError {
                    Text(importError)
                        .foregroundColor(.red)
                        .font(.footnote)
                }
            }
            .navigationTitle("Settings")
        }
        .navigationViewStyle(.stack)
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
                            print("🔄 Overwriting routines and saving to iCloud")
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
    
    private func present(_ viewController: UIViewController) {
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }),
              let rootViewController = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
            return
        }
        
        if let popoverController = viewController.popoverPresentationController {
            popoverController.sourceView = rootViewController.view
            popoverController.sourceRect = CGRect(
                x: rootViewController.view.bounds.midX,
                y: rootViewController.view.bounds.midY,
                width: 0,
                height: 0
            )
            popoverController.permittedArrowDirections = []
        }
        
        rootViewController.present(viewController, animated: true)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
