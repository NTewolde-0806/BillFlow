# Validation and stable-branch review

## Automated baseline

On October 21, 2026, the exact CI script (`bash scripts/test.sh`) built the app and passed all 27 unit tests on iPhone 17 / iOS 27.0 with Xcode 27.1. Automatic simulator selection and the committed shared scheme were exercised. Workflow YAML parsed, shell syntax and scheme XML validated, and git diff checks passed. GitHub-hosted execution remains pending until push.

## Manual checks — results and remaining checks

- [ ] Fresh install shows expected names, amounts, dates and statuses.
- [x] Paid status survives relaunch (user verified October 22).
- [ ] A paid bill has no Pay or reminder control.
- [ ] Empty and error previews render correctly; retry leaves a usable screen.
- [x] Larger-text check passed (user verified October 22).
- [ ] VoiceOver reads the name, amount, date and status clearly and identifies each Pay/reminder button.
- [ ] Reminder permission is requested on scheduling, never on launch.
- [ ] Denying permission shows Settings guidance and schedules nothing.
- [x] A scheduled reminder arrives while the app is in the background (user verified October 22).
- [ ] Rescheduling a bill produces one pending reminder, not duplicates.
- [ ] Paying before a reminder fires cancels it.
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

The latest push retry failed with “Invalid username or token.” GitHub credentials must be corrected locally before pushing and validating hosted CI.
