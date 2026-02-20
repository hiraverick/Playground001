import SwiftUI

enum HRZone: Equatable {
    case athlete      // < 50 BPM
    case excellent    // 50–59 BPM
    case good         // 60–69 BPM
    case average      // 70–79 BPM
    case high         // 80+ BPM

    init(bpm: Double) {
        switch bpm {
        case ..<50:    self = .athlete
        case 50..<60:  self = .excellent
        case 60..<70:  self = .good
        case 70..<80:  self = .average
        default:       self = .high
        }
    }

    var label: String {
        switch self {
        case .athlete:   return "Athlete"
        case .excellent: return "Excellent"
        case .good:      return "Good"
        case .average:   return "Average"
        case .high:      return "Elevated"
        }
    }

    /// Multiple queries per zone so repeated views get variety. All nature, graduated calm → intense.
    var searchQueries: [String] {
        switch self {
        case .athlete:
            // Very serene — still water, mist, dawn
            return ["still lake misty morning", "calm water reflection nature", "peaceful forest dawn", "tranquil pond nature"]
        case .excellent:
            // Gentle nature — flowing streams, soft light
            return ["gentle stream forest", "meadow nature aerial", "coastal cliffs landscape", "rolling hills nature aerial"]
        case .good:
            // Moderate nature — rivers, coastal scenery
            return ["river flowing nature", "ocean coast landscape", "valley nature aerial", "forest canopy aerial"]
        case .average:
            // Dynamic nature — ocean waves, waterfalls
            return ["ocean waves crashing nature", "waterfall nature landscape", "mountain river rapids", "stormy sea waves"]
        case .high:
            // Intense nature — storms, crashing surf, lightning
            return ["lightning storm nature", "crashing waves storm", "thunderstorm nature landscape", "wild ocean storm waves"]
        }
    }

    var color: Color {
        switch self {
        case .athlete:   return Color(red: 0.20, green: 0.60, blue: 1.00)
        case .excellent: return Color(red: 0.10, green: 0.85, blue: 0.55)
        case .good:      return Color(red: 0.55, green: 0.90, blue: 0.20)
        case .average:   return Color(red: 1.00, green: 0.72, blue: 0.15)
        case .high:      return Color(red: 1.00, green: 0.30, blue: 0.30)
        }
    }
}
