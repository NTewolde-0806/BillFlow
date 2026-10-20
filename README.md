# BillFlow

A learning-focused SwiftUI portfolio app. All payments will be simulated; no bank integration or real charges.

## Step 1 — Domain and seeded data

Read `BillFlow/Domain/Bill.swift`, then `BillSeed.swift`, then the unit tests.

- `Bill` is a value type: changing a copy does not change the original.
- `Identifiable` gives SwiftUI stable row identity. Seed IDs stay fixed across calls.
- Amounts use integer cents in this USD-only demo: 6999 means $69.99.
- `Codable` prepares the data for local JSON persistence.
- Overdue is derived from the due date and payment state, rather than stored separately.
- Passing a date and calendar makes time-dependent behavior reproducible in tests.
- Domain files import Foundation only. Views and services will depend on the domain.

Build with Cmd+B. Run unit tests with Cmd+U (or select BillFlowTests in the Test navigator).
The starter screen is unchanged in this step.

Explain it back: Why use cents? Why does a bill due today remain current? Why should overdue status be calculated? Why do fixtures accept a reference date?

## Small implementation milestones

1. Domain, fixtures, and domain tests (this step).
2. SwiftUI bill list, currency formatting, and empty state.
3. Observable state and an async repository boundary; loading/error states.
4. Local JSON persistence and repository tests.
5. Async simulated payment service, success/failure states, and tests.
6. Local reminders, permission handling, and scheduling abstraction.
7. CI build/tests, accessibility checks, and portfolio documentation.

Start with folders for separation of responsibilities; extract packages when a concrete boundary earns it.
