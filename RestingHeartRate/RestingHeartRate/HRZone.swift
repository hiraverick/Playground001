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

    /// Multiple queries per zone so repeated views get variety.
    var searchQueries: [String] {
        switch self {
        case .athlete:
            return ["calm ocean waves", "still lake reflection", "zen water ripple", "peaceful sunrise nature"]
        case .excellent:
            return ["mountain landscape aerial", "open water lake aerial", "coastal path landscape", "forest trail aerial"]
        case .good:
            return ["mountain summit panorama", "ocean surf waves", "river flowing landscape", "countryside aerial view"]
        case .average:
            return ["stadium lights empty", "city marathon aerial", "sports arena overhead", "racetrack aerial view"]
        case .high:
            return ["concert stage lights", "festival lights aerial", "city nightlife aerial", "fireworks night sky"]
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
