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
    @State private var showDeleteAllConfirmation = false
    @State private var showRestoreConfirmation = false
    
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    Text("Settings")
                        .font(.system(size: 42, weight: .black, design: .rounded))
                        .padding(.top, 28)

                    VStack(alignment: .leading, spacing: 14) {
                        SectionTitle("About")
                        SettingsInfoCard(rows: [
                            SettingsInfoRow(title: "Version", value: "1.0.0"),
                            SettingsInfoRow(title: "App Name", value: "Work It Out")
                        ])
                    }

                    VStack(alignment: .leading, spacing: 14) {
                        SectionTitle("Units")
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Weight Unit")
                                .font(.headline.weight(.black))

                            Picker("Weight Unit", selection: $userData.weightUnit) {
                                ForEach(WeightUnit.allCases) { unit in
                                    Text("\(unit.title) (\(unit.abbreviatedTitle))").tag(unit)
                                }
                            }
                            .pickerStyle(.segmented)

                            Text("Existing workout data stays unchanged. The app converts weights for display and new set entry.")
                                .font(.subheadline.weight(.bold))
                                .foregroundColor(.secondary)
                        }
                        .padding(18)
                        .background(AppColors.card)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppColors.border))
                        .cornerRadius(8)
                    }

                    VStack(alignment: .leading, spacing: 14) {
                        SectionTitle("Data")
                        VStack(spacing: 12) {
                            SettingsActionButton(title: "Download your data", systemImage: "square.and.arrow.down") {
                                exportData()
                            }

                            SettingsActionButton(title: "Upload JSON to overwrite routines", systemImage: "square.and.arrow.up") {
                                isFileImporterPresented.toggle()
                            }

                            if let backupInfo = userData.deletedDataBackupInfo {
                                SettingsActionButton(
                                    title: "Restore deleted data",
                                    subtitle: "\(backupInfo.routineCount) routine\(backupInfo.routineCount == 1 ? "" : "s") available for \(backupInfo.daysRemaining) more day\(backupInfo.daysRemaining == 1 ? "" : "s")",
                                    systemImage: "arrow.counterclockwise"
                                ) {
                                    showRestoreConfirmation = true
                                }
                            }

                            SettingsActionButton(
                                title: "Delete all data",
                                subtitle: "Keeps a restore copy for 30 days.",
                                systemImage: "trash.fill",
                                iconColor: .red
                            ) {
                                showDeleteAllConfirmation = true
                            }
                        }
                    }

                    if let importError = importError {
                        Text(importError)
                            .foregroundColor(.red)
                            .font(.footnote.weight(.semibold))
                    }

                    VStack(alignment: .leading, spacing: 14) {
                        SectionTitle("Quick Tips")
                        TipCard(icon: "hand.raised.fill", color: AppColors.accent, title: "Long press to delete", bodyText: "Hold down on routines or sets to delete them.")
                        TipCard(icon: "arrow.left.arrow.right", color: AppColors.accent, title: "Quick adjustments", bodyText: "Tap the +/- buttons to quickly adjust weight and reps.")
                        TipCard(icon: "checkmark.circle.fill", color: AppColors.accent, title: "Complete sets", bodyText: "Tap Log Set to record a set, then Complete Log to archive the workout.")
                    }
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 32)
            }
        }
        .navigationBarHidden(true)
        .alert("Delete all data?", isPresented: $showDeleteAllConfirmation) {
            Button("Delete All Data", role: .destructive) {
                userData.deleteAllDataKeepingRestoreBackup()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This clears your routines, workouts, sets, and history from the app. A restore copy will be available for 30 days.")
        }
        .alert("Restore deleted data?", isPresented: $showRestoreConfirmation) {
            Button("Restore Data") {
                userData.restoreDeletedDataBackup()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This replaces your current app data with the most recently deleted data backup.")
        }
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

    private func exportData() {
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

private struct SettingsInfoRow {
    let title: String
    let value: String
}

private struct SettingsInfoCard: View {
    let rows: [SettingsInfoRow]

    var body: some View {
        VStack(spacing: 0) {
            ForEach(rows.indices, id: \.self) { index in
                HStack {
                    Text(rows[index].title)
                        .font(.headline.weight(.bold))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(rows[index].value)
                        .font(.headline.weight(.black))
                }
                .padding(18)

                if index < rows.count - 1 {
                    Divider().background(AppColors.border)
                }
            }
        }
        .background(AppColors.card)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppColors.border))
        .cornerRadius(8)
    }
}

private struct SettingsActionButton: View {
    let title: String
    var subtitle: String?
    let systemImage: String
    var iconColor: Color = AppColors.accent
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: systemImage)
                    .font(.headline.weight(.bold))
                    .foregroundColor(iconColor)
                    .frame(width: 44, height: 44)
                    .background(AppColors.elevated)
                    .cornerRadius(8)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline.weight(.black))
                        .multilineTextAlignment(.leading)

                    if let subtitle {
                        Text(subtitle)
                            .font(.subheadline.weight(.bold))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.leading)
                    }
                }

                Spacer()
            }
            .padding(16)
            .background(AppColors.card)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppColors.border))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

private struct TipCard: View {
    let icon: String
    let color: Color
    let title: String
    let bodyText: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3.weight(.bold))
                .foregroundColor(color)
                .frame(width: 48, height: 48)
                .background(AppColors.elevated)
                .cornerRadius(8)

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.headline.weight(.black))
                Text(bodyText)
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(.secondary)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(AppColors.card)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppColors.border))
        .cornerRadius(8)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
