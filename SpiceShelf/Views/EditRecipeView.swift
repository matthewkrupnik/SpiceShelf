import SwiftUI
import PhotosUI
import CloudKit

struct EditRecipeView: View {
    @ObservedObject var viewModel: RecipeDetailViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var selectedImage: UIImage? = nil
    @State private var showCamera = false

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Title & Servings")) {
                    TextField("Recipe Title", text: $viewModel.recipe.title)
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
                        HStack {
                            TextField("Name", text: $ingredient.name)
                            TextField("Quantity", value: $ingredient.quantity, format: .number)
                            TextField("Units", text: $ingredient.units)
                        }
                    }
                    .onDelete { offsets in
                        viewModel.recipe.ingredients.remove(atOffsets: offsets)
                    }
                    Button("Add Ingredient") {
                        viewModel.recipe.ingredients.append(Ingredient(id: UUID(), name: "", quantity: 1.0, units: ""))
                    }
                }

                Section(header: Text("Instructions")) {
                    ForEach(0..<viewModel.recipe.instructions.count, id: \.self) { index in
                        TextField("Step \(index + 1)", text: $viewModel.recipe.instructions[index])
                    }
                    .onDelete { offsets in
                        viewModel.recipe.instructions.remove(atOffsets: offsets)
                    }
                    Button("Add Instruction") {
                        viewModel.recipe.instructions.append("")
                    }
                }
            }
            .navigationTitle("Edit Recipe")
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
                        
                        viewModel.saveChanges()
                        dismiss()
                    }
                }
            }
        }
    }
}
