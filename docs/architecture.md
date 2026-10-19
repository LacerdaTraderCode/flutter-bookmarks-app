# Architecture

This document explains why the app is built the way it is, and where each decision stops working. Start with the README for what the app does and what was verified.

## Scope

A client for an existing REST API. The goal is a small, correct mobile app: no code generation, no local database, no offline mode.

Out of scope: pagination and search (the API returns the full list), token refresh (the API issues access tokens only), offline support and optimistic UI.

## Layers

```
presentation (screens, widgets)
      │ reads state, calls
application  (controllers, services)
      │ uses
data         (repositories) ──► core/network (ApiClient) ──► Dio ──► API
      │ returns
domain       (models, filters, validation, formatting)
```

`core/` holds what every feature needs: config, the API client, the session and shared widgets. It does not import from `features/`. `app/` is the composition layer: it wires the router to the screens, so it is the one place allowed to know all of them.

Repositories are interfaces with an API implementation. Tests replace them, and the token store and the link opener, with fakes through Riverpod overrides.

## Session

`SessionController` is a notifier with three states:

- `SessionRestoring`: the stored token is still being read from secure storage;
- `SignedOut({expired})`: no usable token, and a flag saying whether the person was signed out because the token ran out or was rejected;
- `SignedIn(token)`.

On start-up it reads the token. A token whose `exp` claim has passed is cleared and reported as expired. `isTokenExpired` only reads that claim; the signature is verified by the API, so a token that cannot be parsed counts as not expired and the API decides.

Everything else follows this state:

- **The router.** `redirectFor(session, location)` is a pure function: restoring waits on the splash screen, signed out leads to the sign-in screen, signed in leaves the guest screens. go_router re-runs it whenever the session changes, through a `refreshListenable`. Screens never navigate after signing in or out; the session change does it.
- **The API client.** It reads the token lazily, at request time, so creating the client does not depend on the session being ready.
- **The list state**, described below.

## A rejected token

`ApiClient` treats a 401 as a rejected session only when the request carried a token. The sign-in form's 401 for a wrong password has no token, so it is an ordinary error with the API's message. When a token is rejected the client calls `SessionController.expire()`, which clears the token and moves to `SignedOut(expired: true)`; the router then shows the sign-in screen, which explains why.

`expire()` ignores the call when the state is not `SignedIn`. Several requests can fail with 401 at once, and a late one arriving after a manual sign-out must not show an expiry notice.

## API client and errors

`ApiClient` is a thin wrapper over Dio. Every failure becomes an `ApiException`, and no `DioException` leaves it:

- non-2xx answers are handled by the client (`validateStatus` accepts every status), so the API's `{"detail": "..."}` is kept;
- a 422 whose `detail` is a list is collapsed into one sentence instead of leaking its structure;
- a body that is not JSON falls back to a message with the status;
- any Dio failure, such as a timeout or no connection, becomes a 503 with a fixed "unreachable" message, and connection details never reach the screen.

`Bookmark.fromJson` and the two repositories are the only code that knows the wire format (`is_read`, `saved_at`, `full_name`).

## List state scoped to the session

`BookmarksController` holds the list, the active filters, a loading flag and an error message. Two counters protect it:

- `_sessionEpoch` is bumped when the state is rebuilt or disposed. The controller watches the session token, so a different token means a fresh, empty state: one account's bookmarks are never shown to the next. A response that arrives after that is dropped.
- `_loadSerial` is bumped by every load, so only the newest request may update the list. Changing a filter while a request is in flight cannot let the older answer overwrite the newer one.

Mutations return an error message to show, or null. Deleting a bookmark that is already gone (404) counts as done, because the refreshed list is what the person wanted. After a successful mutation the list is reloaded from the API rather than patched locally, so what is shown is what the server has.

## Validation and untrusted data

Validation is in pure functions in `domain/`, with the same rules as the web client: http or https only, a title, at most 10 tags of at most 32 characters, tags lowercased and de-duplicated. They run before anything is sent.

The API stores whatever URL string it receives, so the app does not trust what it reads back: `safeExternalUri` only returns http and https links, and a bookmark with any other scheme is shown but its tile does nothing when tapped.

## Testing strategy

| Level | What it proves | What it cannot catch |
|---|---|---|
| Unit tests of domain code | Parsing, filters, validation, formatting, token expiry, redirect rules | Anything involving Flutter or Riverpod wiring |
| `ApiClient` on a fake Dio adapter | Headers, query, bodies, error mapping, the 401 distinction | Differences between the fake and the real network and API |
| Controllers and services on a Riverpod container with fakes | Session transitions, filters, mutations, stale-response guards, per-session state | Rendering |
| Widget tests running the whole app on fakes | Router redirects, every screen, forms, dialogs, the bottom sheet, snack bars | Real devices, real storage, real HTTP |

The fakes replace storage, the repositories and the link opener. The HTTP layer is replaced only in the `ApiClient` tests.

## Known limits

- The list is unbounded, because the API has no pagination.
- Tag filtering is an exact match on one tag; there is no free-text search.
- There is no token refresh. When the token expires, the person signs in again.
- Dates are shown in UTC so the day does not depend on the device's time zone.
- No device or emulator run was done (see the README).
