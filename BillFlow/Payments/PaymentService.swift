import Foundation

@MainActor
protocol PaymentService {
    func pay(_ bill: Bill) async throws
}

/// A local simulation only. Never contacts a bank or moves money.
struct SimulatedPaymentService: PaymentService {
    var shouldFail = false

    func pay(_ bill: Bill) async throws {
        guard bill.amountInCents > 0 else { throw PaymentError.invalidAmount }
        try await Task.sleep(for: .milliseconds(800))
        if shouldFail { throw PaymentError.declined }
    }

    enum PaymentError: Error { case invalidAmount, declined }
}
