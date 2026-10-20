import Foundation

/// One bill occurrence. Recurring schedules can create future occurrences later.
struct Bill: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    var name: String
    /// Integer cents avoid binary floating-point rounding for this USD demo.
    var amountInCents: Int
    var dueDate: Date
    var isPaid: Bool

    init(id: UUID = UUID(), name: String, amountInCents: Int,
         dueDate: Date, isPaid: Bool = false) {
        self.id = id
        self.name = name
        self.amountInCents = amountInCents
        self.dueDate = dueDate
        self.isPaid = isPaid
    }

    /// A bill becomes overdue the day after its due date in the supplied calendar.
    func isOverdue(asOf date: Date, calendar: Calendar = .current) -> Bool {
        !isPaid && calendar.startOfDay(for: dueDate) < calendar.startOfDay(for: date)
    }
}
