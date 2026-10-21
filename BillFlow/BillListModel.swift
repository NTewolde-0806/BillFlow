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

    private(set) var isSchedulingReminder = false
    private(set) var reminderMessage: String?
    private let reminderScheduler: any BillReminderScheduler
    private let repository: any BillRepository
    private let paymentService: any PaymentService

    init(reminderScheduler: (any BillReminderScheduler)? = nil, repository: any BillRepository, paymentService: (any PaymentService)? = nil) {
        self.reminderScheduler = reminderScheduler ?? LocalBillReminderScheduler()
        self.repository = repository
        self.paymentService = paymentService ?? SimulatedPaymentService()
    }

    func load() async {
        guard state != .loading, !isPaying, !isSchedulingReminder else { return }
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
        guard !isPaying, !isSchedulingReminder,
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
            reminderScheduler.cancel(billID: billID)
        } catch {
            paymentState = .failed("The simulation succeeded, but saving failed. Your bill remains unpaid in the list. Try again.")
        }
    }

    func dismissPaymentError() {
        if case .failed = paymentState { paymentState = .idle }
    }

    func clearReminderMessage() { reminderMessage = nil }

    func scheduleReminder(billID: UUID, at date: Date, now: Date = .now) async {
        guard !isSchedulingReminder, !isPaying,
              case .loaded(let bills) = state,
              let bill = bills.first(where: { $0.id == billID }), !bill.isPaid else { return }
        reminderMessage = nil
        guard date > now else {
            reminderMessage = "Choose a future date and time."
            return
        }
        isSchedulingReminder = true
        defer { isSchedulingReminder = false }
        do {
            guard try await reminderScheduler.requestPermission() else {
                reminderMessage = "Notifications are off. Enable them for BillFlow in Settings, then try again."
                return
            }
            try Task.checkCancellation()
            try await reminderScheduler.schedule(bill: bill, at: date)
            reminderMessage = "Reminder scheduled for \(date.formatted(date: .abbreviated, time: .shortened))."
        } catch is CancellationError {
            reminderMessage = nil
        } catch {
            reminderMessage = "Couldn't schedule the reminder. Please try again."
        }
    }

}
