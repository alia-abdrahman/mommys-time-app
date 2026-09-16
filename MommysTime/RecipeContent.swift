import Foundation

/// What a recipe yields. The raw keys are stable identifiers used inside the
/// curated library; `label` is the copy the user reads.
enum RecipeYieldUnit {
    static let serving = "serving"
    static let portion = "portion"
    static let finger = "finger"
    static let pot = "pot"

    static func label(_ unit: String, count: Int) -> String {
        let single = count == 1
        switch unit {
        case portion: return single ? L.Recipes.unitPortion : L.Recipes.unitPortions
        case finger: return single ? L.Recipes.unitFinger : L.Recipes.unitFingers
        case pot: return L.Recipes.unitPot
        default: return single ? L.Recipes.unitServing : L.Recipes.unitServings
        }
    }
}

/// One line item in a recipe's ingredient list. `amount` is per the recipe's
/// base yield; the detail screen rescales it by servings ÷ base.
struct RecipeIngredient {
    let name: String
    let amount: Double
    /// "g" · "ml" · "tbsp" · "tsp" · "×" (count)
    let unit: String
}

/// The structured, display-ready content behind a recipe. The curated premium
/// recipes have hand-written entries; anything else falls back to a version
/// derived from the stored Core Data fields.
struct RecipeContent {
    let tag: String
    let facts: [(value: String, label: String)]
    let why: String
    let baseYield: Int
    /// Singular unit for the yield stepper: "serving" · "portion" · "finger".
    let yieldUnit: String
    let ingredients: [RecipeIngredient]
    let steps: [String]

    /// Pluralises the yield unit for the servings stepper label.
    func yieldLabel(_ n: Int) -> String {
        L.Recipes.yield(n, unit: RecipeYieldUnit.label(yieldUnit, count: n))
    }

    static func forTitle(_ title: String?, recipe: Recipe) -> RecipeContent {
        if let title, let curated = library[title] { return curated }
        return fallback(for: recipe)
    }

    /// Builds content from a user-created recipe. Ingredients are stored one per
    /// line as "name;;amount" (amount is free text); the leading number is
    /// parsed off for rescaling and the remainder treated as the unit.
    private static func fallback(for recipe: Recipe) -> RecipeContent {
        let category = recipe.category ?? RecipeCategory.mommy
        let isBaby = category == RecipeCategory.baby
        let serves = max(1, Int(recipe.servings))
        let yieldUnit = isBaby ? RecipeYieldUnit.portion : RecipeYieldUnit.serving

        let ingredients = (recipe.ingredients ?? "")
            .split(separator: "\n").map(String.init)
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            .map { line -> RecipeIngredient in
                let parts = line.components(separatedBy: ";;")
                let name = parts[0].trimmingCharacters(in: .whitespaces)
                let amountText = parts.count > 1 ? parts[1].trimmingCharacters(in: .whitespaces) : ""
                let (amount, unit) = parseAmount(amountText)
                return RecipeIngredient(name: name, amount: amount, unit: unit)
            }

        let steps = (recipe.instructions ?? "")
            .split(separator: "\n").map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        var facts: [(String, String)] = [
            ("\(recipe.prepMinutes)", L.Recipes.factMinutes),
            ("\(serves)", RecipeYieldUnit.label(yieldUnit, count: serves)),
        ]
        let count = ingredients.count
        facts.append(("\(count)", count == 1 ? L.Recipes.factItem : L.Recipes.factItems))

        let why = (recipe.why?.isEmpty == false)
            ? recipe.why!
            : L.Recipes.ownWhy

        return RecipeContent(
            tag: L.Recipes.ownTag(RecipeCategory.label(category).uppercased()),
            facts: facts,
            why: why,
            baseYield: serves,
            yieldUnit: yieldUnit,
            ingredients: ingredients,
            steps: steps
        )
    }

    /// Splits a free-text amount into a numeric part (for rescaling) and a unit.
    /// "60 g" → (60, "g") · "2 tbsp" → (2, "tbsp") · "a handful" → (0, "a handful").
    static func parseAmount(_ text: String) -> (Double, String) {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return (0, "") }
        var numberPart = ""
        var rest = trimmed
        for ch in trimmed {
            if ch.isNumber || ch == "." { numberPart.append(ch); rest.removeFirst() } else { break }
        }
        if let n = Double(numberPart) {
            return (n, rest.trimmingCharacters(in: .whitespaces))
        }
        return (0, trimmed)   // no leading number → unchanged across servings
    }

    /// Keyed by the canonical (English) title that seeding writes to Core Data,
    /// so the lookup survives a change of language. Everything *inside* an entry
    /// is translated copy pulled from the catalogue — which is why this is
    /// computed: a `static let` would pin those to the first language rendered.
    static var library: [String: RecipeContent] { [
        L.Recipes.Seed.oatBowlKey: RecipeContent(
            tag: L.Recipes.Seed.oatBowlTag,
            facts: [
                ("15", L.Recipes.factMinutes),
                ("1", L.Recipes.unitPot),
                ("380", L.Recipes.factKcal),
            ],
            why: L.Recipes.Seed.oatBowlWhy,
            baseYield: 1, yieldUnit: RecipeYieldUnit.serving,
            ingredients: [
                RecipeIngredient(name: L.Recipes.Seed.rolledOats, amount: 60, unit: L.Recipes.unitGrams),
                RecipeIngredient(name: L.Recipes.Seed.milkOrWater, amount: 200, unit: L.Recipes.unitMillilitres),
                RecipeIngredient(name: L.Recipes.Seed.greekYoghurt, amount: 2, unit: L.Recipes.unitTablespoon),
                RecipeIngredient(name: L.Recipes.Seed.bananaSliced, amount: 1, unit: L.Recipes.unitCount),
                RecipeIngredient(name: L.Recipes.Seed.peanutButter, amount: 1, unit: L.Recipes.unitTablespoon),
                RecipeIngredient(name: L.Recipes.Seed.cinnamon, amount: 0.5, unit: L.Recipes.unitTeaspoon),
            ],
            steps: L.Recipes.Seed.oatBowlSteps
        ),
        L.Recipes.Seed.porridgeKey: RecipeContent(
            tag: L.Recipes.Seed.porridgeTag,
            facts: [
                ("30", L.Recipes.factMinutes),
                ("1", L.Recipes.unitPot),
                ("420", L.Recipes.factKcal),
            ],
            why: L.Recipes.Seed.porridgeWhy,
            baseYield: 4, yieldUnit: RecipeYieldUnit.serving,
            ingredients: [
                RecipeIngredient(name: L.Recipes.Seed.chickenThigh, amount: 300, unit: L.Recipes.unitGrams),
                RecipeIngredient(name: L.Recipes.Seed.rice, amount: 150, unit: L.Recipes.unitGrams),
                RecipeIngredient(name: L.Recipes.Seed.water, amount: 1200, unit: L.Recipes.unitMillilitres),
                RecipeIngredient(name: L.Recipes.Seed.gingerSliced, amount: 3, unit: L.Recipes.unitCount),
                RecipeIngredient(name: L.Recipes.Seed.springOnion, amount: 2, unit: L.Recipes.unitCount),
                RecipeIngredient(name: L.Recipes.Seed.salt, amount: 1, unit: L.Recipes.unitTeaspoon),
            ],
            steps: L.Recipes.Seed.porridgeSteps
        ),
        L.Recipes.Seed.sweetPotatoKey: RecipeContent(
            tag: L.Recipes.Seed.sweetPotatoTag,
            facts: [
                ("10", L.Recipes.factMinutes),
                ("4", L.Recipes.unitPortions),
                ("90", L.Recipes.factKcal),
            ],
            why: L.Recipes.Seed.sweetPotatoWhy,
            baseYield: 4, yieldUnit: RecipeYieldUnit.portion,
            ingredients: [
                RecipeIngredient(name: L.Recipes.Seed.sweetPotato, amount: 1, unit: L.Recipes.unitCount),
                RecipeIngredient(name: L.Recipes.Seed.breastMilkOrFormula, amount: 30, unit: L.Recipes.unitMillilitres),
            ],
            steps: L.Recipes.Seed.sweetPotatoSteps
        ),
        L.Recipes.Seed.bananaFingersKey: RecipeContent(
            tag: L.Recipes.Seed.bananaFingersTag,
            facts: [
                ("20", L.Recipes.factMinutes),
                ("8", L.Recipes.unitFingers),
                ("60", L.Recipes.factKcal),
            ],
            why: L.Recipes.Seed.bananaFingersWhy,
            baseYield: 8, yieldUnit: RecipeYieldUnit.finger,
            ingredients: [
                RecipeIngredient(name: L.Recipes.Seed.bananaRipe, amount: 2, unit: L.Recipes.unitCount),
                RecipeIngredient(name: L.Recipes.Seed.rolledOats, amount: 80, unit: L.Recipes.unitGrams),
            ],
            steps: L.Recipes.Seed.bananaFingersSteps
        ),
    ] }
}

