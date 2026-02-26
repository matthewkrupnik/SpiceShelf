import SwiftUI

struct ImportRecipeView: View {
    @StateObject private var viewModel: ImportRecipeViewModel
    @Environment(\.dismiss) private var dismiss

    init(initialURL: String? = nil) {
        let vm = ImportRecipeViewModel()
        if let initialURL {
            vm.url = initialURL
        }
        _viewModel = StateObject(wrappedValue: vm)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Import from URL")) {
                    TextField("Enter URL", text: $viewModel.url)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                        .accessibilityLabel("Recipe URL")
                        .accessibilityHint("Enter the web address of a recipe to import")
                }

                Button("Import") {
                    viewModel.importRecipe()
                }
                .accessibilityHint("Imports recipe from the URL entered above")
            }
            .navigationTitle("Import Recipe")
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .overlay(
                Group {
                    if viewModel.state == .importing {
                        ProgressView()
                    }
                }
            )
            .onChange(of: viewModel.state) { _, newState in
                if newState == .success {
                    dismiss()
                }
            }
            .alert(isPresented: .constant(viewModel.error != nil), error: viewModel.error) {
                Button("OK") {
                    viewModel.error = nil
                }
            }
        }
    }
}
