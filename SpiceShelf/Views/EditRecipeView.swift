import SwiftUI
import PhotosUI
import CloudKit

struct EditRecipeView: View {
    @ObservedObject var viewModel: RecipeDetailViewModel
    @Environment(\.presentationMode) var presentationMode

    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var selectedImage: UIImage? = nil
    @State private var showCamera = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Title & Servings")) {
                    TextField("Recipe Title", text: $viewModel.recipe.title)
                    Stepper("Servings: \(viewModel.recipe.servings)", value: $viewModel.recipe.servings, in: 1...100)
                }
                
                Section(header: Text("Photo")) {
                    if let selectedImage {
                        Image(uiImage: selectedImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                    } else if let imageAsset = viewModel.recipe.imageAsset,
                              let fileURL = imageAsset.fileURL,
                              let data = try? Data(contentsOf: fileURL),
                              let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
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
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
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
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}
