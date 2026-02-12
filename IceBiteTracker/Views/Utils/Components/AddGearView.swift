import SwiftUI

struct AddGearView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: GearViewModel
    
    @State private var gearName = ""
    @State private var selectedCategory: GearCategory = .lure
    @State private var selectedColor: String = "4FC3F7"
    @State private var notes = ""
    @State private var showingSaved = false
    
    var editingGear: FishingGear?
    
    let colorOptions = [
        "4FC3F7", // Cyan
        "6FE3C1", // Green
        "FF8A8A", // Coral
        "FFD93D", // Yellow
        "B388FF", // Purple
        "FF6B9D", // Pink
        "4ECDC4", // Teal
        "95E1D3", // Mint
    ]
    
    init(viewModel: GearViewModel, editingGear: FishingGear? = nil) {
        self.viewModel = viewModel
        self.editingGear = editingGear
        
        if let gear = editingGear {
            _gearName = State(initialValue: gear.name)
            _selectedCategory = State(initialValue: gear.category)
            _selectedColor = State(initialValue: gear.color)
            _notes = State(initialValue: gear.notes)
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Gear Name
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Gear Name")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(AppColors.textSecondary)
                            
                            TextField("Enter gear name", text: $gearName)
                                .font(.system(size: 16))
                                .foregroundColor(AppColors.textPrimary)
                                .padding()
                                .background(AppColors.background)
                                .cornerRadius(12)
                        }
                        .padding()
                        .cardStyle()
                        
                        // Category Selection
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Category")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(AppColors.textSecondary)
                            
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                ForEach(GearCategory.allCases, id: \.self) { category in
                                    CategoryButton(
                                        category: category,
                                        isSelected: selectedCategory == category
                                    ) {
                                        withAnimation(.spring(response: 0.3)) {
                                            selectedCategory = category
                                        }
                                    }
                                }
                            }
                        }
                        .padding()
                        .cardStyle()
                        
                        // Color Selection
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Color")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(AppColors.textSecondary)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                                ForEach(colorOptions, id: \.self) { color in
                                    ColorButton(
                                        color: color,
                                        isSelected: selectedColor == color
                                    ) {
                                        withAnimation(.spring(response: 0.3)) {
                                            selectedColor = color
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
                        CustomButton(
                            title: editingGear == nil ? "Add Gear" : "Update Gear",
                            style: .primary
                        ) {
                            saveGear()
                        }
                        .disabled(gearName.isEmpty)
                        .opacity(gearName.isEmpty ? 0.5 : 1.0)
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
            .navigationTitle(editingGear == nil ? "Add Gear" : "Edit Gear")
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
    
    private func saveGear() {
        if let existing = editingGear {
            let updated = FishingGear(
                id: existing.id,
                name: gearName,
                category: selectedCategory,
                color: selectedColor,
                notes: notes,
                dateAdded: existing.dateAdded,
                isFavorite: existing.isFavorite
            )
            viewModel.updateGear(updated)
        } else {
            viewModel.addGear(
                name: gearName,
                category: selectedCategory,
                color: selectedColor,
                notes: notes
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

struct CategoryButton: View {
    let category: GearCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: category.icon)
                    .font(.system(size: 32))
                    .foregroundColor(
                        isSelected ? Color(hex: category.displayColor) : AppColors.textSecondary
                    )
                    .frame(height: 40)
                
                Text(category.rawValue)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isSelected ? AppColors.textPrimary : AppColors.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        isSelected ?
                        Color(hex: category.displayColor).opacity(0.2) :
                        AppColors.divider.opacity(0.3)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(
                        isSelected ? Color(hex: category.displayColor) : Color.clear,
                        lineWidth: 2
                    )
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ColorButton: View {
    let color: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Circle()
                .fill(Color(hex: color))
                .frame(width: 50, height: 50)
                .overlay(
                    Circle()
                        .strokeBorder(
                            isSelected ? Color.white : Color.clear,
                            lineWidth: 3
                        )
                )
                .overlay(
                    isSelected ?
                    Image(systemName: "checkmark")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    : nil
                )
                .scaleEffect(isSelected ? 1.1 : 1.0)
                .shadow(
                    color: isSelected ? Color(hex: color).opacity(0.5) : Color.clear,
                    radius: 8
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
