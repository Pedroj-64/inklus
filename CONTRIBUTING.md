# Contributing to Inklus

*[Leer en español](CONTRIBUTING.es.md)*

Thanks for helping! Inklus is a free, open-source (GPL-3.0-or-later), offline-first handwriting app for stylus tablets. Everything stays free: no premium features, no paid dependencies.

## Quick start

```bash
flutter pub get
flutter analyze                        # must report 0 issues
flutter test                           # unit and widget tests
flutter test integration_test -d linux # end-to-end flows
flutter run -d linux                   # develop on desktop
```

Flutter 3.50 / Dart 3.13. Before touching the canvas, read [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) (the "critical flows" section lists what must not break: stylus input and palm rejection, paint layers, undo/redo, export).

## Ground rules

- **Offline-first.** Nothing local may depend on the network or an account. Google Drive is an optional backup.
- **UI follows the design system**: colors, spacing and text roles come from the theme, never literals. See [`docs/DESIGN_SYSTEM.md`](docs/DESIGN_SYSTEM.md).
- **All user-visible text goes through the ARB files** (`context.l10n.key`). See [`docs/TRANSLATING.md`](docs/TRANSLATING.md).
- **Code comments and the in-app source language are Spanish** (`app_es.arb` is the source); English is fully supported in the UI. Write comments in Spanish unless you are not comfortable, in which case English is fine and a maintainer will help.
- **Never commit secrets** (`android/key.properties`, `*.jks`, `client_secret*.json`). CI runs a secret scan.
- Add or update tests for logic changes. Bug fixes should include a regression test.

## Workflow

1. Open an issue first for anything larger than a small fix, so we can agree on the approach.
2. Fork, then branch from `main`: `feat/short-name`, `fix/short-name`, `docs/short-name`.
3. Keep PRs focused: one concern per PR.
4. Make sure `flutter analyze` is clean and `flutter test` passes.
5. Open the PR using the template. Screenshots are required for UI changes (`flutter test tool/screenshots/screenshots_test.dart` renders the real UI without a device).

## Commit messages

[Conventional Commits](https://www.conventionalcommits.org/): `feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `chore:`, optionally with a scope (`fix(canvas): ...`). Spanish or English are both fine.

## Sign-off (DCO)

There is no CLA. Instead, certify the [Developer Certificate of Origin](https://developercertificate.org/) by signing off each commit:

```bash
git commit -s -m "fix(canvas): ..."
```

This adds `Signed-off-by: Your Name <you@example.com>` and means you wrote the change or have the right to submit it under the project license.

## Translating

New languages and corrections are very welcome and need no Dart knowledge. See [`docs/TRANSLATING.md`](docs/TRANSLATING.md).

## Reporting problems

- Bugs and ideas: use the issue templates.
- Security issues: **do not** open a public issue; see [`SECURITY.md`](SECURITY.md).
- Conduct concerns: see [`CODE_OF_CONDUCT.md`](CODE_OF_CONDUCT.md).
