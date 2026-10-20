import Foundation

/// The screen asks for bills without knowing how they are stored.
@MainActor
protocol BillRepository {
    func fetchBills() async throws -> [Bill]
}

struct SeededBillRepository: BillRepository {
    func fetchBills() async throws -> [Bill] {
        // A brief simulated delay makes the loading state visible in this demo.
        try await Task.sleep(for: .milliseconds(300))
        return BillSeed.makeBills(relativeTo: .now)
    }
}
