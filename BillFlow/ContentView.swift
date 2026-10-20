import SwiftUI

struct ContentView: View {
    @State private var model: BillListModel

    init(repository: (any BillRepository)? = nil) {
        _model = State(initialValue: BillListModel(repository: repository ?? LocalBillRepository()))
    }

    var body: some View {
        NavigationStack {
            Group {
                switch model.state {
                case .idle, .loading:
                    ProgressView("Loading bills…")
                case .failed:
                    ContentUnavailableView {
                        Label("Couldn't load bills", systemImage: "exclamationmark.triangle")
                    } description: {
                        Text("Please try again.")
                    } actions: {
                        Button("Retry") {
                            Task { await model.load() }
                        }
                    }
                case .loaded(let bills):
                    if bills.isEmpty {
                        ContentUnavailableView(
                            "No bills yet",
                            systemImage: "doc.text",
                            description: Text("Your bills will appear here.")
                        )
                    } else {
                        List(bills) { bill in
                            BillRow(bill: bill, referenceDate: .now)
                        }
                    }
                }
            }
            .navigationTitle("BillFlow")
        }
        .task { await model.load() }
    }
}

#Preview("Seeded bills") {
    ContentView(repository: SeededBillRepository())
}

#Preview("Empty list") {
    ContentView(repository: PreviewBillRepository(bills: []))
}

#Preview("Loading error") {
    ContentView(repository: PreviewBillRepository(bills: nil))
}

private struct PreviewBillRepository: BillRepository {
    let bills: [Bill]?

    func fetchBills() async throws -> [Bill] {
        guard let bills else { throw PreviewError.unavailable }
        return bills
    }

    enum PreviewError: Error { case unavailable }
}
