import SwiftUI

/// Common cooking measurement units
enum MeasurementUnit: String, CaseIterable {
    case none = ""
    case cup = "cup"
    case cups = "cups"
    case tablespoon = "tbsp"
    case teaspoon = "tsp"
    case ounce = "oz"
    case pound = "lb"
    case gram = "g"
    case kilogram = "kg"
    case milliliter = "ml"
    case liter = "L"
    case pinch = "pinch"
    case dash = "dash"
    case piece = "piece"
    case slice = "slice"
    case clove = "clove"
    case can = "can"
    case package = "pkg"
    case bunch = "bunch"
    case sprig = "sprig"
    case custom = "other"
    
    var displayName: String {
        switch self {
        case .none: return "—"
        case .tablespoon: return "tbsp"
        case .teaspoon: return "tsp"
        case .ounce: return "oz"
        case .pound: return "lb"
        case .gram: return "g"
        case .kilogram: return "kg"
        case .milliliter: return "ml"
        case .liter: return "L"
        case .package: return "pkg"
        case .custom: return "other..."
        default: return rawValue
        }
    }
    
    static func from(_ string: String) -> MeasurementUnit {
        let lower = string.lowercased().trimmingCharacters(in: .whitespaces)
        
        // Try exact match first
        if let match = allCases.first(where: { $0.rawValue.lowercased() == lower }) {
            return match
        }
        
        // Try common variations
        switch lower {
        case "tablespoon", "tablespoons", "tbs", "tb":
            return .tablespoon
        case "teaspoon", "teaspoons", "ts":
            return .teaspoon
        case "ounce", "ounces":
            return .ounce
        case "pound", "pounds", "lbs":
            return .pound
        case "grams", "gram":
            return .gram
        case "kilograms", "kilogram", "kgs":
            return .kilogram
        case "milliliters", "milliliter":
            return .milliliter
        case "liters", "liter", "litre", "litres":
            return .liter
        case "cloves":
            return .clove
        case "cans":
            return .can
        case "packages", "pack", "packs":
            return .package
        case "bunches":
            return .bunch
        case "sprigs":
            return .sprig
        case "pieces", "pc", "pcs":
            return .piece
        case "slices":
            return .slice
        case "pinches":
            return .pinch
        case "dashes":
            return .dash
        default:
            return lower.isEmpty ? .none : .custom
        }
    }
}

/// A row for editing an existing ingredient with structured fields
struct IngredientEditRow: View {
    @Binding var ingredient: Ingredient
    
    @State private var selectedUnit: MeasurementUnit
    @State private var customUnit: String = ""
    @State private var quantityText: String = ""
    
    init(ingredient: Binding<Ingredient>) {
        self._ingredient = ingredient
        let unit = MeasurementUnit.from(ingredient.wrappedValue.units)
        self._selectedUnit = State(initialValue: unit)
        if unit == .custom {
            self._customUnit = State(initialValue: ingredient.wrappedValue.units)
        }
        // Format quantity for display
        let qty = ingredient.wrappedValue.quantity
        if qty == 0 {
            self._quantityText = State(initialValue: "")
        } else if qty == floor(qty) {
            self._quantityText = State(initialValue: String(Int(qty)))
        } else {
            self._quantityText = State(initialValue: String(qty))
        }
    }
    
    var body: some View {
        HStack(spacing: 8) {
            // Quantity field
            TextField("Qty", text: $quantityText)
                .keyboardType(.decimalPad)
                .frame(width: 45)
                .textFieldStyle(.roundedBorder)
                .onChange(of: quantityText) { _, newValue in
                    ingredient.quantity = Double(newValue) ?? 0
                }
            
            // Unit picker
            if selectedUnit == .custom {
                TextField("unit", text: $customUnit)
                    .frame(width: 50)
                    .textFieldStyle(.roundedBorder)
                    .autocapitalization(.none)
                    .onChange(of: customUnit) { _, newValue in
                        ingredient.units = newValue
                    }
            }
            
            Menu {
                ForEach(MeasurementUnit.allCases, id: \.self) { unit in
                    Button(unit.displayName) {
                        selectedUnit = unit
                        if unit != .custom {
                            ingredient.units = unit.rawValue
                            customUnit = ""
                        }
                    }
                }
            } label: {
                HStack(spacing: 2) {
                    if selectedUnit != .custom {
                        Text(selectedUnit.displayName)
                            .frame(minWidth: 35)
                    }
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption2)
                }
                .foregroundColor(.primary)
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
                .background(Color(.systemGray6))
                .cornerRadius(6)
            }
            
            // Name field
            TextField("Ingredient name", text: $ingredient.name)
                .textFieldStyle(.roundedBorder)
        }
    }
}

/// A row for adding a new ingredient with structured fields
struct IngredientAddRow: View {
    var onAdd: (Ingredient) -> Void
    
    @State private var quantityText: String = ""
    @State private var selectedUnit: MeasurementUnit = .none
    @State private var customUnit: String = ""
    @State private var name: String = ""
    
    @FocusState private var focusedField: Field?
    
    enum Field {
        case quantity, customUnit, name
    }
    
    private var canAdd: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var body: some View {
        HStack(spacing: 8) {
            // Quantity field
            TextField("Qty", text: $quantityText)
                .keyboardType(.decimalPad)
                .frame(width: 45)
                .textFieldStyle(.roundedBorder)
                .focused($focusedField, equals: .quantity)
            
            // Unit picker or custom text field
            if selectedUnit == .custom {
                TextField("unit", text: $customUnit)
                    .frame(width: 50)
                    .textFieldStyle(.roundedBorder)
                    .autocapitalization(.none)
                    .focused($focusedField, equals: .customUnit)
            }
            
            Menu {
                ForEach(MeasurementUnit.allCases, id: \.self) { unit in
                    Button(unit.displayName) {
                        selectedUnit = unit
                        if unit == .custom {
                            customUnit = ""
                        }
                    }
                }
            } label: {
                HStack(spacing: 2) {
                    if selectedUnit != .custom {
                        Text(selectedUnit.displayName)
                            .frame(minWidth: 35)
                    }
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption2)
                }
                .foregroundColor(.primary)
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
                .background(Color(.systemGray6))
                .cornerRadius(6)
            }
            
            // Name field
            TextField("Ingredient name", text: $name)
                .textFieldStyle(.roundedBorder)
                .focused($focusedField, equals: .name)
                .onSubmit {
                    addIngredient()
                }
            
            // Add button
            Button(action: addIngredient) {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(canAdd ? .sageGreen : .gray)
            }
            .disabled(!canAdd)
        }
    }
    
    private func addIngredient() {
        guard canAdd else { return }
        
        let quantity = Double(quantityText) ?? 0
        let units = selectedUnit == .custom ? customUnit : selectedUnit.rawValue
        
        let ingredient = Ingredient(
            name: name.trimmingCharacters(in: .whitespaces),
            quantity: quantity,
            units: units
        )
        
        onAdd(ingredient)
        
        // Reset fields
        quantityText = ""
        selectedUnit = .none
        customUnit = ""
        name = ""
        focusedField = .quantity
    }
}

#Preview {
    Form {
        Section("Edit Ingredient") {
            IngredientEditRow(ingredient: .constant(Ingredient(name: "flour", quantity: 2, units: "cups")))
            IngredientEditRow(ingredient: .constant(Ingredient(name: "salt", quantity: 0.5, units: "tsp")))
            IngredientEditRow(ingredient: .constant(Ingredient(name: "olive oil", quantity: 3, units: "tbsp")))
        }
        
        Section("Add Ingredient") {
            IngredientAddRow { ingredient in
                print("Added: \(ingredient)")
            }
        }
    }
}
