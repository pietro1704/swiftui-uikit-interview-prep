import XCTest
@testable import SwiftUIInterview

final class CounterViewModelTests: XCTestCase {
    func test_increment_increasesCountAndAppendsHistory() {
        let vm = CounterViewModel()
        vm.increment()
        vm.increment()
        XCTAssertEqual(vm.count, 2)
        XCTAssertEqual(vm.history, [1, 2])
    }

    func test_canDecrement_isFalseWhenZero() {
        let vm = CounterViewModel()
        XCTAssertFalse(vm.canDecrement)
    }

    func test_reset_clearsState() {
        let vm = CounterViewModel()
        vm.increment(); vm.increment()
        vm.reset()
        XCTAssertEqual(vm.count, 0)
        XCTAssertTrue(vm.history.isEmpty)
    }

    // Exercise solutions:

    func test_decrement_doesNotGoNegative() {
        let vm = CounterViewModel()
        vm.decrement()
        XCTAssertEqual(vm.count, 0)
        XCTAssertTrue(vm.history.isEmpty)
    }

    func test_history_after3IncrementsAnd1Decrement() {
        let vm = CounterViewModel()
        vm.increment(); vm.increment(); vm.increment()
        vm.decrement()
        XCTAssertEqual(vm.count, 2)
        XCTAssertEqual(vm.history, [1, 2, 3, 2])
    }

    func test_undo_revertsLastChange() {
        let vm = CounterViewModel()
        vm.increment(); vm.increment()  // count = 2
        vm.undo()
        XCTAssertEqual(vm.count, 1)
        vm.undo()
        XCTAssertEqual(vm.count, 0)
    }
}
