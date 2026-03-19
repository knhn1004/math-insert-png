import Foundation

struct MathExpression: Codable, Equatable {
    let id: UUID
    let latex: String
    let createdAt: Date

    init(latex: String) {
        self.id = UUID()
        self.latex = latex
        self.createdAt = Date()
    }
}
