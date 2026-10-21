import Foundation
import UserNotifications

@MainActor
protocol BillReminderScheduler {
    func requestPermission() async throws -> Bool
    func schedule(bill: Bill, at date: Date) async throws
    func cancel(billID: UUID)
}

struct LocalBillReminderScheduler: BillReminderScheduler {
    private let center: UNUserNotificationCenter

    init(center: UNUserNotificationCenter? = nil) {
        self.center = center ?? .current()
    }

    func requestPermission() async throws -> Bool {
        try await center.requestAuthorization(options: [.alert, .sound])
    }

    func schedule(bill: Bill, at date: Date) async throws {
        guard !bill.isPaid, date > .now else { throw ReminderError.invalidRequest }
        let content = UNMutableNotificationContent()
        content.title = "Bill reminder"
        content.body = "Check your \(bill.name) bill in BillFlow."
        content.sound = .default
        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second], from: date
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: Self.identifier(for: bill.id),
                                            content: content, trigger: trigger)
        try await center.add(request)
    }

    func cancel(billID: UUID) {
        let identifiers = [Self.identifier(for: billID)]
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
        center.removeDeliveredNotifications(withIdentifiers: identifiers)
    }

    static func identifier(for billID: UUID) -> String {
        "bill-reminder-\(billID.uuidString)"
    }

    enum ReminderError: Error { case invalidRequest }
}

/// In-memory scheduler for previews. Does not prompt or schedule system notifications.
final class PreviewBillReminderScheduler: BillReminderScheduler {
    private var dates: [UUID: Date] = [:]
    func requestPermission() async throws -> Bool { true }
    func schedule(bill: Bill, at date: Date) async throws { dates[bill.id] = date }
    func cancel(billID: UUID) { dates[billID] = nil }
}
