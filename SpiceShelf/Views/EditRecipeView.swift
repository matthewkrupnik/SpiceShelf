import SwiftUI
import PhotosUI
import CloudKit

struct EditRecipeView: View {
    @ObservedObject var viewModel: RecipeDetailViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var selectedImage: UIImage? = nil
    @State private var showCamera = false
    @State private var selectedDiets: Set<String> = []
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Basic Info")) {
                    TextField("Recipe Title", text: $viewModel.recipe.title)
                    
                    TextField("Description", text: Binding(
                        get: { viewModel.recipe.recipeDescription ?? "" },
                        set: { viewModel.recipe.recipeDescription = $0.isEmpty ? nil : $0 }
                    ), axis: .vertical)
                    .lineLimit(3...6)
                    
                    if let servings = viewModel.recipe.servings {
                        HStack {
                            Stepper("Servings: \(servings)", value: Binding(
                                get: { viewModel.recipe.servings ?? 1 },
                                set: { viewModel.recipe.servings = $0 }
                            ), in: 1...100)
                            Button(action: { viewModel.recipe.servings = nil }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                                    .frame(width: 44, height: 44)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Remove servings")
                        }
                    } else {
                        Button("Add Servings") {
                            viewModel.recipe.servings = 4
                        }
                    }
                }
                
                Section(header: Text("Notes")) {
                    TextField("Personal notes, tips, or variations...", text: Binding(
                        get: { viewModel.recipe.notes ?? "" },
                        set: { viewModel.recipe.notes = $0.isEmpty ? nil : $0 }
                    ), axis: .vertical)
                    .lineLimit(3...10)
                }
                
                Section(header: Text("Category & Cuisine")) {
                    TextField("Cuisine (e.g., Italian, Mexican)", text: Binding(
                        get: { viewModel.recipe.recipeCuisine ?? "" },
                        set: { viewModel.recipe.recipeCuisine = $0.isEmpty ? nil : $0 }
                    ))
                    TextField("Category (e.g., Dessert, Main Course)", text: Binding(
                        get: { viewModel.recipe.recipeCategory ?? "" },
                        set: { viewModel.recipe.recipeCategory = $0.isEmpty ? nil : $0 }
                    ))
                    TextField("Cooking Method (e.g., Baking, Grilling)", text: Binding(
                        get: { viewModel.recipe.cookingMethod ?? "" },
                        set: { viewModel.recipe.cookingMethod = $0.isEmpty ? nil : $0 }
                    ))
                }
                
                Section(header: Text("Time")) {
                    EditableTimePicker(label: "Prep Time", duration: $viewModel.recipe.prepTime)
                    EditableTimePicker(label: "Cook Time", duration: $viewModel.recipe.cookTime)
                    
                    if let prep = viewModel.recipe.prepTime?.totalMinutes,
                       let cook = viewModel.recipe.cookTime?.totalMinutes {
                        HStack {
                            Text("Total Time")
                            Spacer()
                            Text((prep + cook).formattedAsMinutes())
                                .foregroundColor(.secondaryText)
                        }
                    }
                }
                
                Section(header: Text("Dietary Info")) {
                    EditableDietaryPicker(suitableForDiet: $viewModel.recipe.suitableForDiet)
                }
                
                Section(header: Text("Keywords")) {
                    TagInputView(
                        tags: Binding(
                            get: { viewModel.recipe.keywords ?? [] },
                            set: { viewModel.recipe.keywords = $0.isEmpty ? nil : $0 }
                        ),
                        placeholder: "Add keyword..."
                    )
                }
                
                Section(header: Text("Yield")) {
                    TextField("e.g., 1 loaf, 24 cookies", text: Binding(
                        get: { viewModel.recipe.recipeYield ?? "" },
                        set: { viewModel.recipe.recipeYield = $0.isEmpty ? nil : $0 }
                    ))
                    .autocapitalization(.none)
                }
                
                Section(header: Text("Photo")) {
                    if let selectedImage {
                        Image(uiImage: selectedImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                    } else if viewModel.recipe.imageAsset != nil {
                        CachedAsyncImage(asset: viewModel.recipe.imageAsset, contentMode: .fit)
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
                .sheet(isPresented: $showCamera) {
                    ImagePicker(image: $selectedImage, sourceType: .camera)
                }

                Section(header: Text("Ingredients")) {
                    ForEach($viewModel.recipe.ingredients) { $ingredient in
                        IngredientEditRow(ingredient: $ingredient)
                    }
                    .onDelete { offsets in
                        viewModel.recipe.ingredients.remove(atOffsets: offsets)
                    }
                    IngredientAddRow { newIngredient in
                        viewModel.recipe.ingredients.append(newIngredient)
                    }
                }

                Section(header: Text("Instructions")) {
                    ForEach(0..<viewModel.recipe.instructionSteps.count, id: \.self) { index in
                        InstructionStepRow(
                            step: $viewModel.recipe.instructionSteps[index],
                            stepNumber: index + 1
                        )
                    }
                    .onDelete { offsets in
                        viewModel.recipe.instructionSteps.remove(atOffsets: offsets)
                    }
                    .onMove { source, destination in
                        viewModel.recipe.instructionSteps.move(fromOffsets: source, toOffset: destination)
                    }
                    Button("Add Instruction") {
                        viewModel.recipe.instructionSteps.append(HowToStep(""))
                    }
                }
                
                // Instruction Sections (for complex recipes)
                InstructionSectionsEditor(sections: Binding(
                    get: { viewModel.recipe.instructionSections ?? [] },
                    set: { viewModel.recipe.instructionSections = $0.isEmpty ? nil : $0 }
                ))
                
                // Source info (read-only)
                if viewModel.recipe.sourceURL != nil || viewModel.recipe.author != nil {
                    Section(header: Text("Source")) {
                        if let author = viewModel.recipe.author?.name {
                            HStack {
                                Text("Author")
                                Spacer()
                                Text(author)
                                    .foregroundColor(.secondaryText)
                            }
                        }
                        if let sourceURL = viewModel.recipe.sourceURL,
                           let linkURL = URL(string: sourceURL) {
                            HStack {
                                Text("Source")
                                Spacer()
                                Link(linkURL.host ?? "View", destination: linkURL)
                                    .foregroundColor(.sageGreen)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Edit Recipe")
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        if let selectedImage = selectedImage {
                            // Convert UIImage to CKAsset
                            if let data = selectedImage.jpegData(compressionQuality: 0.8) {
                                let tempDir = FileManager.default.temporaryDirectory
                                let fileName = UUID().uuidString + ".jpg"
                                let fileURL = tempDir.appendingPathComponent(fileName)
                                do {
                                    try data.write(to: fileURL)
                                    viewModel.recipe.imageAsset = CKAsset(fileURL: fileURL)
                                } catch {
                                    print("Error saving temp image: \(error)")
                                }
                            }
                        }
                        
                        // Update total time
                        updateTotalTime()
                        
                        viewModel.saveChanges()
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func updateTotalTime() {
        let prep = viewModel.recipe.prepTime?.totalMinutes ?? 0
        let cook = viewModel.recipe.cookTime?.totalMinutes ?? 0
        if prep > 0 || cook > 0 {
            viewModel.recipe.totalTime = RecipeDuration(minutes: prep + cook)
        }
    }
}

// MARK: - Helper Views

struct EditableTimePicker: View {
    let label: String
    @Binding var duration: RecipeDuration?
    
    var body: some View {
        if let currentMinutes = duration?.totalMinutes {
            HStack {
                Text(label)
                Spacer()
                Picker("", selection: Binding(
                    get: { currentMinutes },
                    set: { duration = RecipeDuration(minutes: $0) }
                )) {
                    ForEach([5, 10, 15, 20, 25, 30, 45, 60, 90, 120, 180, 240], id: \.self) { mins in
                        Text(formatTime(mins)).tag(mins)
                    }
                }
                .pickerStyle(.menu)
                
                Button(action: { duration = nil }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        } else {
            Button("Add \(label)") {
                duration = RecipeDuration(minutes: 30)
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

struct EditableDietaryPicker: View {
    @Binding var suitableForDiet: [String]?
    
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
                toggleDiet(diet.0)
            }) {
                HStack {
                    Text(diet.1)
                        .foregroundColor(.primary)
                    Spacer()
                    if suitableForDiet?.contains(diet.0) == true {
                        Image(systemName: "checkmark")
                            .foregroundColor(.sageGreen)
                    }
                }
            }
        }
    }
    
    private func toggleDiet(_ diet: String) {
        if var diets = suitableForDiet {
            if let index = diets.firstIndex(of: diet) {
                diets.remove(at: index)
                suitableForDiet = diets.isEmpty ? nil : diets
            } else {
                diets.append(diet)
                suitableForDiet = diets
            }
        } else {
            suitableForDiet = [diet]
        }
    }
}

// MARK: - Instruction Step Row

struct InstructionStepRow: View {
    @Binding var step: HowToStep
    let stepNumber: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Step name (optional title like "Preheat")
            TextField("Step title (optional)", text: Binding(
                get: { step.name ?? "" },
                set: { step.name = $0.isEmpty ? nil : $0 }
            ))
            .font(.subheadline.weight(.medium))
            .foregroundColor(.primary)
            
            // Step text (the main instruction)
            TextField("Step \(stepNumber)", text: $step.text, axis: .vertical)
                .lineLimit(2...6)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Instruction Sections Editor

struct InstructionSectionsEditor: View {
    @Binding var sections: [HowToSection]
    @State private var isExpanded = false
    
    var body: some View {
        Section {
            DisclosureGroup("Instruction Sections", isExpanded: $isExpanded) {
                if sections.isEmpty {
                    Text("Add sections to organize complex recipes (e.g., \"For the Dough\", \"For the Filling\")")
                        .font(.caption)
                        .foregroundColor(.secondaryText)
                        .padding(.vertical, 4)
                }
                
                ForEach($sections) { $section in
                    SectionEditor(section: $section)
                }
                .onDelete { offsets in
                    sections.remove(atOffsets: offsets)
                }
                
                Button(action: addSection) {
                    Label("Add Section", systemImage: "folder.badge.plus")
                }
            }
        }
    }
    
    private func addSection() {
        withAnimation {
            sections.append(HowToSection(name: "", steps: []))
            isExpanded = true
        }
        HapticStyle.light.trigger()
    }
}

struct SectionEditor: View {
    @Binding var section: HowToSection
    @State private var isExpanded = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Section name
            HStack {
                Image(systemName: "folder")
                    .foregroundColor(.sageGreen)
                TextField("Section Name", text: $section.name)
                    .font(.headline)
            }
            .padding(.vertical, 4)
            
            // Steps in this section
            DisclosureGroup("Steps (\(section.steps.count))", isExpanded: $isExpanded) {
                ForEach(0..<section.steps.count, id: \.self) { index in
                    InstructionStepRow(
                        step: $section.steps[index],
                        stepNumber: index + 1
                    )
                }
                .onDelete { offsets in
                    section.steps.remove(atOffsets: offsets)
                }
                .onMove { source, destination in
                    section.steps.move(fromOffsets: source, toOffset: destination)
                }
                
                Button("Add Step") {
                    withAnimation {
                        section.steps.append(HowToStep(""))
                    }
                }
            }
        }
        .padding(.vertical, 4)
        .padding(.leading, 8)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(.ultraThinMaterial)
        )
    }
}
