import Foundation
import Testing
@testable import BillFlow

@MainActor
struct BillReminderTests {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    @Test func permissionThenSchedulingUsesTheChosenBillAndDate() async {
        let scheduler = SchedulerStub()
        let repository = RepositoryStub()
        let model = makeModel(scheduler, repository)
        await model.load()
        let date = now.addingTimeInterval(3600)
        await model.scheduleReminder(billID: repository.bills[0].id, at: date, now: now)
        #expect(scheduler.events == ["permission", "schedule"])
        #expect(scheduler.scheduled[repository.bills[0].id] == date)
        #expect(model.reminderMessage?.contains("scheduled") == true)
        #expect(!model.isSchedulingReminder)
    }

    @Test func deniedPermissionDoesNotScheduleAndExplainsSettings() async {
        let scheduler = SchedulerStub()
        scheduler.granted = false
        let repository = RepositoryStub()
        let model = makeModel(scheduler, repository)
        await model.load()
        await model.scheduleReminder(billID: repository.bills[0].id,
                                     at: now.addingTimeInterval(60), now: now)
        #expect(scheduler.scheduled.isEmpty)
        #expect(model.reminderMessage?.contains("Settings") == true)
        #expect(!model.isSchedulingReminder)
    }

    @Test func schedulingFailureAllowsRetry() async {
        let scheduler = SchedulerStub()
        scheduler.scheduleError = TestError.failed
        let repository = RepositoryStub()
        let model = makeModel(scheduler, repository)
        await model.load()
        let date = now.addingTimeInterval(60)
        await model.scheduleReminder(billID: repository.bills[0].id, at: date, now: now)
        #expect(model.reminderMessage?.contains("Couldn't") == true)
        #expect(!model.isSchedulingReminder)
        scheduler.scheduleError = nil
        await model.scheduleReminder(billID: repository.bills[0].id, at: date, now: now)
        #expect(scheduler.scheduled.count == 1)
    }

    @Test func permissionErrorIsReportedWithoutScheduling() async {
        let scheduler = SchedulerStub()
        scheduler.permissionError = TestError.failed
        let repository = RepositoryStub()
        let model = makeModel(scheduler, repository)
        await model.load()
        await model.scheduleReminder(billID: repository.bills[0].id,
                                     at: now.addingTimeInterval(60), now: now)
        #expect(scheduler.scheduled.isEmpty)
        #expect(model.reminderMessage?.contains("Couldn't") == true)
    }

    @Test func pastDatePaidAndUnknownBillsNeverRequestPermission() async {
        let scheduler = SchedulerStub()
        let repository = RepositoryStub()
        let model = makeModel(scheduler, repository)
        await model.load()
        await model.scheduleReminder(billID: repository.bills[0].id, at: now, now: now)
        #expect(model.reminderMessage?.contains("future") == true)
        await model.scheduleReminder(billID: repository.bills[2].id,
                                     at: now.addingTimeInterval(60), now: now)
        await model.scheduleReminder(billID: UUID(), at: now.addingTimeInterval(60), now: now)
        #expect(scheduler.events.isEmpty)
    }

    @Test func successfulSavedPaymentCancelsItsReminder() async {
        let scheduler = SchedulerStub()
        let repository = RepositoryStub()
        let model = makeModel(scheduler, repository)
        await model.load()
        let id = repository.bills[0].id
        await model.pay(billID: id)
        #expect(repository.bills[0].isPaid)
        #expect(scheduler.cancelled == [id])
    }

    @Test func failedSaveKeepsReminder() async {
        let scheduler = SchedulerStub()
        let repository = RepositoryStub()
        repository.saveFails = true
        let model = makeModel(scheduler, repository)
        await model.load()
        await model.pay(billID: repository.bills[0].id)
        #expect(scheduler.cancelled.isEmpty)
    }

    @Test func inFlightSchedulingBlocksPaymentReloadAndAnotherReminder() async {
        let scheduler = SchedulerStub()
        let repository = RepositoryStub()
        let service = PaymentStub()
        let model = BillListModel(reminderScheduler: scheduler, repository: repository,
                                  paymentService: service)
        await model.load()
        scheduler.onPermission = {
            #expect(model.isSchedulingReminder)
            await model.pay(billID: repository.bills[0].id)
            await model.load()
            await model.scheduleReminder(billID: repository.bills[1].id,
                                         at: now.addingTimeInterval(60), now: now)
        }
        await model.scheduleReminder(billID: repository.bills[0].id,
                                     at: now.addingTimeInterval(60), now: now)
        #expect(service.calls == 0)
        #expect(repository.fetchCalls == 1)
        #expect(scheduler.events == ["permission", "schedule"])
    }

    @Test func cancellationDoesNotReportSchedulingSuccess() async {
        let scheduler = SchedulerStub()
        scheduler.permissionError = CancellationError()
        let repository = RepositoryStub()
        let model = makeModel(scheduler, repository)
        await model.load()
        await model.scheduleReminder(billID: repository.bills[0].id,
                                     at: now.addingTimeInterval(60), now: now)
        #expect(model.reminderMessage == nil)
        #expect(!model.isSchedulingReminder)
        #expect(scheduler.scheduled.isEmpty)
    }

    private func makeModel(_ scheduler: SchedulerStub, _ repository: RepositoryStub) -> BillListModel {
        BillListModel(reminderScheduler: scheduler, repository: repository,
                      paymentService: PaymentStub())
    }

    private enum TestError: Error { case failed }

    private final class SchedulerStub: BillReminderScheduler {
        var granted = true
        var events: [String] = []
        var scheduled: [UUID: Date] = [:]
        var cancelled: [UUID] = []
        var scheduleError: Error?
        var permissionError: Error?
        var onPermission: (() async -> Void)?

        func requestPermission() async throws -> Bool {
            events.append("permission")
            await onPermission?()
            if let permissionError { throw permissionError }
            return granted
        }
        func schedule(bill: Bill, at date: Date) async throws {
            events.append("schedule")
            if let scheduleError { throw scheduleError }
            scheduled[bill.id] = date
        }
        func cancel(billID: UUID) { cancelled.append(billID) }
    }

    private final class RepositoryStub: BillRepository {
        var bills = BillSeed.makeBills(relativeTo: .now)
        var saveFails = false
        var fetchCalls = 0
        func fetchBills() async throws -> [Bill] { fetchCalls += 1; return bills }
        func saveBills(_ bills: [Bill]) async throws {
            if saveFails { throw TestError.failed }
            self.bills = bills
        }
    }

    private final class PaymentStub: PaymentService {
        var calls = 0
        func pay(_ bill: Bill) async throws { calls += 1 }
    }
}
