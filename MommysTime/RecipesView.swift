import SwiftUI
import CoreData

enum RecipeCategory {
    static let all = ["Mommy", "Baby"]
}

struct RecipesView: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Recipe.createdAt, ascending: false)],
        animation: .default
    )
    private var recipes: FetchedResults<Recipe>

    @State private var category = "Mommy"
    @State private var showingAdd = false
    @State private var toast: String?

    private var filtered: [Recipe] {
        recipes.filter { ($0.category ?? "Mommy") == category }
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    heroCard
                    tabControl.padding(.top, 10)
                    caption.padding(.top, 16)

                    if filtered.isEmpty {
                        emptyState
                    } else {
                        VStack(spacing: 9) {
                            ForEach(filtered, id: \.objectID) { recipe in
                                NavigationLink {
                                    RecipeDetailView(recipe: recipe)
                                } label: {
                                    RecipeRow(recipe: recipe)
                                }
                                .buttonStyle(LiftRowStyle())
                            }
                        }
                        .padding(.top, 12)
                    }
                }
                .padding(.top, 18)
                .padding(.horizontal, 18)
                .padding(.bottom, 120)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(RC.screenBg.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showingAdd) {
            RecipeSheet(defaultCategory: category) { savedCategory, name in
                category = savedCategory
                showToast("\(name) saved")
            }
        }
        .overlay(alignment: .bottom) {
            if let toast {
                Toast(text: toast)
                    .padding(.bottom, 120)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .onAppear(perform: seedIfNeeded)
    }

    /// Blush panel over the list: what this collection is for, and the one
    /// action the screen exists to offer.
    private var heroCard: some View {
        VStack(spacing: 0) {
            Image("recipes")
                .renderingMode(.template).resizable().scaledToFit()
                .frame(width: 20, height: 20)
                .foregroundStyle(Theme.tileGlyph)
                .frame(width: 38, height: 38)
                .background(.white, in: Circle())
                .padding(.bottom, 8)

            Text(category == "Baby" ? "First foods, sorted" : "Real meals, fast")
                .font(.baloo(20, heavy: true))
                .foregroundStyle(Theme.roseInk)

            HStack(spacing: 6) {
                Text("Cooking for")
                    .font(.nunito(13, .bold))
                    .foregroundStyle(Theme.roseMuted)
                Text(category == "Baby" ? "baby" : "you")
                    .font(.nunito(13, .heavy))
                    .foregroundStyle(Theme.roseAccentText)
                    .padding(.vertical, 2).padding(.horizontal, 9)
                    .background(.white, in: Capsule())
            }
            .padding(.top, 4)

            Button { showingAdd = true } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus").font(.system(size: 15, weight: .bold))
                    Text("Add your own recipe").font(.baloo(16))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Theme.tileGlyph, in: Capsule())
                .shadow(color: Color(hex: 0xBE5F78).opacity(0.34), radius: 9, y: 8)
            }
            .buttonStyle(.plain)
            .padding(.top, 14)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14).padding(.horizontal, 20)
        .background(RC.roseFill, in: RoundedRectangle(cornerRadius: 28))
    }

    private var caption: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(category == "Baby" ? "For baby" : "For you")
                .font(.baloo(19, heavy: true))
                .foregroundStyle(Theme.ink)
            Text(category == "Baby"
                 ? "Gentle first tastes that freeze well in cubes."
                 : "One pot, few steps, nothing that needs two hands.")
                .font(.nunito(12.5, .semibold))
                .foregroundStyle(Theme.inkFaint)
        }
        .padding(.horizontal, 2)
    }

    private func showToast(_ message: String) {
        withAnimation { toast = message }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            withAnimation { toast = nil }
        }
    }

    private var header: some View {
        ZStack {
            Text("Recipes")
                .font(.baloo(19, heavy: true))
                .foregroundStyle(RC.textPrimary)
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(RC.backIcon)
                        .frame(width: 38, height: 38)
                        .background(.white, in: Circle())
                        .shadow(color: Color(hex: 0x7A6248).opacity(0.12), radius: 10, y: 3)
                }
                .buttonStyle(.plain)
                Spacer()
                Color.clear.frame(width: 38, height: 38)
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 8)
    }

    private var tabControl: some View {
        HStack(spacing: 5) {
            ForEach(RecipeCategory.all, id: \.self) { cat in
                let sel = category == cat
                Button { withAnimation(.easeInOut(duration: 0.2)) { category = cat } } label: {
                    Text(cat)
                        .font(.nunito(12.5, .heavy))
                        .foregroundStyle(sel ? Theme.roseText : Theme.inkFaint)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background {
                            if sel {
                                Capsule().fill(.white)
                                    .shadow(color: Color(hex: 0x7A6248).opacity(0.14), radius: 4, y: 2)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Theme.field, in: Capsule())
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Text("No \(category.lowercased()) recipes yet")
                .font(.baloo(20, heavy: true))
                .foregroundStyle(RC.textPrimary)
            Text(category == "Baby"
                 ? "Save purées, first foods and toddler meals here."
                 : "Save quick, nourishing meals for yourself here.")
                .font(.nunito(15))
                .foregroundStyle(RC.textMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
        .padding(.horizontal, 24)
    }

    /// Seeds the four default premium recipes the first time the screen opens.
    private func seedIfNeeded() {
        guard recipes.isEmpty else { return }
        let seed: [(String, String, Int, String)] = [
            ("15-min oat bowl", "Mommy", 15, "one pot"),
            ("One-pot chicken porridge", "Mommy", 30, "freezer friendly"),
            ("Sweet potato mash", "Baby", 10, "6m+"),
            ("Banana oat fingers", "Baby", 20, "8m+"),
        ]
        // Descending sort → assign earlier timestamps to later items so the
        // seed array order is preserved, and any custom recipe added later
        // (newer timestamp) lands above them all.
        let base = Date()
        for (i, item) in seed.enumerated() {
            let r = Recipe(context: context)
            r.id = UUID()
            r.createdAt = base.addingTimeInterval(-Double(i))
            r.title = item.0
            r.category = item.1
            r.prepMinutes = Int32(item.2)
            r.tag = item.3
        }
        try? context.save()
    }
}

private struct RecipeRow: View {
    @ObservedObject var recipe: Recipe

    private var meta: String {
        var parts: [String] = []
        if recipe.prepMinutes > 0 { parts.append("\(recipe.prepMinutes) min") }
        if let tag = recipe.tag, !tag.isEmpty { parts.append(tag) }
        return parts.joined(separator: " · ")
    }

    var body: some View {
        HStack(spacing: 13) {
            RoundedRectangle(cornerRadius: 16)
                .fill(RC.roseFill)
                .frame(width: 46, height: 46)
                .overlay(
                    Image(systemName: "fork.knife")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(RC.roseAccent.opacity(0.6))
                )
            VStack(alignment: .leading, spacing: 2) {
                Text(recipe.title ?? "")
                    .font(.nunito(15.5, .heavy))
                    .foregroundStyle(RC.textPrimary)
                if !meta.isEmpty {
                    Text(meta)
                        .font(.nunito(12, .bold))
                        .foregroundStyle(RC.textMuted)
                }
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(RC.chevron)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white, in: RoundedRectangle(cornerRadius: 24))
        .shadow(color: Color(hex: 0x7A6248).opacity(0.09), radius: 14, y: 5)
    }
}

/// Lifts a recipe row slightly while pressed.
private struct LiftRowStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .offset(y: configuration.isPressed ? -2 : 0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Recipes palette

private enum RC {
    static let screenBg = Color(hex: 0xFFF8EE)
    static let textPrimary = Color(hex: 0x4A423B)
    static let textMuted = Color(hex: 0x9A8D80)
    static let roseFill = Color(hex: 0xF6E6E9)
    static let roseAccent = Color(hex: 0xD98FA0)
    static let roseText = Color(hex: 0xC08497)
    static let chevron = Color(hex: 0xC6B9AA)
    static let backIcon = Color(hex: 0x8B7F72)
}

struct RecipeDetailView: View {
    @ObservedObject var recipe: Recipe
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var servings: Int = 1
    @State private var checkedIngredients: Set<Int> = []
    @State private var doneSteps: Set<Int> = []
    @State private var toast: String?

    private var content: RecipeContent { RecipeContent.forTitle(recipe.title, recipe: recipe) }
    private var allStepsDone: Bool { !content.steps.isEmpty && doneSteps.count == content.steps.count }

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    heroCard
                    if !content.why.isEmpty { whyNote.padding(.top, 10) }

                    ingredientsHeader.padding(.top, 16).padding(.bottom, 8)
                    ingredientsCard

                    sectionLabel("METHOD").padding(.top, 16).padding(.bottom, 8)
                    methodList

                    primaryCTA.padding(.top, 18)
                    ctaHint.padding(.top, 8)
                }
                .padding(.top, 14)
                .padding(.horizontal, 18)
                .padding(.bottom, 150)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(RD.screenBg.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .overlay(alignment: .bottom) {
            if let toast {
                Toast(text: toast)
                    .padding(.bottom, 120)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .onAppear { servings = max(1, content.baseYield) }
    }

    // MARK: Header

    private var header: some View {
        ZStack {
            Text(recipe.title ?? "Recipe")
                .font(.baloo(19, heavy: true))
                .foregroundStyle(RD.textPrimary)
                .lineLimit(1)
                .padding(.horizontal, 56)
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Color(hex: 0x8B7F72))
                        .frame(width: 38, height: 38)
                        .background(.white, in: Circle())
                        .shadow(color: Color(hex: 0x7A6248).opacity(0.12), radius: 10, y: 3)
                }
                .buttonStyle(.plain)
                Spacer()
                Color.clear.frame(width: 38, height: 38)
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 8)
    }

    // MARK: Hero card

    private var heroCard: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(content.tag)
                        .font(.nunito(12, .heavy)).tracking(1)
                        .foregroundStyle(RD.roseTag)
                    Text(recipe.title ?? "")
                        .font(.baloo(22, heavy: true))
                        .foregroundStyle(RD.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                Button { toggleSaved() } label: {
                    Image(systemName: recipe.isSaved ? "heart.fill" : "heart")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(recipe.isSaved ? .white : RD.roseAccent)
                        .frame(width: 38, height: 38)
                        .background(recipe.isSaved ? RD.roseCTA : .white, in: Circle())
                        .shadow(color: Color(hex: 0x7A6248).opacity(0.12), radius: 12, y: 4)
                }
                .buttonStyle(.plain)
            }

            if !content.facts.isEmpty {
                HStack(spacing: 8) {
                    ForEach(Array(content.facts.enumerated()), id: \.offset) { _, fact in
                        VStack(spacing: 1) {
                            Text(fact.value).font(.baloo(15, heavy: true)).foregroundStyle(RD.roseAccent)
                            Text(fact.label).font(.nunito(10.5, .bold)).foregroundStyle(RD.textMuted)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10).padding(.horizontal, 8)
                        .background(.white, in: RoundedRectangle(cornerRadius: 18))
                    }
                }
                .padding(.top, 12)
            }
        }
        .padding(.vertical, 15).padding(.horizontal, 18)
        .background(RD.roseFill, in: RoundedRectangle(cornerRadius: 26))
    }

    private var whyNote: some View {
        Text(content.why)
            .font(.nunito(12.5, .bold)).lineSpacing(5)
            .foregroundStyle(RD.noteText)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 12).padding(.horizontal, 16)
            .background(RD.noteBg, in: RoundedRectangle(cornerRadius: 22))
    }

    // MARK: Ingredients

    private var ingredientsHeader: some View {
        HStack {
            Text("INGREDIENTS")
                .font(.nunito(12, .heavy)).tracking(0.8)
                .foregroundStyle(RD.textMuted)
            Spacer()
            HStack(spacing: 0) {
                Button { servings = max(1, servings - 1) } label: {
                    Text("−").font(.nunito(15, .heavy)).foregroundStyle(Color(hex: 0x8A7E72)).frame(width: 32, height: 28)
                }
                .buttonStyle(.plain)
                Text(content.yieldLabel(servings))
                    .font(.nunito(12, .heavy)).foregroundStyle(Color(hex: 0x6E6358)).frame(minWidth: 74)
                Button { servings = min(12, servings + 1) } label: {
                    Text("+").font(.nunito(15, .heavy)).foregroundStyle(RD.roseAccent).frame(width: 32, height: 28)
                }
                .buttonStyle(.plain)
            }
            .background(RD.fieldFill, in: Capsule())
        }
    }

    private var ingredientsCard: some View {
        VStack(spacing: 0) {
            ForEach(Array(content.ingredients.enumerated()), id: \.offset) { i, ing in
                let checked = checkedIngredients.contains(i)
                Button {
                    if checked { checkedIngredients.remove(i) } else { checkedIngredients.insert(i) }
                } label: {
                    HStack(spacing: 12) {
                        checkbox(checked)
                        Text(ing.name)
                            .font(.nunito(14, .bold))
                            .foregroundStyle(checked ? RD.doneText : RD.textPrimary)
                            .strikethrough(checked, color: RD.doneText)
                        Spacer(minLength: 8)
                        Text(amountLabel(ing))
                            .font(.nunito(13, .heavy))
                            .foregroundStyle(RD.textMuted)
                    }
                    .padding(.vertical, 12)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                if i < content.ingredients.count - 1 {
                    Rectangle().fill(RD.divider).frame(height: 1)
                }
            }
        }
        .padding(.horizontal, 18).padding(.vertical, 4)
        .background(.white, in: RoundedRectangle(cornerRadius: 26))
        .shadow(color: Color(hex: 0x7A6248).opacity(0.09), radius: 14, y: 5)
    }

    private func checkbox(_ checked: Bool) -> some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(checked ? RD.roseCTA : RD.fieldFill)
            .frame(width: 22, height: 22)
            .overlay {
                if checked {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .heavy))
                        .foregroundStyle(.white)
                }
            }
    }

    private func amountLabel(_ ing: RecipeIngredient) -> String {
        // Free-text amounts with no leading number (amount 0) show as-is and
        // don't rescale.
        guard ing.amount > 0 else { return ing.unit }
        let scaled = ing.amount * Double(servings) / Double(max(1, content.baseYield))
        let n = (scaled * 10).rounded() / 10
        let num = n.formatted(.number.precision(.fractionLength(0...1)))
        return ing.unit == "×" ? "×\(num)" : "\(num) \(ing.unit)"
    }

    // MARK: Method

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.nunito(12, .heavy)).tracking(0.8)
            .foregroundStyle(RD.textMuted)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var methodList: some View {
        VStack(spacing: 8) {
            ForEach(Array(content.steps.enumerated()), id: \.offset) { i, step in
                let done = doneSteps.contains(i)
                Button {
                    if done { doneSteps.remove(i) } else { doneSteps.insert(i) }
                } label: {
                    HStack(alignment: .top, spacing: 12) {
                        Text("\(i + 1)")
                            .font(.nunito(12, .heavy))
                            .foregroundStyle(done ? .white : RD.roseAccent)
                            .frame(width: 24, height: 24)
                            .background(done ? RD.roseCTA : RD.roseFill, in: Circle())
                        Text(step)
                            .font(.nunito(13.5, .bold)).lineSpacing(4)
                            .foregroundStyle(done ? RD.doneText : RD.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.vertical, 13).padding(.horizontal, 16)
                    .background(done ? RD.doneBg : .white, in: RoundedRectangle(cornerRadius: 22))
                    .shadow(color: Color(hex: 0x7A6248).opacity(0.07), radius: 12, y: 4)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: CTA

    private var primaryCTA: some View {
        Button { cook() } label: {
            HStack(spacing: 9) {
                Image(systemName: allStepsDone ? "checkmark" : "clock")
                    .font(.system(size: 15, weight: .semibold))
                Text(allStepsDone ? "Done — nicely cooked" : "Cook this now")
                    .font(.baloo(16))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(RD.roseCTA, in: Capsule())
            .shadow(color: Color(hex: 0xBE5F78).opacity(0.4), radius: 20, y: 9)
        }
        .buttonStyle(.plain)
    }

    private var ctaHint: some View {
        Text(allStepsDone
             ? "Tap a step again if you want to run it back."
             : "Adds a 30-minute cooking block to today's schedule.")
            .font(.nunito(11.5, .semibold)).lineSpacing(4)
            .foregroundStyle(RD.hintText)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
    }

    // MARK: Actions

    private func toggleSaved() {
        recipe.isSaved.toggle()
        try? context.save()
        showToast(recipe.isSaved ? "Saved to your recipes" : "Removed from saved")
    }

    private func cook() {
        if allStepsDone {
            showToast("Enjoy it while it's hot")
            return
        }
        let cal = Calendar.current
        let start = cal.date(bySettingHour: 17, minute: 30, second: 0, of: Date()) ?? Date()
        let block = ScheduleBlock(context: context)
        block.id = UUID()
        block.title = "Cook: \(recipe.title ?? "recipe")"
        block.category = BlockCategory.chores.rawValue
        block.startTime = start
        block.endTime = start.addingTimeInterval(30 * 60)
        block.repeatsDaily = false
        try? context.save()
        showToast("Cooking block added to today")
    }

    private func showToast(_ message: String) {
        withAnimation { toast = message }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            withAnimation { toast = nil }
        }
    }
}

// MARK: - Recipe detail palette

private enum RD {
    static let screenBg = Color(hex: 0xFFF8EE)
    static let textPrimary = Color(hex: 0x4A423B)
    static let textMuted = Color(hex: 0x9A8D80)
    static let roseFill = Color(hex: 0xF6E6E9)
    static let roseAccent = Color(hex: 0xC4788C)
    static let roseCTA = Color(hex: 0xD9758C)
    static let roseTag = Color(hex: 0xB0899A)
    static let noteBg = Color(hex: 0xFBEBD8)
    static let noteText = Color(hex: 0x8A6A44)
    static let fieldFill = Color(hex: 0xF4EDE4)
    static let divider = Color(hex: 0x7A6248).opacity(0.1)
    static let doneBg = Color(hex: 0xF7F1EA)
    static let doneText = Color(hex: 0xB7AA9B)
    static let hintText = Color(hex: 0xA99B8C)
}

private struct IngredientDraft: Identifiable { let id = UUID(); var name = ""; var amount = "" }
private struct StepDraft: Identifiable { let id = UUID(); var text = "" }

struct RecipeSheet: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss

    var defaultCategory: String = "Mommy"
    /// Called on save with (collection, recipe name).
    var onSaved: (String, String) -> Void = { _, _ in }

    @State private var name = ""
    @State private var collection: String
    @State private var minutes = 20
    @State private var servings = 2
    @State private var why = ""
    @State private var ingredients: [IngredientDraft] = [IngredientDraft(), IngredientDraft()]
    @State private var steps: [StepDraft] = [StepDraft(), StepDraft()]
    @State private var toast: String?
    @FocusState private var focused: Bool

    init(defaultCategory: String = "Mommy", onSaved: @escaping (String, String) -> Void = { _, _ in }) {
        self.defaultCategory = defaultCategory
        self.onSaved = onSaved
        _collection = State(initialValue: defaultCategory)
    }

    private var isBaby: Bool { collection == "Baby" }
    private var filledIngredients: [IngredientDraft] { ingredients.filter { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty } }
    private var filledSteps: [StepDraft] { steps.filter { !$0.text.trimmingCharacters(in: .whitespaces).isEmpty } }
    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && !filledIngredients.isEmpty && !filledSteps.isEmpty
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                header
                heroCard.padding(.top, 18)
                sectionLabel("WHY IT HELPS").padding(.top, 18).padding(.bottom, 8)
                whyCard
                sectionLabel("INGREDIENTS").padding(.top, 18).padding(.bottom, 8)
                ingredientsCard
                addRow("+ Add ingredient") { ingredients.append(IngredientDraft()) }.padding(.top, 9)
                sectionLabel("METHOD").padding(.top, 18).padding(.bottom, 8)
                methodList
                addRow("+ Add step") { steps.append(StepDraft()) }.padding(.top, 9)
                footerNote.padding(.top, 14)
            }
            .padding(.top, 18)
            .padding(.horizontal, 18)
            .padding(.bottom, 176)
        }
        .background(NR.sheetBg)
        .presentationDetents([.large])
        .presentationBackground(NR.sheetBg)
        .presentationDragIndicator(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .overlay(alignment: .bottom) {
            if let toast {
                Toast(text: toast)
                    .padding(.bottom, 40)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    // MARK: Header

    private var header: some View {
        ZStack {
            Text("New Recipe")
                .font(.baloo(17, heavy: true))
                .foregroundStyle(NR.textPrimary)
            HStack {
                Button { dismiss() } label: {
                    Text("Cancel")
                        .font(.nunito(13, .heavy))
                        .foregroundStyle(NR.textSecondary)
                        .padding(.vertical, 8).padding(.horizontal, 16)
                        .background(.white, in: Capsule())
                        .shadow(color: Color(hex: 0x7A6248).opacity(0.1), radius: 10, y: 3)
                }
                .buttonStyle(.plain)
                Spacer()
                Button { save() } label: {
                    Text("Save")
                        .font(.nunito(13, .heavy))
                        .foregroundStyle(canSave ? .white : NR.disabledText)
                        .padding(.vertical, 8).padding(.horizontal, 18)
                        .background(canSave ? NR.accentRose : NR.disabledBg, in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: Hero

    private var heroCard: some View {
        VStack(spacing: 0) {
            TextField("Recipe name", text: $name)
                .font(.baloo(20, heavy: true))
                .foregroundStyle(NR.textPrimary)
                .tint(NR.roseCTA)
                .focused($focused)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 6) {
                ForEach(RecipeCategory.all, id: \.self) { c in
                    let sel = c == collection
                    Button { collection = c } label: {
                        Text(c)
                            .font(.nunito(13, .heavy))
                            .foregroundStyle(sel ? .white : NR.roseTag)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 9)
                            .background { if sel { Capsule().fill(NR.roseCTA) } }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(4)
            .background(.white, in: Capsule())
            .padding(.top, 14)

            HStack(spacing: 8) {
                factCell(value: "\(minutes)", label: "minutes",
                         onMinus: { minutes = max(5, minutes - 5) },
                         onPlus: { minutes = min(180, minutes + 5) })
                factCell(value: "\(servings)", label: servingsLabel,
                         onMinus: { servings = max(1, servings - 1) },
                         onPlus: { servings = min(12, servings + 1) })
            }
            .padding(.top, 12)
        }
        .padding(.vertical, 16).padding(.horizontal, 18)
        .background(NR.roseFill, in: RoundedRectangle(cornerRadius: 26))
    }

    private var servingsLabel: String {
        let word = isBaby ? "portion" : "serving"
        return servings == 1 ? word : word + "s"
    }

    private func factCell(value: String, label: String, onMinus: @escaping () -> Void, onPlus: @escaping () -> Void) -> some View {
        VStack(spacing: 1) {
            Text(value).font(.baloo(15, heavy: true)).foregroundStyle(NR.roseValue)
            Text(label).font(.nunito(10.5, .bold)).foregroundStyle(NR.textMuted)
            HStack(spacing: 6) {
                Button(action: onMinus) {
                    Text("−").font(.nunito(14, .heavy)).foregroundStyle(NR.textSecondary)
                        .frame(width: 26, height: 26).background(NR.fieldFill, in: Circle())
                }.buttonStyle(.plain)
                Button(action: onPlus) {
                    Text("+").font(.nunito(14, .heavy)).foregroundStyle(.white)
                        .frame(width: 26, height: 26).background(NR.roseCTA, in: Circle())
                }.buttonStyle(.plain)
            }
            .padding(.top, 7)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10).padding(.horizontal, 8)
        .background(.white, in: RoundedRectangle(cornerRadius: 18))
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text).font(.nunito(12, .heavy)).tracking(0.8)
            .foregroundStyle(NR.textMuted)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var whyCard: some View {
        TextField("One line, for future you", text: $why)
            .font(.nunito(14, .bold)).foregroundStyle(NR.textPrimary).tint(NR.roseCTA)
            .focused($focused)
            .padding(.vertical, 14).padding(.horizontal, 18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.white, in: RoundedRectangle(cornerRadius: 26))
            .shadow(color: Color(hex: 0x7A6248).opacity(0.09), radius: 14, y: 5)
    }

    // MARK: Ingredients

    private var ingredientsCard: some View {
        VStack(spacing: 0) {
            ForEach($ingredients) { $ing in
                HStack(spacing: 10) {
                    TextField("Ingredient", text: $ing.name)
                        .font(.nunito(14, .bold)).foregroundStyle(NR.textPrimary).tint(NR.roseCTA)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    TextField("Amount", text: $ing.amount)
                        .font(.nunito(13, .heavy)).foregroundStyle(NR.textMuted).tint(NR.roseCTA)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 74)
                    removeButton { remove(ing) }
                }
                .padding(.vertical, 12)
                if ing.id != ingredients.last?.id {
                    Rectangle().fill(NR.divider).frame(height: 1)
                }
            }
        }
        .padding(.horizontal, 18).padding(.vertical, 4)
        .background(.white, in: RoundedRectangle(cornerRadius: 26))
        .shadow(color: Color(hex: 0x7A6248).opacity(0.09), radius: 14, y: 5)
    }

    // MARK: Method

    private var methodList: some View {
        VStack(spacing: 8) {
            ForEach(Array($steps.enumerated()), id: \.element.id) { index, $step in
                HStack(spacing: 11) {
                    Text("\(index + 1)")
                        .font(.nunito(12, .heavy)).foregroundStyle(NR.roseValue)
                        .frame(width: 24, height: 24).background(NR.roseFill, in: Circle())
                    TextField("What happens in this step?", text: $step.text)
                        .font(.nunito(13.5, .bold)).foregroundStyle(NR.textPrimary).tint(NR.roseCTA)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    removeButton { removeStep(step) }
                }
                .padding(.vertical, 12).padding(.horizontal, 14)
                .background(.white, in: RoundedRectangle(cornerRadius: 22))
                .shadow(color: Color(hex: 0x7A6248).opacity(0.07), radius: 12, y: 4)
            }
        }
    }

    private func removeButton(_ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text("×").font(.nunito(12, .heavy)).foregroundStyle(NR.removeIcon)
                .frame(width: 24, height: 24).background(NR.fieldFill, in: Circle())
        }
        .buttonStyle(.plain)
    }

    private func addRow(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.nunito(12.5, .heavy)).foregroundStyle(NR.roseValue)
                .frame(maxWidth: .infinity)
                .padding(11)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(NR.dashBorder, style: StrokeStyle(lineWidth: 2, dash: [6]))
                )
        }
        .buttonStyle(.plain)
    }

    private var footerNote: some View {
        Text(noteText)
            .font(.nunito(12.5, .bold)).lineSpacing(6)
            .foregroundStyle(NR.noteText)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 14).padding(.horizontal, 16)
            .background(NR.noteBg, in: RoundedRectangle(cornerRadius: 22))
    }

    private var noteText: String {
        guard canSave else {
            return "Give it a name, one ingredient and one step — blank lines are dropped when you save."
        }
        let i = filledIngredients.count, s = filledSteps.count
        let iWord = i == 1 ? "ingredient" : "ingredients"
        let sWord = s == 1 ? "step" : "steps"
        return "\(i) \(iWord), \(s) \(sWord). It'll sit at the top of your \(collection.lowercased()) list."
    }

    // MARK: Actions

    private func remove(_ ing: IngredientDraft) {
        guard ingredients.count > 1 else { return }
        ingredients.removeAll { $0.id == ing.id }
    }

    private func removeStep(_ step: StepDraft) {
        guard steps.count > 1 else { return }
        steps.removeAll { $0.id == step.id }
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return showToast("Name your recipe first") }
        let ings = filledIngredients
        guard !ings.isEmpty else { return showToast("Add at least one ingredient") }
        let stps = filledSteps
        guard !stps.isEmpty else { return showToast("Add at least one step") }

        let r = Recipe(context: context)
        r.id = UUID()
        r.createdAt = Date()
        r.title = trimmedName
        r.category = collection
        r.prepMinutes = Int32(minutes)
        r.servings = Int32(servings)
        r.tag = "\(servings) \(servingsLabel)"
        r.why = why.trimmingCharacters(in: .whitespaces)
        r.ingredients = ings
            .map { "\($0.name.trimmingCharacters(in: .whitespaces));;\($0.amount.trimmingCharacters(in: .whitespaces))" }
            .joined(separator: "\n")
        r.instructions = stps
            .map { $0.text.trimmingCharacters(in: .whitespaces) }
            .joined(separator: "\n")
        try? context.save()
        onSaved(collection, trimmedName)
        dismiss()
    }

    private func showToast(_ message: String) {
        focused = false
        withAnimation { toast = message }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { toast = nil }
        }
    }
}

// MARK: - New Recipe palette

private enum NR {
    static let sheetBg = Color(hex: 0xFFF8EE)
    static let textPrimary = Color(hex: 0x4A423B)
    static let textSecondary = Color(hex: 0x8A7E72)
    static let textMuted = Color(hex: 0x9A8D80)
    static let roseFill = Color(hex: 0xF6E6E9)
    static let roseTag = Color(hex: 0xB0899A)
    static let roseValue = Color(hex: 0xC4788C)
    static let roseCTA = Color(hex: 0xD9758C)
    static let accentRose = Color(hex: 0xD98FA0)
    static let dashBorder = Color(hex: 0xC97B8C).opacity(0.45)
    static let fieldFill = Color(hex: 0xF4EDE4)
    static let divider = Color(hex: 0x7A6248).opacity(0.1)
    static let removeIcon = Color(hex: 0xB7AA9B)
    static let noteBg = Color(hex: 0xFBEBD8)
    static let noteText = Color(hex: 0x8A6A44)
    static let disabledBg = Color(hex: 0xF0E7DC)
    static let disabledText = Color(hex: 0xB7AA9B)
}
