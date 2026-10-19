# Reading List — Flutter app

A mobile reading list built with **Flutter** and **Riverpod 3**, backed by the bookmarks API in [django-ninja-mongo-api](https://github.com/LacerdaTraderCode/django-ninja-mongo-api). It does what the web client in [nextjs-bookmarks-dashboard](https://github.com/LacerdaTraderCode/nextjs-bookmarks-dashboard) does: sign in or register, list bookmarks, filter by tag and read state, save a link, mark it read or unread, delete it, sign out.

The point of the project is how the app is put together: where the token lives, how a rejected session is handled, how the list state is kept from leaking between accounts, and what the tests do and do not prove. [`docs/architecture.md`](docs/architecture.md) explains each decision and its limits.

## What it demonstrates

- **Feature-first structure.** `core/` (config, network, session, widgets, theme), `app/` (router and root widget) and `features/auth`, `features/bookmarks`, each split into domain, data, application and presentation.
- **Session as the single source of truth.** One Riverpod notifier holds `restoring`, `signed out` or `signed in`. The router's redirects, the API client and the list state all follow it.
- **A rejected token signs the person out and says why.** A 401 on an authenticated request clears the stored token and shows an explanation on the sign-in screen. A wrong password on the login form is also a 401, and is not mistaken for an expired session.
- **List state scoped to the session.** The list controller is rebuilt empty when the token changes, so one account's bookmarks are never shown to the next, and an answer that arrives late is dropped.
- **One place for the wire format.** `Bookmark.fromJson` and the repositories are the only code that knows the API's `snake_case` fields.
- **Token in the platform keystore** through `flutter_secure_storage`, behind an interface so tests use an in-memory store.
- **Links are only opened when they are http or https**, because the API stores whatever URL string it is given.

## Stack

| Concern | Choice |
|---|---|
| UI | Flutter (Material 3, light and dark) |
| State | `flutter_riverpod` ^3.4.1 |
| HTTP | `dio` ^5.9.0 |
| Navigation | `go_router` (range 14.8.1 to below 18), session-driven redirects |
| Token storage | `flutter_secure_storage` (range 9.2.4 to below 11) |
| Opening links | `url_launcher` ^6.3.2 |
| Lints | `flutter_lints` ^6.0.0 with strict casts |

## Run it

The platform folders are not committed. Generate them once, remove the sample test that `flutter create` adds, and run:

```bash
flutter create . --platforms=android,ios
rm test/widget_test.dart   # the sample counter-app test does not belong to this project
flutter pub get
flutter run --dart-define=BOOKMARKS_API_URL=http://10.0.2.2:8000/api
```

`10.0.2.2` is how the Android emulator reaches the host machine. The default value of `BOOKMARKS_API_URL` is that same address. To try the app without MongoDB, the mock API in `nextjs-bookmarks-dashboard` (`npm run dev:mock`, demo account `demo@example.com` / `correct-horse`) implements the same contract on port 8000.

### Commands

| Command | What it does |
|---|---|
| `flutter analyze` | Static analysis |
| `flutter test` | The whole test suite |
| `flutter test --coverage` | Same, and writes `coverage/lcov.info` |

## Project layout

```
lib/
  app/            root widget, router with session redirects, splash screen
  core/
    config/       API base URL (compile-time define)
    network/      Dio providers, ApiClient, ApiException
    session/      session state, token store, token expiry check
    theme/        Material 3 themes
    widgets/      form error text and submit button shared by features
  features/
    auth/         domain (models, validators), data (repository), application (service), presentation
    bookmarks/    domain (model, filters, validation, formatting), data (repository),
                  application (list controller, link opener), presentation (screen, tile, filters, sheet)
test/
  support/        fakes for storage, repositories, links and the Dio adapter; a test environment
  core/ app/ features/ widget/
```

## Verification

The authoring environment could not run Flutter or Dart: `pub.dev` and the Dart SDK download are blocked there. **Nothing was compiled or run before the first CI run.** Everything below comes from the job logs of the GitHub Actions run on pull request #2.

- **Toolchain:** Flutter 3.47.7 (stable) on `ubuntu-24.04`.
- **Dependencies:** `flutter pub get` resolved the ranges in `pubspec.yaml`. Among the versions it picked: `flutter_secure_storage` 10.3.4 and `go_router` 17.5.0.
- **`flutter analyze`:** no issues in the final run.
- **`flutter test --coverage`:** 119 tests passed.
- **Coverage:** `Line coverage: 91.0% (608 of 668 lines)`.
- **Android:** `✓ Built build/app/outputs/flutter-apk/app-debug.apk` (Gradle `assembleDebug`, 338.2 s on a cold runner).

The first CI run is also part of the honest record. It found two problems in code that had been written blind: a lint asking for a null-aware map entry in `bookmark_filters.dart`, and a test helper that named a type (`Override`) that `flutter_riverpod` 3 does not export. Both were fixed on the pull request branch before merging.

### What the tests cover

- **Unit:** token expiry, bookmark parsing, filters and their API query, bookmark and auth validation, date and link formatting, the redirect rules.
- **API client**, on a fake Dio adapter: bearer header, query, JSON bodies, error mapping, unreachable API, and the difference between a rejected session and a wrong password.
- **Controllers and services:** session restore, sign in and out, expiry, registration, the list controller's filters and mutations, and its guards against stale answers and against showing one account's list to another.
- **Widget tests that run the whole app** (router, screens and Riverpod) on fakes: sign in, registration, validation messages, signing out, a rejected session, listing, filters, tag chips, read toggle, delete confirmation, saving a link, and links that must not open.

## What was not verified

- **A device or an emulator.** The debug APK was built, but never installed or run. Layout on real screens, the keyboard, the bottom sheet, secure storage on a real keystore and `url_launcher` actually launching a browser were not exercised. The widget tests use Flutter's headless test renderer.
- **The real HTTP stack against the real API.** Tests stop at a fake Dio adapter or a fake repository. The app has never talked to `django-ninja-mongo-api` or to the mock server.
- **Cleartext HTTP on Android.** From API 28 Android blocks plain `http://` traffic by default. Running against a local `http://` API probably needs `android:usesCleartextTraffic="true"` in the debug manifest generated by `flutter create`. This was not tried. A release build also needs the `INTERNET` permission in the main manifest; the generated debug and profile manifests carry it, the main one does not.
- **iOS.** Never built.
- **Platform folders.** They are generated, not committed, so the repository does not pin Gradle, the Android Gradle plugin or the Xcode project.
- **Code formatting.** `dart format` is not enforced. The code was written without the formatter, and CI does not check it.
- **Exact dependency versions.** There is no `pubspec.lock`, and `pubspec.yaml` uses ranges for two packages, so versions resolve at install time.
- **The coverage figure counts only files the tests load.** `main.dart` and the bodies of `SecureTokenStore` and `UrlLauncherLinkOpener` are not exercised.

## License

MIT
