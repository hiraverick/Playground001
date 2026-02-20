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
            return ["yoga meditation", "tai chi slow", "floating water calm", "breathwork nature"]
        case .excellent:
            return ["cycling nature trail", "swimming pool", "slow jogging park", "rowing calm water"]
        case .good:
            return ["hiking mountain trail", "outdoor running", "dance performance", "surf ocean wave"]
        case .average:
            return ["gym workout training", "running stadium", "basketball court", "crossfit athletes"]
        case .high:
            return ["concert crowd energy", "sprint race track", "music festival crowd", "extreme sports adrenaline"]
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
