import SwiftUI
import FoundationModels

@Generable
enum PostCategory: String, CaseIterable, Codable {
    case design, foodRecipes, travel, tech, tipsLearning, shopping, entertainment, other

    var displayName: String {
        switch self {
        case .design: "Design"
        case .foodRecipes: "Food & Recipes"
        case .travel: "Travel"
        case .tech: "Tech"
        case .tipsLearning: "Tips & Learning"
        case .shopping: "Shopping"
        case .entertainment: "Entertainment"
        case .other: "Other"
        }
    }

    var color: Color {
        switch self {
        case .design: .purple
        case .foodRecipes: .orange
        case .travel: .teal
        case .tech: .blue
        case .tipsLearning: .yellow
        case .shopping: .pink
        case .entertainment: .red
        case .other: .gray
        }
    }

    var symbol: String {
        switch self {
        case .design: "paintbrush.pointed"
        case .foodRecipes: "fork.knife"
        case .travel: "airplane"
        case .tech: "laptopcomputer"
        case .tipsLearning: "lightbulb"
        case .shopping: "bag"
        case .entertainment: "play.rectangle"
        case .other: "square.grid.2x2"
        }
    }
}
