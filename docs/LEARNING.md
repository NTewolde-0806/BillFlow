# Learning guide

These notes record each implementation step in order. Earlier steps describe the app as it existed at that point. See the root README for current behavior.

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

## Step 5 — Simulated payments

Read `Payments/PaymentService.swift`, then `BillListModel.pay(billID:)`, then the Pay button in `ContentView`.

The service simulates a delay and either succeeds or throws; it never sends money. The model guards against duplicate requests, already-paid bills, and unknown IDs. It keeps the loaded list visible while one payment runs and blocks reloads until it finishes.

After simulation succeeds, the model saves a modified copy of the bill list. It publishes that copy only after saving succeeds. Payment failure and save failure show different messages; both leave the visible bill unpaid. A successful save removes the Pay button and survives relaunch. This demonstration is not a real payment transaction system; a real gateway would require durable receipts, idempotency, and reconciliation when payment succeeds but local saving fails.

`BillRepository` now includes saving. The seeded repository stores changes in memory for interactive previews; the local repository writes JSON. The payment-failure preview deliberately fails every payment. Cancellation before simulation completes leaves bills unchanged; cancellation/error while saving is reported because the outcome needs attention.

Manual check: pay Electricity, observe progress and Paid status, then relaunch to verify persistence. In the Payment failure preview, tap Pay and confirm the failure alert leaves the bill unpaid. Check larger text and VoiceOver; the Pay button identifies its bill.

Explain it back: Why save before publishing Paid? Why guard payment calls in the model as well as disable buttons? Why are payment and storage separate dependencies? What extra problem would a real payment gateway introduce if saving failed?

Next: local reminder permission handling and scheduling through a testable abstraction.

Step 5 validation (October 21, 2026): app/test targets compiled; all 18 unit tests passed on iPhone 17 / iOS 27.0. The first test launch timed out; the retry after simulator startup passed. Manual visual and VoiceOver checks remain.

## Step 6 — Local reminders

Read `Reminders/BillReminderScheduler.swift`, `BillListModel.scheduleReminder`, then `Reminders/BillReminderView.swift`.

Tap Remind me on an unpaid bill, choose a future date/time, then Schedule reminder. Only this explicit action requests notification permission. The sheet reports success, permission denial with Settings guidance, or failure. Paid bills have no reminder control. Scheduling and payment cannot run concurrently.

The system scheduler uses UserNotifications and a nonrepeating calendar trigger. The bill UUID forms a stable notification identifier, so scheduling again replaces that bill's pending request. After a payment is saved, its pending and delivered reminders are removed. A failed payment/save leaves the reminder in place. Bill JSON remains focused on bill data; the OS stores pending reminder requests. This step does not display a persistent reminder toggle or list of pending reminders.

Manual device/simulator checks: choose a minute ahead, grant permission, tap Done, then background the app and wait. Foreground banners are not enabled in this step. Try denying permission and check Settings guidance. Schedule a reminder, pay the bill before it fires, and verify no notification arrives. Focus and notification settings may affect presentation. Re-schedule the same bill to check it replaces rather than duplicates the pending request. Previews use an in-memory scheduler and never prompt.

Tests use a scheduler stub: permission grant/denial/error, future-date validation, schedule failure/retry, paid/unknown bills, cancellation, concurrency guards, and cancellation only after payment is saved. System delivery still requires the manual checks above.

Explain it back: Why request permission when scheduling rather than on launch? Why use the bill ID for the notification request? Why cancel only after saving payment? Why is a stub useful even though it cannot prove iOS delivers a notification?

Next: CI build/tests and portfolio documentation, followed by a stable-branch review.

Apple reference: https://developer.apple.com/documentation/usernotifications/scheduling-a-notification-locally-from-your-app

Step 6 validation: app/test targets compiled; all 27 unit tests passed on iPhone 17 / iOS 27.0. System permission/delivery, Focus behavior and VoiceOver still require manual verification.

## Step 7 — CI and portfolio documentation

Read `.github/workflows/ios.yml`, then `scripts/test.sh`, then the shared scheme under `BillFlow.xcodeproj/xcshareddata/xcschemes`.

The workflow checks out source, selects Xcode 27.1 on GitHub's Xcode 27 runner, and invokes the same test script used locally. The script chooses an available iOS 27+ iPhone simulator, preferring an already booted device, and runs the app's unit suite. It exits with xcodebuild's status, so failed tests fail the job. The workflow uploads a result bundle even after failure when one exists. The job has read-only repository permissions and a 20-minute limit; newer runs on the same ref cancel older ones.

A shared scheme is committed project configuration: a fresh checkout can find the same test target without relying on a developer's private Xcode settings. The UI-test target is still a starter template and is excluded from this unit-test baseline.

The root README now explains current behavior and tradeoffs to a reviewer; this file retains the learning history. `docs/VALIDATION.md` separates automated evidence from pending device, notification and accessibility checks. No badges, screenshots, hosted-CI passes, or UI-test coverage are claimed without evidence.

Validation: the exact script built and passed all 27 tests locally with Xcode 27.1 on iPhone 17 / iOS 27.0. Hosted CI remains pending until push.

Explain it back: Why commit a shared scheme? Why use the same test command locally and in CI? Why keep result artifacts when the job fails? What can passing unit tests tell us, and what remains a manual check?

Next: complete manual validation, run hosted CI once pushing is requested, and review the full branch before agreeing to merge it to main.
