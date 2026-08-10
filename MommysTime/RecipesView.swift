import SwiftUI
import CoreData

enum RecipeCategory {
    static let all = ["Mommy", "Baby"]
}

struct RecipesView: View {
    @Environment(\.managedObjectContext) private var context
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Recipe.title, ascending: true)],
        animation: .default
    )
    private var recipes: FetchedResults<Recipe>

    @State private var category = "Mommy"
    @State private var showingAdd = false

    private var filtered: [Recipe] {
        recipes.filter { ($0.category ?? "Mommy") == category }
    }

    var body: some View {
        VStack(spacing: 0) {
            categoryPicker
            if filtered.isEmpty {
                Spacer()
                emptyState
                Spacer()
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(filtered, id: \.objectID) { recipe in
                            NavigationLink {
                                RecipeDetailView(recipe: recipe)
                            } label: {
                                RecipeCard(recipe: recipe)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Recipe")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showingAdd = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $showingAdd) {
            RecipeSheet(defaultCategory: category)
        }
    }

    private var categoryPicker: some View {
        HStack(spacing: 12) {
            ForEach(RecipeCategory.all, id: \.self) { cat in
                Button { category = cat } label: {
                    Text(cat)
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            category == cat ? Color.pink : Color.pink.opacity(0.12),
                            in: Capsule()
                        )
                        .foregroundStyle(category == cat ? .white : .pink)
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Text("🍽️")
                .font(.system(size: 56))
            Text("No \(category.lowercased()) recipes yet")
                .font(.title3.bold())
            Text(category == "Baby"
                 ? "Save purées, first foods and toddler meals here."
                 : "Save quick, nourishing meals for yourself here.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Add a recipe") { showingAdd = true }
                .buttonStyle(.bordered)
        }
        .padding(32)
    }
}

private struct RecipeCard: View {
    @ObservedObject var recipe: Recipe

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "fork.knife")
                .foregroundStyle(.pink)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 3) {
                Text(recipe.title ?? "")
                    .font(.headline)
                if recipe.prepMinutes > 0 {
                    Label("\(recipe.prepMinutes) min", systemImage: "clock")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color.pink.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
    }
}

struct RecipeDetailView: View {
    @ObservedObject var recipe: Recipe
    @State private var showingEdit = false

    private var ingredientLines: [String] {
        (recipe.ingredients ?? "")
            .split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(recipe.title ?? "")
                        .font(.largeTitle.bold())
                    HStack(spacing: 12) {
                        Label(recipe.category ?? "", systemImage: "tag")
                        if recipe.prepMinutes > 0 {
                            Label("\(recipe.prepMinutes) min", systemImage: "clock")
                        }
                    }
                    .font(.subheadline)
                    .foregroundStyle(.pink)
                }

                if !ingredientLines.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Ingredients")
                            .font(.headline)
                        ForEach(ingredientLines, id: \.self) { line in
                            Label(line, systemImage: "circle.fill")
                                .labelStyle(BulletLabelStyle())
                                .font(.body)
                        }
                    }
                }

                if let instructions = recipe.instructions, !instructions.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Instructions")
                            .font(.headline)
                        Text(instructions)
                            .font(.body)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .navigationTitle(recipe.title ?? "Recipe")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") { showingEdit = true }
            }
        }
        .sheet(isPresented: $showingEdit) {
            RecipeSheet(recipe: recipe)
        }
    }
}

private struct BulletLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            configuration.icon
                .font(.system(size: 6))
                .foregroundStyle(.pink)
            configuration.title
        }
    }
}

struct RecipeSheet: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss

    let recipe: Recipe?

    @State private var title: String
    @State private var category: String
    @State private var prepMinutes: Int
    @State private var ingredients: String
    @State private var instructions: String
    @State private var showingDeleteConfirmation = false

    init(recipe: Recipe? = nil, defaultCategory: String = "Mommy") {
        self.recipe = recipe
        _title = State(initialValue: recipe?.title ?? "")
        _category = State(initialValue: recipe?.category ?? defaultCategory)
        _prepMinutes = State(initialValue: Int(recipe?.prepMinutes ?? 0))
        _ingredients = State(initialValue: recipe?.ingredients ?? "")
        _instructions = State(initialValue: recipe?.instructions ?? "")
    }

    private var isEditing: Bool { recipe != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Recipe") {
                    TextField("Title (e.g. Banana purée)", text: $title)
                    Picker("For", selection: $category) {
                        ForEach(RecipeCategory.all, id: \.self) { Text($0).tag($0) }
                    }
                    HStack {
                        Text("Prep time")
                        Spacer()
                        TextField("0", value: $prepMinutes, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 50)
                        Text("min").foregroundStyle(.secondary)
                        Stepper("", value: $prepMinutes, in: 0...240).labelsHidden()
                    }
                }
                Section {
                    TextField("One per line…", text: $ingredients, axis: .vertical)
                        .lineLimit(4, reservesSpace: true)
                } header: {
                    Text("Ingredients")
                }
                Section("Instructions") {
                    TextField("Steps…", text: $instructions, axis: .vertical)
                        .lineLimit(5, reservesSpace: true)
                }
                if isEditing {
                    Section {
                        Button("Delete recipe", role: .destructive) {
                            showingDeleteConfirmation = true
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Recipe" : "New Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .confirmationDialog(
                "Delete this recipe?",
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) { deleteRecipe() }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    private func save() {
        let target = recipe ?? Recipe(context: context)
        if recipe == nil {
            target.id = UUID()
            target.createdAt = Date()
        }
        target.title = title.trimmingCharacters(in: .whitespaces)
        target.category = category
        target.prepMinutes = Int32(prepMinutes)
        target.ingredients = ingredients
        target.instructions = instructions
        try? context.save()
        dismiss()
    }

    private func deleteRecipe() {
        if let recipe {
            context.delete(recipe)
            try? context.save()
        }
        dismiss()
    }
}
