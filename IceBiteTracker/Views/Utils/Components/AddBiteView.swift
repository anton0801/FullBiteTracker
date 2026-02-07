import SwiftUI

struct AddBiteView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: SessionViewModel
    
    @State private var selectedTime = Date()
    @State private var selectedStrength: BiteStrength = .medium
    @State private var selectedResult: BiteResult = .miss
    @State private var notes = ""
    @State private var showingSaved = false
    
    var editingBite: Bite?
    
    init(viewModel: SessionViewModel, editingBite: Bite? = nil) {
        self.viewModel = viewModel
        self.editingBite = editingBite
        
        if let bite = editingBite {
            _selectedTime = State(initialValue: bite.timestamp)
            _selectedStrength = State(initialValue: bite.strength)
            _selectedResult = State(initialValue: bite.result)
            _notes = State(initialValue: bite.notes)
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Time Picker
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Time")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(AppColors.textSecondary)
                            
                            DatePicker("", selection: $selectedTime, displayedComponents: [.hourAndMinute])
                                .datePickerStyle(WheelDatePickerStyle())
                                .labelsHidden()
                                .colorScheme(.dark)
                        }
                        .padding()
                        .cardStyle()
                        
                        // Bite Strength
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Bite Strength")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(AppColors.textSecondary)
                            
                            HStack(spacing: 12) {
                                ForEach(BiteStrength.allCases, id: \.self) { strength in
                                    StrengthButton(
                                        strength: strength,
                                        isSelected: selectedStrength == strength
                                    ) {
                                        withAnimation(.spring(response: 0.3)) {
                                            selectedStrength = strength
                                        }
                                    }
                                }
                            }
                        }
                        .padding()
                        .cardStyle()
                        
                        // Result
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Result")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(AppColors.textSecondary)
                            
                            HStack(spacing: 12) {
                                ForEach(BiteResult.allCases, id: \.self) { result in
                                    ResultButton(
                                        result: result,
                                        isSelected: selectedResult == result
                                    ) {
                                        withAnimation(.spring(response: 0.3)) {
                                            selectedResult = result
                                        }
                                    }
                                }
                            }
                        }
                        .padding()
                        .cardStyle()
                        
                        // Notes
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Notes (Optional)")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(AppColors.textSecondary)
                            
                            TextEditor(text: $notes)
                                .frame(height: 100)
                                .padding(8)
                                .background(AppColors.background)
                                .cornerRadius(8)
                                .foregroundColor(AppColors.textPrimary)
                        }
                        .padding()
                        .cardStyle()
                        
                        // Save Button
                        CustomButton(title: editingBite == nil ? "Save Bite" : "Update Bite", style: .primary) {
                            saveBite()
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                    }
                    .padding()
                }
                
                if showingSaved {
                    SavedIndicator()
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .navigationTitle(editingBite == nil ? "Add Bite" : "Edit Bite")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(AppColors.textSecondary)
                }
            }
        }
    }
    
    private func saveBite() {
        if let existing = editingBite {
            let updated = Bite(
                id: existing.id,
                timestamp: selectedTime,
                strength: selectedStrength,
                result: selectedResult,
                notes: notes
            )
            viewModel.updateBite(updated)
        } else {
            viewModel.addBite(
                strength: selectedStrength,
                result: selectedResult,
                notes: notes,
                timestamp: selectedTime
            )
        }
        
        withAnimation {
            showingSaved = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            presentationMode.wrappedValue.dismiss()
        }
    }
}

struct StrengthButton: View {
    let strength: BiteStrength
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Circle()
                    .fill(
                        isSelected ?
                        LinearGradient(
                            colors: [Color(hex: strength.color), Color(hex: strength.color).opacity(0.6)],
                            startPoint: .top,
                            endPoint: .bottom
                        ) :
                        LinearGradient(
                            colors: [AppColors.divider, AppColors.divider],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 60, height: 60)
                    .overlay(
                        Circle()
                            .strokeBorder(
                                isSelected ? Color(hex: strength.color) : Color.clear,
                                lineWidth: 3
                            )
                    )
                    .scaleEffect(isSelected ? 1.1 : 1.0)
                
                Text(strength.displayName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isSelected ? AppColors.textPrimary : AppColors.textSecondary)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ResultButton: View {
    let result: BiteResult
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: result.icon)
                    .font(.system(size: 28))
                    .foregroundColor(isSelected ? AppColors.primaryAccent : AppColors.textSecondary)
                    .frame(width: 60, height: 60)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isSelected ? AppColors.primaryAccent.opacity(0.2) : AppColors.divider.opacity(0.5))
                    )
                    .scaleEffect(isSelected ? 1.1 : 1.0)
                
                Text(result.displayName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isSelected ? AppColors.textPrimary : AppColors.textSecondary)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SavedIndicator: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(AppColors.highActivity)
            
            Text("Saved!")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(AppColors.textPrimary)
        }
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(AppColors.cardBackground)
                .shadow(color: Color.black.opacity(0.3), radius: 20)
        )
    }
}
