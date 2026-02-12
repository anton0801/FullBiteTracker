import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @State private var showingExport = false
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background.ignoresSafeArea()
                
                List {
                    // General Settings
//                    Section(header: Text("General").foregroundColor(AppColors.textSecondary)) {
//                        Picker("Time Format", selection: Binding(
//                            get: { viewModel.settings.timeFormat },
//                            set: { viewModel.updateTimeFormat($0) }
//                        )) {
//                            Text("12h").tag(AppSettings.TimeFormat.twelveHour)
//                            Text("24h").tag(AppSettings.TimeFormat.twentyFourHour)
//                        }
//                        .foregroundColor(AppColors.textPrimary)
//                        
//                        Stepper(
//                            "Bite Strength Scale: \(viewModel.settings.biteStrengthScale)",
//                            value: Binding(
//                                get: { viewModel.settings.biteStrengthScale },
//                                set: { viewModel.updateStrengthScale($0) }
//                            ),
//                            in: 3...5
//                        )
//                        .foregroundColor(AppColors.textPrimary)
//                        
//                        Stepper(
//                            "Default Session: \(viewModel.settings.defaultSessionLength)h",
//                            value: Binding(
//                                get: { viewModel.settings.defaultSessionLength },
//                                set: { viewModel.updateDefaultSessionLength($0) }
//                            ),
//                            in: 2...12
//                        )
//                        .foregroundColor(AppColors.textPrimary)
//                    }
//                    .listRowBackground(AppColors.cardBackground)
                    
                    // Export
                    Section(header: Text("Data").foregroundColor(AppColors.textSecondary)) {
                        Button(action: { showingExport = true }) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("Export Data")
                            }
                            .foregroundColor(AppColors.primaryAccent)
                        }
                    }
                    .listRowBackground(AppColors.cardBackground)
                    
                    // Danger Zone
                    Section(header: Text("Danger Zone").foregroundColor(AppColors.lowActivity)) {
                        Button(action: { viewModel.showingResetConfirmation = true }) {
                            HStack {
                                Image(systemName: "trash")
                                Text("Reset All Data")
                            }
                            .foregroundColor(AppColors.lowActivity)
                        }
                    }
                    .listRowBackground(AppColors.cardBackground)
                    
                    // About
                    Section(header: Text("About").foregroundColor(AppColors.textSecondary)) {
                        HStack {
                            Text("Version")
                            Spacer()
                            Text("1.0.0")
                                .foregroundColor(AppColors.textSecondary)
                        }
                        .foregroundColor(AppColors.textPrimary)
                    }
                    .listRowBackground(AppColors.cardBackground)
                }
                .listStyle(InsetGroupedListStyle())
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .alert("Reset All Data", isPresented: $viewModel.showingResetConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    viewModel.resetData()
                }
            } message: {
                Text("This will permanently delete all sessions and data. This action cannot be undone.")
            }
            .sheet(isPresented: $showingExport) {
                ExportView()
            }
        }
    }
}

struct ExportView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedFormat: ExportFormat = .csv
    @State private var isExporting = false
    
    enum ExportFormat: String, CaseIterable {
        case csv = "CSV"
        case json = "JSON"
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Format selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Export Format")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(AppColors.textSecondary)
                        
                        Picker("Format", selection: $selectedFormat) {
                            ForEach(ExportFormat.allCases, id: \.self) { format in
                                Text(format.rawValue).tag(format)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    .padding()
                    .cardStyle()
                    
                    Spacer()
                    
                    // Export button
                    CustomButton(title: "Export", style: .primary) {
                        exportData()
                    }
                    .padding(.horizontal)
                }
                .padding()
                
                if isExporting {
                    ZStack {
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()
                        
                        VStack(spacing: 16) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: AppColors.primaryAccent))
                                .scaleEffect(1.5)
                            
                            Text("Preparing export...")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(AppColors.textPrimary)
                        }
                        .padding(40)
                        .cardStyle()
                    }
                }
            }
            .navigationTitle("Export Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(AppColors.primaryAccent)
                }
            }
        }
    }
    
    private func exportData() {
        isExporting = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let dataManager = DataManager.shared
            let content: String
            let filename: String
            
            switch selectedFormat {
            case .csv:
                content = dataManager.exportToCSV()
                filename = "icebite_export_\(Date().timeIntervalSince1970).csv"
            case .json:
                content = dataManager.exportToJSON() ?? "{}"
                filename = "icebite_export_\(Date().timeIntervalSince1970).json"
            }
            
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
            
            do {
                try content.write(to: tempURL, atomically: true, encoding: .utf8)
                
                let activityVC = UIActivityViewController(
                    activityItems: [tempURL],
                    applicationActivities: nil
                )
                
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let rootVC = windowScene.windows.first?.rootViewController {
                    rootVC.present(activityVC, animated: true)
                }
            } catch {
                print("Export error: \(error)")
            }
            
            isExporting = false
        }
    }
}
