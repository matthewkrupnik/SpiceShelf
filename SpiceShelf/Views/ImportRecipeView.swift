import SwiftUI

struct ImportRecipeView: View {
    @StateObject private var viewModel = ImportRecipeViewModel()
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Import from URL")) {
                    TextField("Enter URL", text: $viewModel.url)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                }

                Button("Import") {
                    viewModel.importRecipe()
                }
            }
            .navigationTitle("Import Recipe")
            .navigationBarItems(leading: Button("Cancel") {
                self.presentationMode.wrappedValue.dismiss()
            })
            .overlay(
                Group {
                    if viewModel.state == .importing {
                        ProgressView()
                    }
                }
            )
            .onChange(of: viewModel.state) { _, newState in
                if newState == .success {
                    self.presentationMode.wrappedValue.dismiss()
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
