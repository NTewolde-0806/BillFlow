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
Step 1 establishes the domain independently of the screen.

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

## Step 2 — Seeded SwiftUI list

In step 2, `ContentView` accepted bills and a reference date directly. Step 3 replaces that initializer with repository injection; the empty preview now supplies a repository returning no bills. `List` uses each bill's stable ID to track rows.

`BillRow` only presents a bill. Decimal currency formatting converts integer cents into a localized USD amount. Status includes a text label as well as color, and the vertical layout accommodates larger text. VoiceOver reads each row as a combined element.

Run the app: Electricity should show $84.50 / Overdue, Internet $69.99 / Upcoming, and Rent $1,500.00 / Paid (formatting varies by locale). Open both previews, increase Dynamic Type, and check VoiceOver reading order. No payment action is available yet.

Explain it back: Why pass data into the screen? How does List identify a row? Why keep currency formatting in the view? What is the difference between a view's input and state it owns?

Next: introduce observable state and an async repository, then show loading and error states.

## Source control workflow

Create a feature branch from main before starting each step. Commit a completed step after appropriate verification, noting any checks that could not run. Merge to main only after we agree the step is stable. Push or open a pull request when requested.

`BillRow.swift` includes previews for all three statuses and accessibility text size.

## Step 3 — Observable state and async loading

Read `Data/BillRepository.swift`, `BillListModel.swift`, then `ContentView.swift`.

- The repository protocol defines an async, throwing fetch operation. Today's implementation returns seeds after a short simulated delay; a later implementation will read local storage.
- The main-actor observable model owns an enum: idle, loading, loaded, or failed. An enum prevents contradictory combinations such as loading and failed at once.
- `@State` preserves the model across SwiftUI view updates. The view renders the current state.
- `.task` starts loading when the screen appears and participates in SwiftUI cancellation. Cancellation returns to idle instead of showing a failure.
- Retry calls the same load method. A guard avoids overlapping fetches.

Build with Cmd+B and run BillFlowTests with Cmd+U. Run the app to see the brief loading indicator and populated list. Use the empty and error previews to inspect those states. The error preview intentionally keeps failing when retried; the retry unit test uses a repository that recovers.

Explain it back: What does `async throws` promise? Why depend on a protocol? Why does the UI model use the main actor? How does an enum simplify screen state?

Next: replace seeded fetching with local JSON persistence and test storage behavior.

Step 3 validation: app and test targets compiled; all 7 unit tests passed on the iPhone 17 / iOS 27.0 simulator.

## Step 4 — Local JSON persistence

Read `Data/BillFileStore.swift`, then `Data/LocalBillRepository.swift`. The model and fetch protocol are unchanged: the screen now defaults to the local repository. Previews explicitly use fixtures so they never touch app storage.

- Bills live in the app sandbox's Application Support/BillFlow/bills.json.
- The first fetch creates directories and saves seeds only if the file is missing.
- Subsequent loads preserve dates, IDs, paid status, and even an empty array.
- The file-store actor serializes its own operations away from the main actor. The repository handles JSON encoding/decoding; the small demo payload is encoded on the main actor.
- Atomic writes replace the complete file. This is a single-app demo, not a database or cross-process transaction system.
- A corrupt file or other storage error propagates to the existing error screen. Retry does not erase or repair the data.
- `saveBills` is ready for the later payment/edit flow. The UI is still read-only.

Run the app twice to confirm due dates persist. The four storage tests use unique temporary folders and remove them afterward; they never access the app's real data. For a fresh demo, uninstall the simulator app, which removes its sandbox.

Explain it back: Why distinguish a missing file from an empty list? What does an atomic write protect against? Why put disk access in an actor? Why should a decode failure not trigger reseeding?

Next: simulated async payments and saving their results, with failure-path tests.

Step 4 validation: app/test targets compiled; all 11 unit tests passed on iPhone 17 / iOS 27.0, including four persistence tests.
