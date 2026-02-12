import SwiftUI

struct AddBiteView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: SessionViewModel
    
    @State private var selectedTime = Date()
    @State private var selectedStrength: BiteStrength = .medium
    @State private var selectedResult: BiteResult = .miss
    @State private var selectedGear: FishingGear? // NEW
    @State private var notes = ""
    @State private var showingSaved = false
    @State private var showingGearPicker = false // NEW
    
    var editingBite: Bite?
    
    init(viewModel: SessionViewModel, editingBite: Bite? = nil) {
        self.viewModel = viewModel
        self.editingBite = editingBite
        
        if let bite = editingBite {
            _selectedTime = State(initialValue: bite.timestamp)
            _selectedStrength = State(initialValue: bite.strength)
            _selectedResult = State(initialValue: bite.result)
            _notes = State(initialValue: bite.notes)
            
            // NEW - загружаем привязанную снасть
            if let gearId = bite.gearId {
                _selectedGear = State(initialValue: DataManager.shared.getGear(by: gearId))
            }
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
                        
                        // NEW - Gear Selection
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Fishing Gear (Optional)")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(AppColors.textSecondary)
                            
                            Button(action: { showingGearPicker = true }) {
                                HStack {
                                    if let gear = selectedGear {
                                        Image(systemName: gear.category.icon)
                                            .font(.system(size: 20))
                                            .foregroundColor(Color(hex: gear.color))
                                        
                                        Text(gear.name)
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(AppColors.textPrimary)
                                        
                                        Spacer()
                                        
                                        Button(action: { selectedGear = nil }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(AppColors.textSecondary)
                                        }
                                    } else {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 20))
                                            .foregroundColor(AppColors.primaryAccent)
                                        
                                        Text("Select Gear")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(AppColors.primaryAccent)
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(AppColors.textSecondary)
                                    }
                                }
                                .padding()
                                .background(AppColors.background)
                                .cornerRadius(12)
                            }
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
            .sheet(isPresented: $showingGearPicker) {
                GearPickerView(selectedGear: $selectedGear)
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
                notes: notes,
                gearId: selectedGear?.id // NEW
            )
            viewModel.updateBite(updated)
        } else {
            viewModel.addBite(
                strength: selectedStrength,
                result: selectedResult,
                notes: notes,
                timestamp: selectedTime,
                gearId: selectedGear?.id
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

struct BiteAlertView: View {
    @ObservedObject var program: Program
    
    var body: some View {
        GeometryReader { g in
            ZStack {
                Color.black.ignoresSafeArea()
                
                Image("bg_notification_screen")
                    .resizable()
                    .scaledToFill()
                    .frame(width: g.size.width, height: g.size.height)
                    .ignoresSafeArea()
                    .opacity(0.9)
                
                if g.size.width < g.size.height {
                    VStack(spacing: 12) {
                        Spacer()
                        
                        Text("ALLOW NOTIFICATIONS ABOUT\nBONUSES AND PROMOS")
                            .font(.system(size: 24, weight: .black))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        Text("STAY TUNED WITH BEST OFFERS FROM\nOUR CASINO")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                        
                        actionButtons
                    }
                    .padding(.bottom, 24)
                    .padding(.horizontal, 12)
                } else {
                    HStack {
                        Spacer()
                        VStack(alignment: .leading, spacing: 12) {
                            Spacer()
                            
                            Text("ALLOW NOTIFICATIONS ABOUT\nBONUSES AND PROMOS")
                                .font(.system(size: 24, weight: .black))
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .multilineTextAlignment(.leading)
                            
                            Text("STAY TUNED WITH BEST OFFERS FROM\nOUR CASINO")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white.opacity(0.7))
                                .padding(.horizontal, 12)
                                .multilineTextAlignment(.leading)
                        }
                        Spacer()
                        VStack {
                            Spacer()
                            actionButtons
                        }
                        Spacer()
                    }
                    .padding(.bottom, 24)
                }
            }
        }
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
    }
    
    private var actionButtons: some View {
        VStack(spacing: 16) {
            Button {
                program.send(.alertPermissionRequested)
            } label: {
                Image("notification_screen_btn")
                    .resizable()
                    .frame(width: 300, height: 55)
            }
            
            Button {
                program.send(.alertPromptDismissed)
            } label: {
                Text("Skip")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.4))
                    .frame(width: 260, height: 40)
                    .background(
                        Color.white.opacity(0.2)
                    )
                    .cornerRadius(52)
            }
        }
        .padding(.horizontal, 24)
    }
}


// NEW - Gear Picker Sheet
struct GearPickerView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var selectedGear: FishingGear?
    @StateObject private var viewModel = GearViewModel()
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background.ignoresSafeArea()
                
                if viewModel.dataManager.fishingGear.isEmpty {
                    VStack(spacing: 24) {
                        Image(systemName: "fork.knife.circle")
                            .font(.system(size: 60))
                            .foregroundColor(AppColors.textSecondary.opacity(0.5))
                        
                        VStack(spacing: 8) {
                            Text("No Gear Yet")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(AppColors.textPrimary)
                            
                            Text("Add gear in the Gear tab first")
                                .font(.system(size: 16))
                                .foregroundColor(AppColors.textSecondary)
                        }
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.dataManager.fishingGear) { gear in
                                GearPickerRow(gear: gear, isSelected: selectedGear?.id == gear.id)
                                    .onTapGesture {
                                        selectedGear = gear
                                        presentationMode.wrappedValue.dismiss()
                                    }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Select Gear")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(AppColors.textSecondary)
                }
            }
        }
    }
}

struct GearPickerRow: View {
    let gear: FishingGear
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: gear.category.icon)
                .font(.system(size: 24))
                .foregroundColor(Color(hex: gear.color))
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(gear.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                
                Text(gear.category.rawValue)
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.textSecondary)
            }
            
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(AppColors.primaryAccent)
                    .font(.system(size: 24))
            }
        }
        .padding()
        .background(isSelected ? AppColors.primaryAccent.opacity(0.1) : AppColors.cardBackground)
        .cornerRadius(12)
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
