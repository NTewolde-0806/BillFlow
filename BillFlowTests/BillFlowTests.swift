import Foundation
import Testing
@testable import BillFlow

@MainActor
struct BillFlowTests {
    private let today = Date(timeIntervalSince1970: 1_800_000_000)
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    @Test func overdueUsesCalendarDaysAndExcludesPaidBills() {
        let bills = BillSeed.makeBills(relativeTo: today, calendar: calendar)
        #expect(bills[0].isOverdue(asOf: today, calendar: calendar))
        #expect(!bills[1].isOverdue(asOf: today, calendar: calendar))
        #expect(!bills[2].isOverdue(asOf: today, calendar: calendar))
        var dueToday = bills[0]
        dueToday.dueDate = calendar.startOfDay(for: today)
        #expect(!dueToday.isOverdue(asOf: today, calendar: calendar))
    }

    @Test func seedsHaveStableUniqueIdentity() {
        let first = BillSeed.makeBills(relativeTo: today, calendar: calendar)
        let second = BillSeed.makeBills(relativeTo: today, calendar: calendar)
        #expect(first == second)
        #expect(Set(first.map(\.id)).count == first.count)
        #expect(first.allSatisfy { $0.amountInCents > 0 })
    }

    @Test func billsRoundTripThroughJSON() throws {
        let bills = BillSeed.makeBills(relativeTo: today, calendar: calendar)
        let data = try JSONEncoder().encode(bills)
        #expect(try JSONDecoder().decode([Bill].self, from: data) == bills)
    }
}
