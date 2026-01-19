import SwiftUI
import PhotosUI

@MainActor
struct AddRecipeView: View {
    @StateObject private var viewModel: AddRecipeViewModel
    @State private var title = ""
    @State private var ingredients: [Ingredient] = []
    @State private var instructions: [String] = [""]
    @State private var servings: Int? = nil
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var selectedImage: UIImage? = nil
    @State private var showCamera = false
    @Environment(\.dismiss) private var dismiss

    @State private var newIngredientText = ""

    // Allow injecting a view model (useful for tests); default will be created by the caller.
    init(viewModel: AddRecipeViewModel? = nil) {
        _viewModel = StateObject(wrappedValue: viewModel ?? AddRecipeViewModel())
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Recipe Info")) {
                    TextField("Title", text: $title)
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
                        // Editable view for ingredients
                        HStack {
                            TextField("Qty", value: $ingredient.quantity, format: .number)
                                .keyboardType(.decimalPad)
                                .frame(width: 50)

                            TextField("Unit", text: $ingredient.units)
                                .frame(width: 60)
                                .autocapitalization(.none)

                            TextField("Name", text: $ingredient.name)
                        }
                    }
                    .onDelete { offsets in
                        ingredients.remove(atOffsets: offsets)
                    }

                    HStack {
                        TextField("e.g. 2 cups flour", text: $newIngredientText)
                            .onSubmit {
                                addSmartIngredient()
                            }
                            .accessibilityIdentifier("SmartIngredientField")
                        Button(action: addSmartIngredient) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.sageGreen)
                        }
                        .disabled(newIngredientText.isEmpty)
                        .accessibilityIdentifier("AddIngredientButton")
                    }
                }

                Section(header: Text("Instructions")) {
                    ForEach(0..<instructions.count, id: \.self) { index in
                        TextField("Step \(index + 1)", text: $instructions[index])
                    }
                    Button("Add Instruction") {
                        instructions.append("")
                    }
                }

                // Show the saved recipe title when available so UI tests can assert on it
                if let saved = viewModel.savedRecipe {
                    Section {
                        Text(saved.title)
                            .accessibilityIdentifier("SavedRecipeTitle")
                    }
                }
            }
            .navigationTitle("New Recipe")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let nonEmptyIngredients = ingredients.filter { !$0.name.isEmpty }
                        let nonEmptyInstructions = instructions.filter { !$0.isEmpty }
                        viewModel.saveRecipe(
                            title: title,
                            ingredients: nonEmptyIngredients,
                            instructions: nonEmptyInstructions,
                            servings: servings,
                            image: selectedImage
                        )
                    }
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

    private func addSmartIngredient() {
        guard !newIngredientText.isEmpty else { return }
        let ingredient = RecipeParserService.parseIngredientString(newIngredientText)
        ingredients.append(ingredient)
        newIngredientText = ""
    }
}
