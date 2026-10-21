import Foundation
import Testing
@testable import BillFlow

@MainActor
struct BillListModelTests {
    @Test func successfulLoadReplacesIdleWithBills() async {
        let bills = BillSeed.makeBills(relativeTo: .now)
        let repository = StubRepository(result: .success(bills))
        let model = BillListModel(reminderScheduler: PreviewBillReminderScheduler(), repository: repository)
        #expect(model.state == .idle)
        repository.onFetch = { #expect(model.state == .loading) }
        await model.load()
        #expect(model.state == .loaded(bills))
    }

    @Test func emptyResultIsAValidLoadedState() async {
        let model = BillListModel(reminderScheduler: PreviewBillReminderScheduler(), repository: StubRepository(result: .success([])))
        await model.load()
        #expect(model.state == .loaded([]))
    }

    @Test func failureCanBeRetried() async {
        let repository = StubRepository(result: .failure(TestError.unavailable))
        let model = BillListModel(reminderScheduler: PreviewBillReminderScheduler(), repository: repository)
        await model.load()
        #expect(model.state == .failed)
        repository.result = .success([])
        await model.load()
        #expect(model.state == .loaded([]))
    }

    @Test func cancellationDoesNotShowAnError() async {
        let model = BillListModel(reminderScheduler: PreviewBillReminderScheduler(), repository: StubRepository(result: .failure(CancellationError())))
        await model.load()
        #expect(model.state == .idle)
    }

    private enum TestError: Error { case unavailable }

    private final class StubRepository: BillRepository {
        var result: Result<[Bill], Error>
        var onFetch: (() -> Void)?

        init(result: Result<[Bill], Error>) { self.result = result }

        func saveBills(_ bills: [Bill]) async throws { result = .success(bills) }

        func fetchBills() async throws -> [Bill] {
            onFetch?()
            return try result.get()
        }
    }
}
