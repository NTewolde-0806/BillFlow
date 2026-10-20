import SwiftUI

struct ContentView: View {
    let bills: [Bill]
    let referenceDate: Date

    init(bills: [Bill]? = nil, referenceDate: Date = .now) {
        self.referenceDate = referenceDate
        self.bills = bills ?? BillSeed.makeBills(relativeTo: referenceDate)
    }

    var body: some View {
        NavigationStack {
            Group {
                if bills.isEmpty {
                    ContentUnavailableView(
                        "No bills yet",
                        systemImage: "doc.text",
                        description: Text("Your bills will appear here.")
                    )
                } else {
                    List(bills) { bill in
                        BillRow(bill: bill, referenceDate: referenceDate)
                    }
                }
            }
            .navigationTitle("BillFlow")
        }
    }
}

#Preview("Seeded bills") {
    ContentView()
}

#Preview("Empty list") {
    ContentView(bills: [])
}
