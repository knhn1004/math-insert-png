import XCTest
@testable import MathInsert

final class HistoryManagerTests: XCTestCase {
    private var manager: HistoryManager!

    override func setUp() {
        super.setUp()
        manager = HistoryManager()
        manager.clear()
    }

    override func tearDown() {
        manager.clear()
        super.tearDown()
    }

    func testAddExpression() {
        manager.add("x^2")
        XCTAssertEqual(manager.expressions.count, 1)
        XCTAssertEqual(manager.expressions.first?.latex, "x^2")
    }

    func testAddMultipleExpressions() {
        manager.add("a")
        manager.add("b")
        XCTAssertEqual(manager.expressions.count, 2)
        XCTAssertEqual(manager.expressions[0].latex, "b")
        XCTAssertEqual(manager.expressions[1].latex, "a")
    }

    func testDeduplication() {
        manager.add("x^2")
        manager.add("y^2")
        manager.add("x^2")
        XCTAssertEqual(manager.expressions.count, 2)
        XCTAssertEqual(manager.expressions[0].latex, "x^2")
        XCTAssertEqual(manager.expressions[1].latex, "y^2")
    }

    func testMaxFiftyCap() {
        for i in 0..<60 {
            manager.add("expr_\(i)")
        }
        XCTAssertEqual(manager.expressions.count, 50)
        XCTAssertEqual(manager.expressions.first?.latex, "expr_59")
    }

    func testRemoveAtIndex() {
        manager.add("a")
        manager.add("b")
        manager.add("c")
        manager.remove(at: 1)
        XCTAssertEqual(manager.expressions.count, 2)
        XCTAssertEqual(manager.expressions[0].latex, "c")
        XCTAssertEqual(manager.expressions[1].latex, "a")
    }

    func testRemoveOutOfBoundsIsNoOp() {
        manager.add("a")
        manager.remove(at: 5)
        XCTAssertEqual(manager.expressions.count, 1)
    }

    func testClear() {
        manager.add("a")
        manager.add("b")
        manager.clear()
        XCTAssertTrue(manager.expressions.isEmpty)
    }

    func testEmptyStringIsIgnored() {
        manager.add("")
        manager.add("   ")
        XCTAssertTrue(manager.expressions.isEmpty)
    }
}
