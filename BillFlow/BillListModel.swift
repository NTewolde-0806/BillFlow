import Foundation
import Observation

@MainActor
@Observable
final class BillListModel {
    enum State: Equatable {
        case idle
        case loading
        case loaded([Bill])
        case failed
    }

    private(set) var state: State = .idle
    private let repository: any BillRepository

    init(repository: any BillRepository) {
        self.repository = repository
    }

    func load() async {
        guard state != .loading else { return }
        state = .loading
        do {
            let bills = try await repository.fetchBills()
            try Task.checkCancellation()
            state = .loaded(bills)
        } catch is CancellationError {
            state = .idle
        } catch {
            state = .failed
        }
    }
}
