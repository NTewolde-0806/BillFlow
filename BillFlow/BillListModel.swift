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
    enum PaymentState: Equatable {
        case idle
        case processing(UUID)
        case failed(String)
    }

    private(set) var paymentState: PaymentState = .idle
    var isPaying: Bool {
        if case .processing = paymentState { return true }
        return false
    }

    private let repository: any BillRepository
    private let paymentService: any PaymentService

    init(repository: any BillRepository, paymentService: (any PaymentService)? = nil) {
        self.repository = repository
        self.paymentService = paymentService ?? SimulatedPaymentService()
    }

    func load() async {
        guard state != .loading, !isPaying else { return }
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

    func pay(billID: UUID) async {
        guard !isPaying,
              case .loaded(var bills) = state,
              let index = bills.firstIndex(where: { $0.id == billID }),
              !bills[index].isPaid else { return }

        paymentState = .processing(billID)
        defer {
            if isPaying { paymentState = .idle }
        }

        do {
            try await paymentService.pay(bills[index])
        } catch is CancellationError {
            return
        } catch {
            paymentState = .failed("Simulated payment failed. Your bill remains unpaid. Try again.")
            return
        }

        bills[index].isPaid = true
        do {
            try await repository.saveBills(bills)
            state = .loaded(bills)
        } catch {
            paymentState = .failed("The simulation succeeded, but saving failed. Your bill remains unpaid in the list. Try again.")
        }
    }

    func dismissPaymentError() {
        if case .failed = paymentState { paymentState = .idle }
    }

}
