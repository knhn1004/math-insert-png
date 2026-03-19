import Foundation

class HistoryManager {
    static let shared = HistoryManager()
    private let key = "math_expression_history"
    private let maxEntries = 50

    var expressions: [MathExpression] {
        get {
            guard let data = UserDefaults.standard.data(forKey: key),
                  let decoded = try? JSONDecoder().decode([MathExpression].self, from: data) else {
                return []
            }
            return decoded
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(data, forKey: key)
            }
        }
    }

    func add(_ latex: String) {
        guard !latex.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        var list = expressions
        // Deduplicate: remove existing entry with same latex
        list.removeAll { $0.latex == latex }
        // Insert at front
        list.insert(MathExpression(latex: latex), at: 0)
        // Trim to max
        if list.count > maxEntries {
            list = Array(list.prefix(maxEntries))
        }
        expressions = list
    }

    func remove(at index: Int) {
        var list = expressions
        guard index >= 0 && index < list.count else { return }
        list.remove(at: index)
        expressions = list
    }

    func clear() {
        expressions = []
    }
}
