import SwiftUI

/// A tag input view for adding/removing keywords with a flowing layout
struct TagInputView: View {
    @Binding var tags: [String]
    var placeholder: String = "Add tag..."
    
    @State private var newTag = ""
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Display existing tags in a flowing layout
            if !tags.isEmpty {
                FlowLayout(spacing: 8) {
                    ForEach(tags, id: \.self) { tag in
                        TagChip(tag: tag) {
                            withAnimation(.spring(response: 0.3)) {
                                tags.removeAll { $0 == tag }
                            }
                            HapticStyle.light.trigger()
                        }
                    }
                }
            }
            
            // Input field for new tags
            HStack {
                TextField(placeholder, text: $newTag)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($isInputFocused)
                    .onSubmit {
                        addTag()
                    }
                
                Button(action: addTag) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(newTag.isEmpty ? .secondary : .sageGreen)
                }
                .disabled(newTag.isEmpty)
            }
        }
    }
    
    private func addTag() {
        let trimmed = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        // Avoid duplicates
        if !tags.contains(where: { $0.lowercased() == trimmed.lowercased() }) {
            withAnimation(.spring(response: 0.3)) {
                tags.append(trimmed)
            }
            HapticStyle.light.trigger()
        }
        newTag = ""
    }
}

/// A single tag chip with delete button
struct TagChip: View {
    let tag: String
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Text(tag)
                .font(.subheadline)
            
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.thinMaterial, in: Capsule())
        .foregroundColor(.primary)
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State var tags = ["Italian", "Quick", "Vegetarian"]
        
        var body: some View {
            Form {
                Section("Keywords") {
                    TagInputView(tags: $tags)
                }
            }
        }
    }
    
    return PreviewWrapper()
}
