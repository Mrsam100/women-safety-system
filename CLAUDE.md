# SafeRide — Claude Code Instructions

## Project Overview

SafeRide is an AI-powered women cab safety app built with Flutter + Firebase. It monitors rides in real-time using GPS, on-device AI, and automated emergency alerts.

See `PROJECT_PLAN.md` for the full feature list, architecture, database schema, and implementation phases.

## Tech Stack

- **Frontend:** Flutter (Dart)
- **State Management:** Riverpod 3.x with code generation (`riverpod_annotation` + `build_runner`)
- **Navigation:** go_router with auth guard redirects
- **Backend:** Firebase (Auth, Firestore, Cloud Storage, Cloud Functions)
- **Maps:** Google Maps SDK + Directions API
- **SMS:** Twilio via Cloud Functions + native telephony for offline
- **Push:** Firebase Cloud Messaging (FCM)
- **AI:** TFLite (Whisper Tiny) for on-device keyword detection
- **Audio:** record package + just_audio
- **Local Storage:** Hive + flutter_secure_storage
- **Encryption:** AES-256 via encrypt package

## Architecture Rules

### Clean Architecture (Mandatory)

Every feature follows this structure — no exceptions:

```
features/{feature_name}/
  data/
    datasources/     → Remote (Firebase) and local (Hive) data sources
    models/          → Serializable models (toJson, fromJson, toEntity)
    repositories/    → Repository implementations
  domain/
    entities/        → Immutable business objects
    repositories/    → Abstract repository interfaces
    usecases/        → Single-responsibility use cases
  presentation/
    providers/       → Riverpod providers
    screens/         → Full-page widgets
    widgets/         → Reusable UI components for this feature
```

### Shared Code

Shared utilities, services, and widgets go in `lib/core/` — never in a feature directory.

### State Management

- Use Riverpod 3.x with `@riverpod` annotations and code generation
- Run `dart run build_runner build --delete-conflicting-outputs` after adding/modifying providers
- One provider per concern — don't overload providers

### Navigation

- All routes defined in `lib/core/router/app_router.dart`
- Route names as constants in `lib/core/constants/route_names.dart`
- Auth guards redirect unauthenticated users to `/auth`
- Profile completion guard redirects to `/profile-setup`

## Code Conventions

### Dart/Flutter

- Use `const` constructors wherever possible
- Prefer `final` over `var`
- Use `freezed` for immutable data classes and union types
- Use `dartz Either<Failure, T>` for error handling in repositories and use cases
- File naming: `snake_case.dart`
- Class naming: `PascalCase`
- Private members: prefix with `_`
- Max line length: 80 characters

### Firebase

- Firestore references go in datasource files, never in UI
- All Firestore writes must go through repository → use case → provider chain
- Security rules must match — never rely on client-side validation alone
- Cloud Functions in TypeScript, located in `firebase/functions/src/`

### Error Handling

- Use `Failure` subclasses from `lib/core/errors/failures.dart`
- Catch Firebase exceptions in repository implementations, convert to `Failure`
- Never let raw exceptions reach the UI layer
- Show user-friendly error messages, log technical details

### Testing

- Unit tests for every use case and repository implementation
- Widget tests for every screen's core interactions
- Integration tests for critical flows (auth, panic, ride)
- Target: 80% code coverage
- Test files mirror source structure: `test/unit/features/auth/...`

## Key Services (in lib/core/services/)

| Service | Responsibility |
|---------|---------------|
| `location_service.dart` | GPS tracking (foreground + background), location stream |
| `audio_service.dart` | Recording, circular buffer, playback |
| `shake_service.dart` | Accelerometer-based shake detection |
| `sms_service.dart` | Native SMS dispatch (offline) + Cloud Function trigger (online) |
| `battery_service.dart` | Battery level monitoring |
| `connectivity_service.dart` | Online/offline state stream |
| `notification_service.dart` | FCM token management, push handling |
| `permission_service.dart` | Runtime permission requests |
| `local_storage_service.dart` | Hive wrapper for offline cache |

## Critical Implementation Notes

### Panic Button (`trigger_panic.dart`)
This is the most important file in the app. It orchestrates:
1. GPS capture (current location)
2. Audio evidence save (last 30 seconds, encrypted)
3. SMS dispatch to all emergency contacts
4. Firestore alert creation
5. Push notification to contacts with the app
6. Live tracking update (isEmergency: true)

All steps must run in parallel where possible. Must work offline (queue and sync).

### Offline-First
- Panic button MUST work without internet
- GPS points cached in Hive, synced when online
- SMS sent via native telephony when offline, via Twilio Cloud Function when online
- Firestore offline persistence enabled

### Privacy
- Audio is processed ON-DEVICE only (TFLite)
- No audio leaves the phone unless emergency is triggered
- Audio evidence is AES-256 encrypted before upload
- All ride data auto-deletes after 30 days unless user saves it
- No camera, no driver monitoring

### Background Execution
- `flutter_background_geolocation` for GPS during background/screen-off
- Audio buffer runs as long as ride is active
- Shake detection runs as long as ride is active

## Commands

```bash
# Get dependencies
flutter pub get

# Code generation (after modifying providers, freezed classes, JSON models)
dart run build_runner build --delete-conflicting-outputs

# Run app
flutter run

# Run tests
flutter test

# Run specific test
flutter test test/unit/features/auth/

# Build Android release
flutter build appbundle --release

# Build iOS release
flutter build ipa --release

# Build web (contact dashboard)
flutter build web --release --web-renderer canvaskit

# Deploy Cloud Functions
cd firebase/functions && npm run deploy

# Deploy web dashboard
firebase deploy --only hosting

# Deploy Firestore rules
firebase deploy --only firestore:rules

# Analyze code
flutter analyze
```

## Firestore Collections

| Collection | Purpose |
|-----------|---------|
| `/users/{userId}` | User profile, settings |
| `/users/{userId}/emergencyContacts/{id}` | Emergency contacts |
| `/users/{userId}/rides/{rideId}` | Ride records |
| `/users/{userId}/rides/{rideId}/locationTrail/{id}` | GPS points during ride |
| `/users/{userId}/rides/{rideId}/alerts/{id}` | Alerts triggered during ride |
| `/users/{userId}/audioEvidence/{id}` | Encrypted audio evidence metadata |
| `/liveTracking/{rideId}` | Real-time location (top-level for fast reads) |
| `/trackingTokens/{token}` | Web dashboard access tokens |
| `/areaData/{geohash}` | Aggregated area safety scores |

## Theme Colors

| Name | Hex | Usage |
|------|-----|-------|
| Primary | `#6C3EC1` | Main brand color (deep purple) |
| Danger | `#FF6B6B` | Panic button, emergency states |
| Safe | `#4CAF50` | Safe status, ride active |
| Warning | `#FFA726` | Caution alerts |
| Background | `#F5F5F5` | Light mode background |
| Surface | `#FFFFFF` | Cards, sheets |

## Don'ts

- Don't put Firebase calls directly in UI widgets
- Don't skip the domain layer (no direct datasource → provider)
- Don't store API keys in source code (use `--dart-define`)
- Don't send audio to any server during normal rides
- Don't record or monitor the driver in any way
- Don't use `setState` — use Riverpod providers
- Don't create God-widgets — break into small, focused components
- Don't ignore offline scenarios — every critical feature must work without internet
