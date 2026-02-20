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

    /// All queries target top-down overhead drone/aerial nature shots, graduated calm → intense.
    var searchQueries: [String] {
        switch self {
        case .athlete:
            // Serene — still water, glassy lakes from directly above
            return ["top down aerial still lake", "overhead drone calm water nature", "bird eye view lake reflection", "top view aerial pond nature"]
        case .excellent:
            // Gentle — forests and meadows from above
            return ["top down aerial forest canopy", "overhead drone green meadow", "bird eye view river forest", "top view aerial woodland nature"]
        case .good:
            // Moderate — rivers and coastline from above
            return ["top down aerial river flowing", "overhead drone ocean coast", "bird eye view waterfall top", "top view aerial nature stream"]
        case .average:
            // Dynamic — waves and rapids from directly overhead
            return ["top down aerial ocean waves", "overhead drone river rapids", "bird eye view crashing waves", "top view aerial waterfall"]
        case .high:
            // Intense — turbulent water and storms from above
            return ["top down aerial stormy ocean", "overhead drone turbulent waves", "bird eye view storm nature", "top view aerial wild sea"]
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
