import XCTest
@testable import MathInsert

final class MathExpressionTests: XCTestCase {

    func testInitSetsLatex() {
        let expr = MathExpression(latex: "x^2")
        XCTAssertEqual(expr.latex, "x^2")
    }

    func testInitGeneratesUniqueIDs() {
        let a = MathExpression(latex: "x")
        let b = MathExpression(latex: "x")
        XCTAssertNotEqual(a.id, b.id)
    }

    func testCodableRoundtrip() throws {
        let original = MathExpression(latex: "\\frac{a}{b}")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(MathExpression.self, from: data)
        XCTAssertEqual(decoded, original)
    }

    func testCodableArrayRoundtrip() throws {
        let items = [
            MathExpression(latex: "a"),
            MathExpression(latex: "b"),
            MathExpression(latex: "c"),
        ]
        let data = try JSONEncoder().encode(items)
        let decoded = try JSONDecoder().decode([MathExpression].self, from: data)
        XCTAssertEqual(decoded, items)
    }
}
