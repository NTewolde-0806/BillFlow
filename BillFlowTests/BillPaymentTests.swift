import Foundation
import Testing
@testable import BillFlow

@MainActor
struct BillPaymentTests {
    @Test func successfulPaymentSavesBeforeUpdatingTheList() async throws {
        let repository = RepositoryStub()
        let service = PaymentStub()
        let model = BillListModel(reminderScheduler: PreviewBillReminderScheduler(), repository: repository, paymentService: service)
        await model.load()
        let original = repository.bills
        repository.onSave = {
            #expect(model.state == .loaded(original))
            #expect(model.isPaying)
        }
        await model.pay(billID: original[0].id)
        #expect(service.calls == 1)
        #expect(repository.saveCalls == 1)
        #expect(repository.bills[0].isPaid)
        #expect(model.state == .loaded(repository.bills))
        #expect(model.paymentState == .idle)
    }

    @Test func declinedPaymentDoesNotSaveAndCanBeRetried() async {
        let repository = RepositoryStub()
        let service = PaymentStub()
        service.error = TestError.failed
        let model = BillListModel(reminderScheduler: PreviewBillReminderScheduler(), repository: repository, paymentService: service)
        await model.load()
        await model.pay(billID: repository.bills[0].id)
        #expect(repository.saveCalls == 0)
        #expect(model.state == .loaded(repository.bills))
        guard case .failed = model.paymentState else {
            Issue.record("Expected payment failure"); return
        }
        model.dismissPaymentError()
        #expect(model.paymentState == .idle)
        service.error = nil
        await model.pay(billID: repository.bills[0].id)
        #expect(repository.bills[0].isPaid)
    }

    @Test func saveFailureDoesNotClaimTheBillIsPaid() async {
        let repository = RepositoryStub()
        repository.saveError = TestError.failed
        let model = BillListModel(reminderScheduler: PreviewBillReminderScheduler(), repository: repository, paymentService: PaymentStub())
        await model.load()
        let original = repository.bills
        await model.pay(billID: original[0].id)
        #expect(model.state == .loaded(original))
        #expect(repository.bills == original)
        guard case .failed(let message) = model.paymentState else {
            Issue.record("Expected save failure"); return
        }
        #expect(message.contains("saving failed"))
        #expect(!model.isPaying)
    }

    @Test func paidAndUnknownBillsDoNotReachThePaymentService() async {
        let repository = RepositoryStub()
        let service = PaymentStub()
        let model = BillListModel(reminderScheduler: PreviewBillReminderScheduler(), repository: repository, paymentService: service)
        await model.load()
        await model.pay(billID: repository.bills[2].id)
        await model.pay(billID: UUID())
        #expect(service.calls == 0)
        #expect(repository.saveCalls == 0)
    }

    @Test func inFlightPaymentBlocksOtherPaymentsAndReloads() async {
        let repository = RepositoryStub()
        let service = PaymentStub()
        let model = BillListModel(reminderScheduler: PreviewBillReminderScheduler(), repository: repository, paymentService: service)
        await model.load()
        service.onPay = {
            #expect(model.paymentState == .processing(repository.bills[0].id))
            await model.pay(billID: repository.bills[0].id)
            await model.pay(billID: repository.bills[1].id)
            await model.load()
        }
        await model.pay(billID: repository.bills[0].id)
        #expect(service.calls == 1)
        #expect(repository.fetchCalls == 1)
        #expect(repository.saveCalls == 1)
    }

    @Test func cancellationBeforePaymentCompletionDoesNotSave() async {
        let repository = RepositoryStub()
        let service = PaymentStub()
        service.error = CancellationError()
        let model = BillListModel(reminderScheduler: PreviewBillReminderScheduler(), repository: repository, paymentService: service)
        await model.load()
        await model.pay(billID: repository.bills[0].id)
        #expect(repository.saveCalls == 0)
        #expect(model.paymentState == .idle)
        #expect(model.state == .loaded(repository.bills))
    }

    @Test func paidStatusSurvivesReloadFromDisk() async throws {
        let folder = FileManager.default.temporaryDirectory
            .appendingPathComponent("BillFlowPaymentTests-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: folder) }
        let file = folder.appendingPathComponent("bills.json")
        let model = BillListModel(reminderScheduler: PreviewBillReminderScheduler(), repository: LocalBillRepository(fileURL: file),
                                  paymentService: PaymentStub())
        await model.load()
        guard case .loaded(let bills) = model.state else {
            Issue.record("Expected initial bills"); return
        }
        await model.pay(billID: bills[0].id)
        let restored = try await LocalBillRepository(fileURL: file).fetchBills()
        #expect(restored[0].isPaid)
        #expect(restored[0].id == bills[0].id)
        #expect(model.state == .loaded(restored))
    }

    private enum TestError: Error { case failed }

    private final class PaymentStub: PaymentService {
        var calls = 0
        var error: Error?
        var onPay: (() async -> Void)?
        func pay(_ bill: Bill) async throws {
            calls += 1
            await onPay?()
            if let error { throw error }
        }
    }

    private final class RepositoryStub: BillRepository {
        var bills = BillSeed.makeBills(relativeTo: .now)
        var saveCalls = 0
        var fetchCalls = 0
        var saveError: Error?
        var onSave: (() -> Void)?

        func fetchBills() async throws -> [Bill] {
            fetchCalls += 1
            return bills
        }

        func saveBills(_ bills: [Bill]) async throws {
            saveCalls += 1
            onSave?()
            if let saveError { throw saveError }
            self.bills = bills
        }
    }
}
