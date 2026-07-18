import Foundation

enum ModelPayloadParser {
    static func parseModels(from data: Data, assumesLoadedModels: Bool) throws -> [LMStudioModel] {
        let payload = try JSONSerialization.jsonObject(with: data)
        let dictionaries = modelDictionaries(from: payload)

        return dictionaries.compactMap { dictionary in
            makeModel(from: dictionary, assumesLoadedModels: assumesLoadedModels)
        }
    }

    private static func modelDictionaries(from payload: Any) -> [[String: Any]] {
        if let array = payload as? [[String: Any]] {
            return array
        }

        guard let dictionary = payload as? [String: Any] else {
            return []
        }

        for key in ["data", "models", "items"] {
            if let array = dictionary[key] as? [[String: Any]] {
                return array
            }
        }

        return []
    }

    private static func makeModel(from dictionary: [String: Any], assumesLoadedModels: Bool) -> LMStudioModel? {
        let name = stringValue(
            in: dictionary,
            keys: ["displayName", "display_name", "name", "id", "model", "modelKey", "model_key", "key", "path"]
        )

        guard let name, !name.isEmpty else {
            return nil
        }

        let modelKey = stringValue(in: dictionary, keys: ["modelKey", "model_key", "key", "id", "model"])
        let type = stringValue(in: dictionary, keys: ["type", "architecture", "format"])
        let contextLength = intValue(in: dictionary, keys: ["maxContextLength", "max_context_length", "context_length", "ctx"])
        let loadedInstances = loadedInstanceCount(in: dictionary, assumesLoadedModels: assumesLoadedModels)
        let id = modelKey ?? name

        return LMStudioModel(
            id: id,
            name: name,
            modelKey: modelKey,
            type: type,
            contextLength: contextLength,
            loadedInstances: loadedInstances,
            activity: .idle,
            queuedRequests: 0
        )
    }

    private static func loadedInstanceCount(in dictionary: [String: Any], assumesLoadedModels: Bool) -> Int {
        for key in ["loadedInstances", "loaded_instances"] {
            if let instances = dictionary[key] as? [Any] {
                return instances.count
            }
        }

        if let count = intValue(in: dictionary, keys: ["loadedCount", "loaded_count", "loaded"]) {
            return count
        }

        if let isLoaded = boolValue(in: dictionary, keys: ["isLoaded", "is_loaded", "loaded"]) {
            return isLoaded ? 1 : 0
        }

        let state = stringValue(in: dictionary, keys: ["state", "status"])?.lowercased()
        if state == "loaded" || state == "running" || state == "active" {
            return 1
        }

        return assumesLoadedModels ? 1 : 0
    }

    private static func stringValue(in dictionary: [String: Any], keys: [String]) -> String? {
        for key in keys {
            if let value = dictionary[key] as? String {
                return value
            }
        }
        return nil
    }

    private static func intValue(in dictionary: [String: Any], keys: [String]) -> Int? {
        for key in keys {
            if let value = dictionary[key] as? Int {
                return value
            }

            if let value = dictionary[key] as? Double {
                return Int(value)
            }

            if let value = dictionary[key] as? String, let intValue = Int(value) {
                return intValue
            }
        }
        return nil
    }

    private static func boolValue(in dictionary: [String: Any], keys: [String]) -> Bool? {
        for key in keys {
            if let value = dictionary[key] as? Bool {
                return value
            }
        }
        return nil
    }
}
