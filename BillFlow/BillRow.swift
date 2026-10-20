import SwiftUI

struct BillRow: View {
    let bill: Bill
    let referenceDate: Date

    private var status: String {
        if bill.isPaid { return "Paid" }
        return bill.isOverdue(asOf: referenceDate) ? "Overdue" : "Upcoming"
    }

    private var statusColor: Color {
        if bill.isPaid { return .green }
        return bill.isOverdue(asOf: referenceDate) ? .red : .secondary
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(bill.name)
                .font(.headline)
            Text(Decimal(bill.amountInCents) / 100, format: .currency(code: "USD"))
                .font(.title3)
                .monospacedDigit()
            Text("Due \(bill.dueDate.formatted(date: .abbreviated, time: .omitted))")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(status)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(statusColor)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}

#Preview("Bill statuses") {
    let referenceDate = Date.now
    List(BillSeed.makeBills(relativeTo: referenceDate)) { bill in
        BillRow(bill: bill, referenceDate: referenceDate)
    }
}

#Preview("Accessibility text size") {
    let referenceDate = Date.now
    List(BillSeed.makeBills(relativeTo: referenceDate)) { bill in
        BillRow(bill: bill, referenceDate: referenceDate)
    }
    .environment(\.dynamicTypeSize, .accessibility3)
}
