import Foundation

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
        "\(n) \(yieldUnit)\(n == 1 ? "" : "s")"
    }

    static func forTitle(_ title: String?, recipe: Recipe) -> RecipeContent {
        if let title, let curated = library[title] { return curated }
        return fallback(for: recipe)
    }

    /// Builds content from a user-created recipe. Ingredients are stored one per
    /// line as "name;;amount" (amount is free text); the leading number is
    /// parsed off for rescaling and the remainder treated as the unit.
    private static func fallback(for recipe: Recipe) -> RecipeContent {
        let category = recipe.category ?? "Mommy"
        let isBaby = category == "Baby"
        let serves = max(1, Int(recipe.servings))
        let yieldUnit = isBaby ? "portion" : "serving"

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

        let servesLabel = isBaby ? "portion" : "serving"
        var facts: [(String, String)] = [("\(recipe.prepMinutes)", "minutes"),
                                         ("\(serves)", serves == 1 ? servesLabel : servesLabel + "s")]
        let count = ingredients.count
        facts.append(("\(count)", count == 1 ? "item" : "items"))

        let why = (recipe.why?.isEmpty == false)
            ? recipe.why!
            : "Your own recipe — saved so you never have to remember it again."

        return RecipeContent(
            tag: "YOUR RECIPE · \(category.uppercased())",
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

    static let library: [String: RecipeContent] = [
        "15-min oat bowl": RecipeContent(
            tag: "BREAKFAST · ONE POT",
            facts: [("15", "minutes"), ("1", "pot"), ("380", "kcal")],
            why: "Slow-release oats and a hit of protein — the kind of breakfast that holds until the next feed.",
            baseYield: 1, yieldUnit: "serving",
            ingredients: [
                RecipeIngredient(name: "Rolled oats", amount: 60, unit: "g"),
                RecipeIngredient(name: "Milk or water", amount: 200, unit: "ml"),
                RecipeIngredient(name: "Greek yoghurt", amount: 2, unit: "tbsp"),
                RecipeIngredient(name: "Banana, sliced", amount: 1, unit: "×"),
                RecipeIngredient(name: "Peanut butter", amount: 1, unit: "tbsp"),
                RecipeIngredient(name: "Cinnamon", amount: 0.5, unit: "tsp"),
            ],
            steps: [
                "Add the oats and milk to a small pot over medium heat.",
                "Stir for 4–5 minutes until creamy and thickened.",
                "Take off the heat and fold through the Greek yoghurt.",
                "Top with sliced banana, peanut butter and a dusting of cinnamon.",
            ]
        ),
        "One-pot chicken porridge": RecipeContent(
            tag: "LUNCH · FREEZER FRIENDLY",
            facts: [("30", "minutes"), ("1", "pot"), ("420", "kcal")],
            why: "One pot, barely any washing up, and it freezes beautifully — cook once, eat all week.",
            baseYield: 4, yieldUnit: "serving",
            ingredients: [
                RecipeIngredient(name: "Chicken thigh", amount: 300, unit: "g"),
                RecipeIngredient(name: "Rice", amount: 150, unit: "g"),
                RecipeIngredient(name: "Water", amount: 1200, unit: "ml"),
                RecipeIngredient(name: "Ginger, sliced", amount: 3, unit: "×"),
                RecipeIngredient(name: "Spring onion", amount: 2, unit: "×"),
                RecipeIngredient(name: "Salt", amount: 1, unit: "tsp"),
            ],
            steps: [
                "Add the chicken, rice, water and ginger to a large pot.",
                "Bring to a boil, then lower to a gentle simmer.",
                "Cook for 25 minutes, stirring now and then, until thick.",
                "Shred the chicken, season with salt and scatter spring onion.",
            ]
        ),
        "Sweet potato mash": RecipeContent(
            tag: "FIRST FOODS · 6M+",
            facts: [("10", "minutes"), ("4", "portions"), ("90", "kcal")],
            why: "Smooth, naturally sweet and gentle on new tummies — a lovely first taste.",
            baseYield: 4, yieldUnit: "portion",
            ingredients: [
                RecipeIngredient(name: "Sweet potato", amount: 1, unit: "×"),
                RecipeIngredient(name: "Breast milk or formula", amount: 30, unit: "ml"),
            ],
            steps: [
                "Peel and dice the sweet potato into small cubes.",
                "Steam for 8 minutes until very soft.",
                "Mash with the milk until smooth, adding more to loosen.",
                "Cool to just warm before serving.",
            ]
        ),
        "Banana oat fingers": RecipeContent(
            tag: "FINGER FOOD · 8M+",
            facts: [("20", "minutes"), ("8", "fingers"), ("60", "kcal")],
            why: "Soft, self-feeding fingers with no added sugar — perfect for little hands learning to grip.",
            baseYield: 8, yieldUnit: "finger",
            ingredients: [
                RecipeIngredient(name: "Banana, ripe", amount: 2, unit: "×"),
                RecipeIngredient(name: "Rolled oats", amount: 80, unit: "g"),
            ],
            steps: [
                "Heat the oven to 180°C and line a small tray.",
                "Mash the bananas, then stir in the oats to a thick dough.",
                "Shape into finger lengths and place on the tray.",
                "Bake for 15 minutes until set and lightly golden. Cool before serving.",
            ]
        ),
    ]
}

