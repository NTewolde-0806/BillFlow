# Validation and stable-branch review

## Automated baseline

On October 21, 2026, the exact CI script (`bash scripts/test.sh`) built the app and passed all 27 unit tests on iPhone 17 / iOS 27.0 with Xcode 27.1. Automatic simulator selection and the committed shared scheme were exercised. Workflow YAML parsed, shell syntax and scheme XML validated, and git diff checks passed. GitHub-hosted CI passed on October 22 for commit `fbc8a14`: [successful run](https://github.com/NTewolde-0806/BillFlow/actions/runs/39836160109).

## Manual checks — results and remaining checks

- [ ] Fresh install shows expected names, amounts, dates and statuses.
- [x] Paid status survives relaunch (user verified October 22).
- [x] Paid bills have no Pay or reminder controls (observed Internet and Rent in simulator October 22).
- [ ] Empty and error previews render correctly; retry leaves a usable screen.
- [x] Larger-text check passed (user verified October 22).
- [ ] VoiceOver reads the name, amount, date and status clearly and identifies each Pay/reminder button.
- [ ] Reminder permission is requested on scheduling, never on launch.
- [ ] Denying permission shows Settings guidance and schedules nothing.
- [x] A scheduled reminder arrives while the app is in the background (user verified October 22).
- [ ] Rescheduling a bill produces one pending reminder, not duplicates.
- [x] Scheduled Electricity reminder, paid before the deadline, backgrounded the app, and observed no reminder after the scheduled minute (simulator October 22; not a direct inspection of the OS pending-request store).
- [ ] Reminder-sheet date selection, progress and messages work with VoiceOver and large text.

## CI explanation checkpoint

Why commit a shared scheme? Why run the same script locally and in CI? Why save test-result artifacts on failure? Why do passing unit tests not replace the manual checks above?

## Before merging to main

Review the final diff and automated results, complete the manual checks, then agree the branch is stable. Once pushing is requested, verify the hosted Actions run too. No merges or pushes are performed automatically by this workflow.

## October 22 validation session

- The exact CI script rebuilt the current workspace and passed all 27 unit tests on iPhone 17 / iOS 27.0 with Xcode 27.1. Result bundle: `/tmp/BillFlow-Oct22.xcresult` (local artifact, not part of the repo).
- Preserved Xcode's shared-scheme normalization, launcher setting and document-versioning update; this scheme was used by the passing test run.
- The feature-branch push was rejected by GitHub because the saved Personal Access Token lacks the `workflow` scope required to create `.github/workflows/ios.yml`. Hosted CI has not run. Credential changes must be completed locally by the user, without sharing a token in chat.
- Native UI automation timed out or took several minutes per observation. The user subsequently confirmed payment persistence after relaunch, background reminder delivery, and larger-text behavior. VoiceOver was explicitly not tested; other unchecked scenarios above remain unverified.
- No merge to main has been performed.

The credential errors described above were resolved by the user pushing from Terminal. The branch now tracks origin/feature/ci-and-documentation. Hosted build/tests and artifact upload passed for `fbc8a14`.

After the ChatGPT restart, native app inventory, Xcode accessibility inspection and Device Hub screenshots succeeded promptly. Screenshot access is verified. This does not establish VoiceOver behavior inside BillFlow.

Simulator inspection after restart: the accessibility tree exposes combined bill details and bill-specific action labels. The reminder sheet exposes date/time controls, Schedule, Done and the successful scheduling message. These checks verify exposed semantics and a scheduling result, not spoken VoiceOver navigation. No additional notification delivery or cancellation scenario is claimed.

Additional October 22 validation: hosted CI [passed for dd5c326](https://github.com/NTewolde-0806/BillFlow/actions/runs/39838176748). The simulator cancellation scenario changed Electricity to Paid; all three saved demo bills are now paid. Fresh data is needed for further unpaid-bill reminder checks; no data reset was performed. Permission-denial, duplicate-rescheduling, fresh-install, preview and spoken VoiceOver checks remain pending.

## Pre-merge code review — October 22

Reviewed the domain and fixtures, observable loading/payment/reminder state, repository and file-store boundaries, notification adapter, screen/row/reminder views, unit tests, shared scheme, test script, CI workflow and README. No additional blocking defect was identified in the reviewed demo flows. This is a static review result, not proof of unexercised UI or OS behavior.

Confirmed by source/test inspection: empty saved data is not reseeded; corrupt files are preserved; payment state is published after saving; duplicate concurrent actions are guarded; permission denial has Settings guidance; notification requests use stable bill identifiers. The 27 unit tests and successful hosted CI remain the automated evidence. Notification adapter delivery, actual permission denial and duplicate pending requests still require their manual checks.

The separate iPhone 17e live display timed out (DeviceKit error 4002), so it did not establish a fresh-install or denied-permission result. The ContentView preview canvas was refreshed but stalled preparing its simulator and the UI connection timed out. Empty/error preview checks remain pending rather than being inferred from the model tests.

The user is updating their physical iPhone before building for spoken VoiceOver checks. Local project signing settings are user work in progress and were not staged in this documentation update. Existing simulator bill data was not reset. Main remains unchanged; merge readiness is deferred until outstanding validation is resolved or explicitly accepted.
