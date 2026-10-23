import SwiftUI

struct ContentView: View {
    @State private var model: BillListModel
    @State private var reminderBill: Bill?

    init(reminderScheduler: (any BillReminderScheduler)? = nil, repository: (any BillRepository)? = nil, paymentService: (any PaymentService)? = nil) {
        _model = State(initialValue: BillListModel(reminderScheduler: reminderScheduler, repository: repository ?? LocalBillRepository(), paymentService: paymentService))
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
                                        .disabled(model.isPaying || model.isSchedulingReminder)
                                        .accessibilityLabel("Simulate payment for \(bill.name)")
                                        Button("Remind me…") {
                                            model.clearReminderMessage()
                                            reminderBill = bill
                                        }
                                        .buttonStyle(.bordered)
                                        .disabled(model.isPaying || model.isSchedulingReminder)
                                        .accessibilityLabel("Set reminder for \(bill.name)")
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
        .sheet(item: $reminderBill) { bill in
            BillReminderView(bill: bill, model: model)
        }
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
    ContentView(reminderScheduler: PreviewBillReminderScheduler(), repository: SeededBillRepository())
}

#Preview("Empty list") {
    ContentView(reminderScheduler: PreviewBillReminderScheduler(), repository: PreviewBillRepository(bills: []))
}

#Preview("Loading error") {
    ContentView(reminderScheduler: PreviewBillReminderScheduler(), repository: PreviewBillRepository(bills: nil))
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
    ContentView(reminderScheduler: PreviewBillReminderScheduler(), repository: SeededBillRepository(),
                paymentService: SimulatedPaymentService(shouldFail: true))
}
