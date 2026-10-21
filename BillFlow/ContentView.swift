import SwiftUI

struct ContentView: View {
    @State private var model: BillListModel

    init(repository: (any BillRepository)? = nil, paymentService: (any PaymentService)? = nil) {
        _model = State(initialValue: BillListModel(repository: repository ?? LocalBillRepository(), paymentService: paymentService))
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
                            VStack(alignment: .leading, spacing: 8) {
                                BillRow(bill: bill, referenceDate: .now)
                                if !bill.isPaid {
                                    if model.paymentState == .processing(bill.id) {
                                        ProgressView("Simulating payment…")
                                    } else {
                                        Button("Pay (demo)") {
                                            Task { await model.pay(billID: bill.id) }
                                        }
                                        .buttonStyle(.bordered)
                                        .disabled(model.isPaying)
                                        .accessibilityLabel("Simulate payment for \(bill.name)")
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("BillFlow")
        }
        .task { await model.load() }
        .alert("Payment update", isPresented: Binding(
            get: { if case .failed = model.paymentState { return true }; return false },
            set: { if !$0 { model.dismissPaymentError() } }
        )) {
            Button("OK") { model.dismissPaymentError() }
        } message: {
            if case .failed(let message) = model.paymentState { Text(message) }
        }
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

private final class PreviewBillRepository: BillRepository {
    var bills: [Bill]?

    init(bills: [Bill]?) { self.bills = bills }

    func saveBills(_ bills: [Bill]) async throws { self.bills = bills }

    func fetchBills() async throws -> [Bill] {
        guard let bills else { throw PreviewError.unavailable }
        return bills
    }

    enum PreviewError: Error { case unavailable }
}

#Preview("Payment failure") {
    ContentView(repository: SeededBillRepository(),
                paymentService: SimulatedPaymentService(shouldFail: true))
}
