
import SwiftUI

struct ImportRecipeView: View {
    @StateObject var viewModel = ImportRecipeViewModel()
    
    var body: some View {
        VStack {
            TextField("URL", text: $viewModel.urlString)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            Button(action: {
                viewModel.importRecipe()
            }) {
                Text("Import Recipe")
            }
            
            if viewModel.isImporting {
                ProgressView()
            }
            
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
            }
            
            Spacer()
        }
        .navigationTitle("Import Recipe")
    }
}
