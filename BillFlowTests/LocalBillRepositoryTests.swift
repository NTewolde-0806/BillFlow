import Foundation
import Testing
@testable import BillFlow

@MainActor
struct LocalBillRepositoryTests {
    @Test func firstLoadSeedsAndCreatesFile() async throws {
        let folder = temporaryFolder()
        defer { try? FileManager.default.removeItem(at: folder) }
        let file = folder.appendingPathComponent("nested/bills.json")
        let bills = try await LocalBillRepository(fileURL: file).fetchBills()
        #expect(bills.count == 3)
        let saved = try JSONDecoder().decode([Bill].self, from: Data(contentsOf: file))
        #expect(saved == bills)
    }

    @Test func savedChangesSurviveANewRepositoryInstance() async throws {
        let folder = temporaryFolder()
        defer { try? FileManager.default.removeItem(at: folder) }
        let file = folder.appendingPathComponent("bills.json")
        let repository = LocalBillRepository(fileURL: file)
        var bills = try await repository.fetchBills()
        bills[0].name = "Updated electricity"
        bills[0].isPaid = true
        try await repository.saveBills(bills)
        let reloaded = try await LocalBillRepository(fileURL: file).fetchBills()
        #expect(reloaded == bills)
    }

    @Test func emptySavedListIsNotReseeded() async throws {
        let folder = temporaryFolder()
        defer { try? FileManager.default.removeItem(at: folder) }
        let file = folder.appendingPathComponent("bills.json")
        try await LocalBillRepository(fileURL: file).saveBills([])
        let bills = try await LocalBillRepository(fileURL: file).fetchBills()
        #expect(bills.isEmpty)
    }

    @Test func corruptFileThrowsAndRemainsUntouched() async throws {
        let folder = temporaryFolder()
        defer { try? FileManager.default.removeItem(at: folder) }
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let file = folder.appendingPathComponent("bills.json")
        let corruptData = Data("invalid JSON".utf8)
        try corruptData.write(to: file)
        do {
            _ = try await LocalBillRepository(fileURL: file).fetchBills()
            Issue.record("Expected a decoding failure")
        } catch is DecodingError {
            // A corrupt file must not silently become fresh demo data.
        }
        #expect(try Data(contentsOf: file) == corruptData)
    }

    private func temporaryFolder() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("BillFlowTests-\(UUID().uuidString)", isDirectory: true)
    }
}
