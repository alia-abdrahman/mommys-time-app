import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    static let preview = PersistenceController(inMemory: true)

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "MommysTime")

        if let description = container.persistentStoreDescriptions.first {
            if inMemory {
                description.url = URL(fileURLWithPath: "/dev/null")
            }
            // Enable lightweight migration so added attributes (thresholds,
            // toggles, tags…) migrate an existing store instead of crashing.
            description.shouldMigrateStoreAutomatically = true
            description.shouldInferMappingModelAutomatically = true
        }

        container.loadPersistentStores { [container] _, error in
            guard let error else { return }
            // If the on-device store is incompatible with the current model
            // (e.g. a schema change that can't be inferred during development),
            // rebuild it rather than hard-crashing on launch.
            if let url = container.persistentStoreDescriptions.first?.url,
               url.path != "/dev/null" {
                try? FileManager.default.removeItem(at: url)
                try? FileManager.default.removeItem(at: url.appendingPathExtension("shm"))
                try? FileManager.default.removeItem(at: url.appendingPathExtension("wal"))
                container.loadPersistentStores { _, retryError in
                    if let retryError {
                        fatalError("Failed to load Core Data store: \(retryError)")
                    }
                }
            } else {
                fatalError("Failed to load Core Data store: \(error)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
