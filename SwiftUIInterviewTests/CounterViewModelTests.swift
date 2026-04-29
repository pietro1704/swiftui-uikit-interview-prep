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

    // TODO Exercise: complete with the additional scenarios listed in Lesson10.
}
