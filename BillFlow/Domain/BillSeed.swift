import Foundation

/// Demo fixtures only; persistence will decide when to seed a new installation.
enum BillSeed {
    static func makeBills(relativeTo date: Date, calendar: Calendar = .current) -> [Bill] {
        let today = calendar.startOfDay(for: date)
        func day(_ offset: Int) -> Date {
            calendar.date(byAdding: .day, value: offset, to: today)!
        }

        return [
            Bill(id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
                 name: "Electricity", amountInCents: 8450, dueDate: day(-2)),
            Bill(id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
                 name: "Internet", amountInCents: 6999, dueDate: day(3)),
            Bill(id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
                 name: "Rent", amountInCents: 150000, dueDate: day(-5), isPaid: true)
        ]
    }
}
