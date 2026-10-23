# Validation and stable-branch review

## Automated baseline

On October 21, 2026, the exact CI script (`bash scripts/test.sh`) built the app and passed all 27 unit tests on iPhone 17 / iOS 27.0 with Xcode 27.1. Automatic simulator selection and the committed shared scheme were exercised. Workflow YAML parsed, shell syntax and scheme XML validated, and git diff checks passed. GitHub-hosted CI passed on October 22 for commit `fbc8a14`: [successful run](https://github.com/NTewolde-0806/BillFlow/actions/runs/39836160109).

## Manual checks — results and remaining checks

- [x] Fresh-install bill details passed (user verified on iPhone 17e October 23); seeded names, amounts and statuses also observed directly by the assistant.
- [x] Paid status survives relaunch (user verified October 22).
- [x] Paid bills have no Pay or reminder controls (observed Internet and Rent in simulator October 22).
- [x] Empty and error previews, including visible Retry behavior, passed (user verified October 23). The error fixture intentionally keeps failing; recovery is separately unit-tested.
- [x] Larger-text check passed (user verified October 22).
- [x] VoiceOver reads all elements clearly, including bill and reminder controls (user verified on physical iPhone October 22).
- [x] No notification prompt on fresh launch (user verified October 23); explicit scheduling permission behavior verified in the physical-device checks.
- [x] Permission-denial scenario passed on physical iPhone (user verified October 22).
- [x] A scheduled reminder arrives while the app is in the background (user verified October 22).
- [x] Rescheduling scenario passed: only the later reminder arrives (user verified on physical iPhone October 22).
- [x] Scheduled Electricity reminder, paid before the deadline, backgrounded the app, and observed no reminder after the scheduled minute (simulator October 22; not a direct inspection of the OS pending-request store).
- [x] Reminder-sheet controls and messages have clear VoiceOver speech (user verified October 22).
- [x] Reminder-sheet date selection, progress and messages fit at maximum accessibility text size (user verified October 23).

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

## Physical-device validation — October 22

After updating the phone and running BillFlow on it, the user reported successful permission-denial and rescheduling scenarios and confirmed that all elements were spoken clearly by VoiceOver. These user-observed results complete the corresponding checks above. They do not independently establish an OS pending-request count.

Remaining unchecked items are fresh-install fixture appearance, empty/error preview rendering and visible retry behavior, no permission prompt on launch, and the reminder sheet at large text sizes. These have not been silently treated as passed. The personal development-team setting is preserved locally and excluded from this documentation commit.

## Final validation — October 23

The user reported that all remaining checks passed on iPhone 17e: fresh-install appearance with no launch-time permission prompt, empty/error previews and Retry behavior, and the reminder sheet at maximum accessibility text size. The assistant directly observed the seeded bill list with expected names, amounts and Overdue/Upcoming/Paid statuses. The subsequent reminder-sheet retest hit a Computer Use timeout, so the other visual passes are explicitly user-verified, not independently repeated by the assistant.

All agreed manual checklist items now have passing evidence. No app source changed during this final validation. The latest verified hosted baseline before this documentation update is [eea8d0c](https://github.com/NTewolde-0806/BillFlow/actions/runs/39858249884). The documentation update will trigger a fresh CI run. The pre-merge code review found no additional blocking issues within the documented demo scope.

Ready for the final merge decision once the latest CI is green. No merge has been performed. The personal development-team settings remain uncommitted local changes and are excluded from the feature commits.
