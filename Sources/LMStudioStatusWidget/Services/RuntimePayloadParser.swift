import Foundation

enum RuntimePayloadParser {
    static func parseRuntimeInfo(from data: Data) throws -> [LMStudioRuntimeInfo] {
        guard let dictionaries = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            return []
        }

        return dictionaries.compactMap { dictionary in
            guard let identifier = stringValue(
                in: dictionary,
                keys: ["identifier", "modelKey", "model_key", "id"]
            ), !identifier.isEmpty else {
                return nil
            }

            let rawStatus = stringValue(in: dictionary, keys: ["status", "state"])?.lowercased()
            let activity: ModelActivity

            switch rawStatus {
            case "generating":
                activity = .generating
            case "loading":
                activity = .loading
            default:
                activity = .idle
            }

            return LMStudioRuntimeInfo(
                identifier: identifier,
                activity: activity,
                queuedRequests: max(0, intValue(in: dictionary, keys: ["queued", "queuedRequests"]) ?? 0)
            )
        }
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
        }
        return nil
    }
}
