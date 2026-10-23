import SwiftUI

struct BillReminderView: View {
    let bill: Bill
    let model: BillListModel
    @State private var date = Date.now.addingTimeInterval(60)
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section(bill.name) {
                    DatePicker("Remind me", selection: $date, in: Date.now...)
                    Button("Schedule reminder") {
                        Task { await model.scheduleReminder(billID: bill.id, at: date) }
                    }
                    .disabled(model.isSchedulingReminder)
                    if model.isSchedulingReminder { ProgressView("Scheduling…") }
                    if let message = model.reminderMessage {
                        Text(message)
                            .accessibilityAddTraits(.updatesFrequently)
                    }
                }
            }
            .navigationTitle("Bill reminder")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .disabled(model.isSchedulingReminder)
                }
            }
        }
        .interactiveDismissDisabled(model.isSchedulingReminder)
    }
}
