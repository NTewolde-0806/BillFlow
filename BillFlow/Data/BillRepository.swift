import Foundation

/// Defines data access independently of storage details.
@MainActor
protocol BillRepository {
    func fetchBills() async throws -> [Bill]
    func saveBills(_ bills: [Bill]) async throws
}

/// In-memory fixture storage for previews. Never writes to disk.
final class SeededBillRepository: BillRepository {
    private var bills: [Bill]?

    func fetchBills() async throws -> [Bill] {
        try await Task.sleep(for: .milliseconds(300))
        if let bills { return bills }
        let seeds = BillSeed.makeBills(relativeTo: .now)
        bills = seeds
        return seeds
    }

    func saveBills(_ bills: [Bill]) async throws {
        self.bills = bills
    }
}
