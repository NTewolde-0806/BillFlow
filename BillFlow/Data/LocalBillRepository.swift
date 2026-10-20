import Foundation

struct LocalBillRepository: BillRepository {
    private let store: BillFileStore

    init(fileURL: URL = URL.applicationSupportDirectory
        .appendingPathComponent("BillFlow", isDirectory: true)
        .appendingPathComponent("bills.json")) {
        store = BillFileStore(fileURL: fileURL)
    }

    func fetchBills() async throws -> [Bill] {
        let seeds = BillSeed.makeBills(relativeTo: .now)
        let initialData = try JSONEncoder().encode(seeds)
        let data = try await store.readOrCreate(initialData: initialData)
        return try JSONDecoder().decode([Bill].self, from: data)
    }

    /// Used by future editing/payment flows; fetch-only consumers keep the smaller protocol.
    func saveBills(_ bills: [Bill]) async throws {
        let data = try JSONEncoder().encode(bills)
        try await store.write(data)
    }
}
