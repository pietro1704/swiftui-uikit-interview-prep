import XCTest
@testable import SwiftUIInterview

final class CounterViewModelTests: XCTestCase {
    func test_increment_aumenta_count_e_history() {
        let vm = CounterViewModel()
        vm.increment()
        vm.increment()
        XCTAssertEqual(vm.count, 2)
        XCTAssertEqual(vm.history, [1, 2])
    }

    func test_canDecrement_falso_quando_zero() {
        let vm = CounterViewModel()
        XCTAssertFalse(vm.canDecrement)
    }

    func test_reset_zera_estado() {
        let vm = CounterViewModel()
        vm.increment(); vm.increment()
        vm.reset()
        XCTAssertEqual(vm.count, 0)
        XCTAssertTrue(vm.history.isEmpty)
    }

    // TODO Exercício: complete com mais cenários (ver Lesson10)
}
