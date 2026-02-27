import SwiftUI
import PhotosUI

@MainActor
struct AddRecipeView: View {
    @StateObject private var viewModel: AddRecipeViewModel
    @State private var title = ""
    @State private var recipeDescription = ""
    @State private var ingredients: [Ingredient] = []
    @State private var instructionSteps: [HowToStep] = [HowToStep("")]
    @State private var instructionSections: [HowToSection] = []
    @State private var servings: Int? = nil
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var selectedImage: UIImage? = nil
    @State private var showCamera = false
    
    // New fields
    @State private var recipeCuisine = ""
    @State private var recipeCategory = ""
    @State private var cookingMethod = ""
    @State private var prepTimeMinutes: Int? = nil
    @State private var cookTimeMinutes: Int? = nil
    @State private var selectedDiets: Set<String> = []
    @State private var keywords: [String] = []
    @State private var recipeYield = ""
    @State private var notes = ""
    
    @Environment(\.dismiss) private var dismiss

    

    // Allow injecting a view model (useful for tests); default will be created by the caller.
    init(viewModel: AddRecipeViewModel? = nil) {
        _viewModel = StateObject(wrappedValue: viewModel ?? AddRecipeViewModel())
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Recipe Info")) {
                    TextField("Title", text: $title)
                    
                    TextField("Description (optional)", text: $recipeDescription, axis: .vertical)
                        .lineLimit(3...6)
                    
                    if let servingsValue = servings {
                        HStack {
                            Stepper("Servings: \(servingsValue)", value: Binding(
                                get: { servings ?? 1 },
                                set: { servings = $0 }
                            ), in: 1...100)
                            Button(action: { servings = nil }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                                    .frame(width: 44, height: 44)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Remove servings")
                        }
                    } else {
                        Button("Add Servings") {
                            servings = 4
                        }
                    }
                }
                
                Section(header: Text("Notes")) {
                    TextField("Add personal notes, tips, or variations...", text: $notes, axis: .vertical)
                        .lineLimit(3...10)
                }
                
                Section(header: Text("Category & Cuisine")) {
                    TextField("Cuisine (e.g., Italian, Mexican)", text: $recipeCuisine)
                    TextField("Category (e.g., Dessert, Main Course)", text: $recipeCategory)
                    TextField("Cooking Method (e.g., Baking, Grilling)", text: $cookingMethod)
                }
                
                Section(header: Text("Time")) {
                    OptionalTimePicker(label: "Prep Time", minutes: $prepTimeMinutes)
                    OptionalTimePicker(label: "Cook Time", minutes: $cookTimeMinutes)
                    
                    if let prep = prepTimeMinutes, let cook = cookTimeMinutes {
                        HStack {
                            Text("Total Time")
                            Spacer()
                            Text((prep + cook).formattedAsMinutes())
                                .foregroundColor(.secondaryText)
                        }
                    }
                }
                
                Section(header: Text("Dietary Info")) {
                    DietaryPicker(selectedDiets: $selectedDiets)
                }
                
                Section(header: Text("Keywords")) {
                    TagInputView(tags: $keywords, placeholder: "Add keyword...")
                }
                
                Section(header: Text("Yield")) {
                    TextField("e.g., 1 loaf, 24 cookies", text: $recipeYield)
                        .autocapitalization(.none)
                }

                Section(header: Text("Photo")) {
                    if let selectedImage {
                        Image(uiImage: selectedImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                    }
                    
                    HStack {
                        PhotosPicker(selection: $selectedItem, matching: .images, photoLibrary: .shared()) {
                            Label("Library", systemImage: "photo.on.rectangle")
                        }
                        .buttonStyle(BorderedButtonStyle())
                        
                        Spacer()
                        
                        Button(action: {
                            showCamera = true
                        }) {
                            Label("Camera", systemImage: "camera")
                        }
                        .buttonStyle(BorderedButtonStyle())
                    }
                    .onChange(of: selectedItem) { _, newItem in
                        Task {
                            if let data = try? await newItem?.loadTransferable(type: Data.self),
                               let uiImage = UIImage(data: data) {
                                selectedImage = uiImage
                            }
                        }
                    }
                }

                Section(header: Text("Ingredients")) {
                    ForEach($ingredients) { $ingredient in
                        IngredientEditRow(ingredient: $ingredient)
                    }
                    .onDelete { offsets in
                        ingredients.remove(atOffsets: offsets)
                    }

                    IngredientAddRow { newIngredient in
                        ingredients.append(newIngredient)
                    }
                }

                Section(header: Text("Instructions")) {
                    ForEach(0..<instructionSteps.count, id: \.self) { index in
                        InstructionStepRow(
                            step: $instructionSteps[index],
                            stepNumber: index + 1
                        )
                    }
                    .onDelete { offsets in
                        instructionSteps.remove(atOffsets: offsets)
                    }
                    .onMove { source, destination in
                        instructionSteps.move(fromOffsets: source, toOffset: destination)
                    }
                    Button("Add Instruction") {
                        instructionSteps.append(HowToStep(""))
                    }
                }
                
                // Instruction Sections (for complex recipes)
                InstructionSectionsEditor(sections: $instructionSections)

                // Show the saved recipe title when available so UI tests can assert on it
                if let saved = viewModel.savedRecipe {
                    Section {
                        Text(saved.title)
                            .accessibilityIdentifier("SavedRecipeTitle")
                    }
                }
            }
            .navigationTitle("New Recipe")
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let nonEmptyIngredients = ingredients.filter { !$0.name.isEmpty }
                        let nonEmptySteps = instructionSteps.filter { !$0.text.isEmpty }
                        viewModel.saveRecipe(
                            title: title,
                            ingredients: nonEmptyIngredients,
                            instructionSteps: nonEmptySteps,
                            instructionSections: instructionSections.isEmpty ? nil : instructionSections,
                            servings: servings,
                            image: selectedImage,
                            recipeDescription: recipeDescription,
                            recipeCuisine: recipeCuisine,
                            recipeCategory: recipeCategory,
                            cookingMethod: cookingMethod,
                            prepTimeMinutes: prepTimeMinutes,
                            cookTimeMinutes: cookTimeMinutes,
                            suitableForDiet: Array(selectedDiets),
                            keywords: keywords.isEmpty ? nil : keywords,
                            recipeYield: recipeYield.isEmpty ? nil : recipeYield,
                            notes: notes.isEmpty ? nil : notes
                        )
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        // Observe an Equatable value (the saved recipe's id) instead of the Recipe itself so we don't
        // need Recipe to conform to Equatable. UUID is Equatable so this satisfies onChange's requirement.
        .onChange(of: viewModel.savedRecipe?.id) { _, newValue in
            if newValue != nil {
                // After a successful save, dismiss the sheet so UI tests can interact with the
                // underlying list and verify the new recipe appears.
                dismiss()
            }
        }
        .alert(isPresented: .constant(viewModel.error != nil), error: viewModel.error) {
            Button("OK") {
                viewModel.error = nil
            }
        }
        .sheet(isPresented: $showCamera) {
            ImagePicker(image: $selectedImage, sourceType: .camera)
        }
    }

}

// MARK: - Helper Views for AddRecipeView

struct OptionalTimePicker: View {
    let label: String
    @Binding var minutes: Int?
    
    var body: some View {
        if let currentMinutes = minutes {
            HStack {
                Text(label)
                Spacer()
                Picker("", selection: Binding(
                    get: { currentMinutes },
                    set: { minutes = $0 }
                )) {
                    ForEach([5, 10, 15, 20, 25, 30, 45, 60, 90, 120, 180, 240], id: \.self) { mins in
                        Text(formatTime(mins)).tag(mins)
                    }
                }
                .pickerStyle(.menu)
                
                Button(action: { minutes = nil }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        } else {
            Button("Add \(label)") {
                minutes = 30
            }
        }
    }
    
    private func formatTime(_ mins: Int) -> String {
        let hours = mins / 60
        let minutes = mins % 60
        if hours > 0 && minutes > 0 {
            return "\(hours)h \(minutes)m"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(minutes)m"
        }
    }
}

struct DietaryPicker: View {
    @Binding var selectedDiets: Set<String>
    
    let availableDiets = [
        ("VegetarianDiet", "Vegetarian"),
        ("VeganDiet", "Vegan"),
        ("GlutenFreeDiet", "Gluten-Free"),
        ("DairyFreeDiet", "Dairy-Free"),
        ("LowFatDiet", "Low Fat"),
        ("LowCalorieDiet", "Low Calorie"),
        ("KosherDiet", "Kosher"),
        ("HalalDiet", "Halal")
    ]
    
    var body: some View {
        ForEach(availableDiets, id: \.0) { diet in
            Button(action: {
                if selectedDiets.contains(diet.0) {
                    selectedDiets.remove(diet.0)
                } else {
                    selectedDiets.insert(diet.0)
                }
            }) {
                HStack {
                    Text(diet.1)
                        .foregroundColor(.primary)
                    Spacer()
                    if selectedDiets.contains(diet.0) {
                        Image(systemName: "checkmark")
                            .foregroundColor(.sageGreen)
                    }
                }
            }
        }
    }
}
