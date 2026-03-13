# SafeRide — AI-Powered Women Cab Safety System

## Complete Project Plan, Architecture & Feature Specification

---

## 1. Project Overview

SafeRide is a mobile safety application for women passengers using cab services. It uses real-time GPS tracking, on-device AI monitoring, and automated emergency alerts to detect danger and act — even when the user can't.

**Problem:** Women face real safety risks during cab rides — harassment, route deviations, kidnapping, assault. Existing solutions (calling someone, sharing location manually) are reactive, slow, and require conscious effort during a crisis.

**Solution:** A system that monitors rides passively and can detect danger and trigger emergency protocols automatically.

---

## 2. Target Users

| User | Role |
|------|------|
| **Primary** | Women passengers (age 18-45, urban, using Ola/Uber/autos) |
| **Secondary** | Emergency contacts (family, friends) |
| **Tertiary** | Cab companies wanting to add a safety layer |
| **Future** | Solo women travelers, delivery workers, night-shift commuters |

---

## 3. Technology Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Flutter (Dart) |
| State Management | Riverpod 3.x with code generation |
| Navigation | go_router with auth guards |
| Backend | Firebase (Auth, Firestore, Cloud Storage, Cloud Functions) |
| Maps & GPS | Google Maps SDK + Directions API |
| Background Location | flutter_background_geolocation |
| SMS | Twilio (via Cloud Functions) + native telephony (offline) |
| Push Notifications | Firebase Cloud Messaging (FCM) |
| AI / ML | TFLite (Whisper Tiny) for on-device keyword detection |
| Audio | record package + just_audio |
| Local Storage | Hive + flutter_secure_storage |
| Encryption | AES-256 via encrypt package |
| Web Dashboard | Flutter Web on Firebase Hosting |

---

## 4. Architecture

### 4.1 Architecture Pattern

**Clean Architecture** with feature-first folder structure:

```
Each feature follows:
  data/       → datasources (remote/local), models, repository implementations
  domain/     → entities, abstract repositories, use cases
  presentation/ → providers (Riverpod), screens, widgets
```

### 4.2 Key Architecture Decisions

| Decision | Rationale |
|----------|-----------|
| Feature-first folders | Each feature is self-contained; easy to work on independently |
| Riverpod 3.x + codegen | Type-safe, testable state management with minimal boilerplate |
| go_router | Declarative routing with auth guards and deep linking support |
| Offline-first | Hive for local cache, Firestore offline persistence, queued SMS — safety must work without internet |
| On-device AI | Audio never leaves the phone unless emergency triggers — privacy by design |
| AES-256 encryption | Audio evidence encrypted on device before upload |
| Separate liveTracking collection | Top-level Firestore collection for real-time reads (avoids nested query limitations) |

### 4.3 System Architecture Diagram

```
┌──────────────────────────────────────────────────┐
│                  FLUTTER APP                      │
│                                                   │
│  ┌──────────┐ ┌──────────┐ ┌───────────────────┐ │
│  │ GPS      │ │ Audio    │ │ Shake Detector    │ │
│  │ Service  │ │ Service  │ │ (accelerometer)   │ │
│  └────┬─────┘ └────┬─────┘ └────────┬──────────┘ │
│       │            │                 │             │
│  ┌────▼────────────▼─────────────────▼──────────┐ │
│  │          Threat Scoring Engine                │ │
│  │   (combines all signals → 0-100 score)       │ │
│  └────────────────────┬─────────────────────────┘ │
│                       │                            │
│  ┌────────────────────▼─────────────────────────┐ │
│  │         Emergency Protocol Orchestrator       │ │
│  │  GPS capture │ Audio save │ SMS │ Firestore   │ │
│  └────────────────────┬─────────────────────────┘ │
│                       │                            │
│  ┌────────────────────▼─────────────────────────┐ │
│  │    On-Device AI (Whisper Tiny TFLite)        │ │
│  │    Runs on background Isolate                 │ │
│  │    Audio NEVER leaves device unless emergency │ │
│  └──────────────────────────────────────────────┘ │
└───────────────────────┬──────────────────────────┘
                        │
            ┌───────────▼───────────┐
            │    Firebase Backend    │
            │                       │
            │  Auth (Phone OTP)     │
            │  Firestore (ride DB)  │
            │  Cloud Storage (audio)│
            │  Cloud Functions:     │
            │   → Twilio SMS        │
            │   → Push Notifs (FCM) │
            │   → Auto-escalation   │
            │   → Data retention    │
            │  Hosting (web dash)   │
            └───────────┬───────────┘
                        │
            ┌───────────▼───────────┐
            │  Google Maps Platform  │
            │  Maps SDK + Directions │
            └───────────────────────┘
```

### 4.4 Threat Scoring System

```
SIGNAL                                POINTS
──────────────────────────────────────────────
Route deviation (>1.5km, >2min)       +30
Speed anomaly (>100km/h)              +25
Distress keyword detected             +20 * confidence
Isolated area + nighttime             +15
Stopped for extended time             +10
Shake alert triggered                 +35
Panic button pressed                  +50 (instant max)
Area risk level (from aggregated data)+0 to +10

SCORE = min(100, sum of active signals)

THRESHOLDS:
  0-30   → Green  (normal, no action)
  31-60  → Yellow (in-app: "Are you safe?" — 60s to respond)
  61-80  → Orange (auto-notify emergency contacts with advisory)
  81-100 → Red    (full emergency protocol — SMS + audio + location blast)
```

---

## 5. Complete Feature List (30 Features)

### 5.1 Core Safety Features

| # | Feature | Description | Phase |
|---|---------|-------------|-------|
| 1 | **Panic Button** | Large red button, always visible during ride. One tap → GPS + audio recording + SMS to all contacts + Firestore alert. 3-second long-press to prevent accidental triggers. | 1 |
| 2 | **Shake to Alert** | Shake phone 3x rapidly (>15 m/s² within 2s) → triggers silent panic. No UI feedback for stealth. | 1 |
| 3 | **Live Location Sharing** | On ride start, auto-sends live tracking link via SMS to all emergency contacts. Updates every 10 seconds. | 1 |
| 4 | **Fake Call** | Generates realistic fake incoming call with configurable caller name and delay (5/15/30s). Accept → plays pre-recorded conversation. | 1 |
| 5 | **Route Deviation Alert** | Compares actual GPS vs expected route every 30s. Alerts if >1.5km deviation sustained for >2 minutes. | 1 |
| 6 | **Speed Anomaly Alert** | Alerts if cab >100km/h or stopped in isolated area for >5 min at night (8pm-6am). | 1 |
| 7 | **Low Battery Alert** | Sends last known location to all contacts when battery drops below 10%. | 1 |
| 8 | **Offline Emergency Mode** | Panic button works without internet — queues SMS via native telephony, caches GPS in Hive, syncs when network returns. | 1 |

### 5.2 AI Features (On-Device)

| # | Feature | Description | Phase |
|---|---------|-------------|-------|
| 9 | **Voice Keyword Detection** | Whisper Tiny TFLite on background Isolate. Detects: "help", "bachao", "stop", "chhodo", "please help", "let me go", "save me", "police". 3-second audio chunks, entirely on-phone. | 2 |
| 10 | **Threat Scoring Engine** | Combines all signals into 0-100 score. Recalculates every 10 seconds. Drives auto-escalation. | 2 |
| 11 | **Auto-Escalation** | Yellow → prompt user. Orange → notify contacts. Red → full emergency. No user action needed. | 2 |

### 5.3 User Management

| # | Feature | Description | Phase |
|---|---------|-------------|-------|
| 12 | **OTP Login** | Phone number + OTP via Firebase Auth. Auto-retrieval on Android. 60s resend timer. | 1 |
| 13 | **Emergency Contacts** | Add 3-5 trusted contacts with name, phone, relationship. Pick from phone contacts. | 1 |
| 14 | **Profile Setup** | Name, photo (camera/gallery), blood group, medical notes. | 1 |

### 5.4 Ride Management

| # | Feature | Description | Phase |
|---|---------|-------------|-------|
| 15 | **Start/End Ride** | One tap to enter safety mode. Optional destination input for route tracking. | 1 |
| 16 | **Live Map View** | Google Maps with live marker, expected route (blue polyline), actual route (green → red on deviation). | 1 |
| 17 | **Ride History** | List of all past rides — date, duration, status, alert count. | 1 |
| 18 | **Ride Summary** | Map with route taken, timeline of events, safety score, duration, distance. | 1 |

### 5.5 Emergency Contact Side

| # | Feature | Description | Phase |
|---|---------|-------------|-------|
| 19 | **Contact Dashboard (Web)** | Web app at tracking link — no app install needed. Shows live map, route, alert timeline, emergency status. "Call" and "Call Police" buttons. | 2 |
| 20 | **SMS Alerts** | Contacts receive SMS with location link on any emergency trigger. | 1 |
| 21 | **Push Notifications** | Contacts with the app get instant push alerts via FCM. | 2 |

### 5.6 Evidence & Storage

| # | Feature | Description | Phase |
|---|---------|-------------|-------|
| 22 | **Audio Evidence Vault** | Circular 30-second buffer. On emergency, last 30s saved, AES-256 encrypted, uploaded to Cloud Storage. | 1 |
| 23 | **Location Trail** | GPS every 10s → Hive locally → batch upload to Firestore every 60s. Visualized on ride summary. | 1 |
| 24 | **Auto-Delete Policy** | Evidence auto-deletes after 30 days via Cloud Function. User can "save" to prevent deletion. | 1 |
| 25 | **User Data Control** | View, download, or delete all personal data anytime. Full GDPR compliance. | 1 |

### 5.7 Settings & Extras

| # | Feature | Description | Phase |
|---|---------|-------------|-------|
| 26 | **Permission Manager** | Granular control over mic, location, shake detection permissions. | 1 |
| 27 | **Alert Sensitivity** | Low / Medium / High — adjusts threat scoring thresholds to reduce false alerts. | 2 |
| 28 | **Multi-language** | English + Hindi (Phase 1). Tamil, Telugu, Bengali, Marathi (Phase 2). | 1-2 |
| 29 | **Onboarding Tutorial** | First-time walkthrough explaining every feature with Lottie animations. | 1 |
| 30 | **Safety Rating** | Post-ride 1-5 star safety rating. Aggregated into area safety heatmap data. | 2 |

---

## 6. Complete Folder Structure

```
c:\Users\Lenovo\women-safety-system\
│
├── android/
├── ios/
├── web/                                    # Contact dashboard
│
├── assets/
│   ├── images/
│   ├── icons/
│   ├── animations/                         # Lottie files
│   ├── fonts/
│   ├── audio/                              # Fake call ringtones
│   └── models/                             # TFLite models
│       └── whisper_tiny.tflite
│
├── firebase/
│   └── functions/
│       ├── src/
│       │   ├── index.ts                    # Cloud Functions entry point
│       │   ├── sms/
│       │   │   └── sendSms.ts              # Twilio SMS dispatch
│       │   ├── notifications/
│       │   │   └── pushNotification.ts     # FCM push
│       │   ├── escalation/
│       │   │   └── autoEscalate.ts         # Server-side escalation
│       │   ├── dataRetention.ts            # Scheduled cleanup
│       │   └── userData.ts                 # Data export/delete
│       ├── package.json
│       └── tsconfig.json
│
├── lib/
│   ├── main.dart                           # Entry point
│   ├── app.dart                            # MaterialApp.router + ProviderScope
│   ├── firebase_options.dart               # Generated by FlutterFire CLI
│   │
│   ├── core/
│   │   ├── constants/
│   │   │   ├── app_colors.dart
│   │   │   ├── app_strings.dart
│   │   │   ├── app_dimensions.dart
│   │   │   ├── api_constants.dart
│   │   │   └── route_names.dart
│   │   │
│   │   ├── theme/
│   │   │   ├── app_theme.dart              # Light + Dark themes
│   │   │   ├── text_styles.dart
│   │   │   └── widget_themes.dart
│   │   │
│   │   ├── router/
│   │   │   └── app_router.dart             # GoRouter + auth guards
│   │   │
│   │   ├── errors/
│   │   │   ├── failures.dart               # Failure classes
│   │   │   └── exceptions.dart             # Exception classes
│   │   │
│   │   ├── utils/
│   │   │   ├── validators.dart
│   │   │   ├── distance_calculator.dart
│   │   │   ├── permission_handler.dart
│   │   │   └── logger.dart
│   │   │
│   │   ├── extensions/
│   │   │   ├── context_extensions.dart
│   │   │   ├── string_extensions.dart
│   │   │   └── datetime_extensions.dart
│   │   │
│   │   ├── widgets/
│   │   │   ├── app_button.dart
│   │   │   ├── app_text_field.dart
│   │   │   ├── loading_overlay.dart
│   │   │   ├── error_widget.dart
│   │   │   └── safe_area_wrapper.dart
│   │   │
│   │   ├── services/
│   │   │   ├── location_service.dart       # GPS + background tracking
│   │   │   ├── audio_service.dart          # Recording + playback
│   │   │   ├── shake_service.dart          # Accelerometer detection
│   │   │   ├── sms_service.dart            # Native SMS dispatch
│   │   │   ├── battery_service.dart        # Battery monitoring
│   │   │   ├── connectivity_service.dart   # Online/offline detection
│   │   │   ├── notification_service.dart   # FCM + local notifications
│   │   │   ├── permission_service.dart     # Runtime permissions
│   │   │   └── local_storage_service.dart  # Hive wrapper
│   │   │
│   │   └── providers/
│   │       ├── firebase_providers.dart     # Firebase instance providers
│   │       ├── service_providers.dart      # Service singletons
│   │       └── shared_providers.dart       # Shared app state
│   │
│   ├── features/
│   │   │
│   │   ├── auth/
│   │   │   ├── data/
│   │   │   │   ├── datasources/
│   │   │   │   │   └── auth_remote_datasource.dart
│   │   │   │   ├── models/
│   │   │   │   │   └── user_model.dart
│   │   │   │   └── repositories/
│   │   │   │       └── auth_repository_impl.dart
│   │   │   ├── domain/
│   │   │   │   ├── entities/
│   │   │   │   │   └── user_entity.dart
│   │   │   │   ├── repositories/
│   │   │   │   │   └── auth_repository.dart
│   │   │   │   └── usecases/
│   │   │   │       ├── send_otp.dart
│   │   │   │       ├── verify_otp.dart
│   │   │   │       └── sign_out.dart
│   │   │   └── presentation/
│   │   │       ├── providers/
│   │   │       │   └── auth_provider.dart
│   │   │       ├── screens/
│   │   │       │   ├── phone_input_screen.dart
│   │   │       │   ├── otp_verification_screen.dart
│   │   │       │   └── auth_wrapper.dart
│   │   │       └── widgets/
│   │   │           ├── otp_input_field.dart
│   │   │           └── phone_input_field.dart
│   │   │
│   │   ├── profile/
│   │   │   ├── data/
│   │   │   │   ├── datasources/
│   │   │   │   │   └── profile_remote_datasource.dart
│   │   │   │   ├── models/
│   │   │   │   │   └── profile_model.dart
│   │   │   │   └── repositories/
│   │   │   │       └── profile_repository_impl.dart
│   │   │   ├── domain/
│   │   │   │   ├── entities/
│   │   │   │   │   └── profile_entity.dart
│   │   │   │   ├── repositories/
│   │   │   │   │   └── profile_repository.dart
│   │   │   │   └── usecases/
│   │   │   │       ├── get_profile.dart
│   │   │   │       ├── update_profile.dart
│   │   │   │       └── upload_photo.dart
│   │   │   └── presentation/
│   │   │       ├── providers/
│   │   │       │   └── profile_provider.dart
│   │   │       ├── screens/
│   │   │       │   └── profile_setup_screen.dart
│   │   │       └── widgets/
│   │   │           ├── avatar_picker.dart
│   │   │           └── medical_info_form.dart
│   │   │
│   │   ├── emergency_contacts/
│   │   │   ├── data/
│   │   │   │   ├── datasources/
│   │   │   │   │   └── contacts_remote_datasource.dart
│   │   │   │   ├── models/
│   │   │   │   │   └── contact_model.dart
│   │   │   │   └── repositories/
│   │   │   │       └── contacts_repository_impl.dart
│   │   │   ├── domain/
│   │   │   │   ├── entities/
│   │   │   │   │   └── emergency_contact.dart
│   │   │   │   ├── repositories/
│   │   │   │   │   └── contacts_repository.dart
│   │   │   │   └── usecases/
│   │   │   │       ├── add_contact.dart
│   │   │   │       ├── remove_contact.dart
│   │   │   │       └── get_contacts.dart
│   │   │   └── presentation/
│   │   │       ├── providers/
│   │   │       │   └── contacts_provider.dart
│   │   │       ├── screens/
│   │   │       │   └── manage_contacts_screen.dart
│   │   │       └── widgets/
│   │   │           ├── contact_card.dart
│   │   │           └── add_contact_dialog.dart
│   │   │
│   │   ├── safety/
│   │   │   ├── data/
│   │   │   │   ├── datasources/
│   │   │   │   │   ├── safety_remote_datasource.dart
│   │   │   │   │   └── safety_local_datasource.dart
│   │   │   │   ├── models/
│   │   │   │   │   ├── alert_model.dart
│   │   │   │   │   └── safety_event_model.dart
│   │   │   │   └── repositories/
│   │   │   │       └── safety_repository_impl.dart
│   │   │   ├── domain/
│   │   │   │   ├── entities/
│   │   │   │   │   ├── alert.dart
│   │   │   │   │   └── safety_event.dart
│   │   │   │   ├── repositories/
│   │   │   │   │   └── safety_repository.dart
│   │   │   │   └── usecases/
│   │   │   │       ├── trigger_panic.dart
│   │   │   │       ├── trigger_fake_call.dart
│   │   │   │       ├── start_shake_detection.dart
│   │   │   │       └── send_emergency_alert.dart
│   │   │   └── presentation/
│   │   │       ├── providers/
│   │   │       │   ├── panic_provider.dart
│   │   │       │   ├── shake_provider.dart
│   │   │       │   └── fake_call_provider.dart
│   │   │       ├── screens/
│   │   │       │   ├── panic_screen.dart
│   │   │       │   └── fake_call_screen.dart
│   │   │       └── widgets/
│   │   │           ├── panic_button.dart
│   │   │           └── safety_status_indicator.dart
│   │   │
│   │   ├── ride/
│   │   │   ├── data/
│   │   │   │   ├── datasources/
│   │   │   │   │   ├── ride_remote_datasource.dart
│   │   │   │   │   └── ride_local_datasource.dart
│   │   │   │   ├── models/
│   │   │   │   │   ├── ride_model.dart
│   │   │   │   │   └── route_point_model.dart
│   │   │   │   └── repositories/
│   │   │   │       └── ride_repository_impl.dart
│   │   │   ├── domain/
│   │   │   │   ├── entities/
│   │   │   │   │   ├── ride.dart
│   │   │   │   │   └── route_point.dart
│   │   │   │   ├── repositories/
│   │   │   │   │   └── ride_repository.dart
│   │   │   │   └── usecases/
│   │   │   │       ├── start_ride.dart
│   │   │   │       ├── end_ride.dart
│   │   │   │       ├── get_ride_history.dart
│   │   │   │       └── check_route_deviation.dart
│   │   │   └── presentation/
│   │   │       ├── providers/
│   │   │       │   ├── ride_provider.dart
│   │   │       │   ├── map_provider.dart
│   │   │       │   └── ride_history_provider.dart
│   │   │       ├── screens/
│   │   │       │   ├── ride_screen.dart
│   │   │       │   ├── ride_history_screen.dart
│   │   │       │   └── ride_summary_screen.dart
│   │   │       └── widgets/
│   │   │           ├── ride_map.dart
│   │   │           ├── ride_controls.dart
│   │   │           ├── route_overlay.dart
│   │   │           └── ride_history_card.dart
│   │   │
│   │   ├── alerts/
│   │   │   ├── data/
│   │   │   │   ├── datasources/
│   │   │   │   │   └── alerts_remote_datasource.dart
│   │   │   │   ├── models/
│   │   │   │   │   └── alert_config_model.dart
│   │   │   │   └── repositories/
│   │   │   │       └── alerts_repository_impl.dart
│   │   │   ├── domain/
│   │   │   │   ├── entities/
│   │   │   │   │   └── alert_config.dart
│   │   │   │   ├── repositories/
│   │   │   │   │   └── alerts_repository.dart
│   │   │   │   └── usecases/
│   │   │   │       ├── check_route_deviation.dart
│   │   │   │       ├── check_speed_anomaly.dart
│   │   │   │       └── check_low_battery.dart
│   │   │   └── presentation/
│   │   │       ├── providers/
│   │   │       │   └── alerts_provider.dart
│   │   │       └── widgets/
│   │   │           ├── alert_banner.dart
│   │   │           └── alert_dialog.dart
│   │   │
│   │   ├── evidence/
│   │   │   ├── data/
│   │   │   │   ├── datasources/
│   │   │   │   │   ├── evidence_local_datasource.dart
│   │   │   │   │   └── evidence_remote_datasource.dart
│   │   │   │   ├── models/
│   │   │   │   │   ├── audio_evidence_model.dart
│   │   │   │   │   └── location_trail_model.dart
│   │   │   │   └── repositories/
│   │   │   │       └── evidence_repository_impl.dart
│   │   │   ├── domain/
│   │   │   │   ├── entities/
│   │   │   │   │   ├── audio_evidence.dart
│   │   │   │   │   └── location_trail.dart
│   │   │   │   ├── repositories/
│   │   │   │   │   └── evidence_repository.dart
│   │   │   │   └── usecases/
│   │   │   │       ├── save_audio_evidence.dart
│   │   │   │       ├── get_location_trail.dart
│   │   │   │       └── auto_delete_old_data.dart
│   │   │   └── presentation/
│   │   │       ├── providers/
│   │   │       │   └── evidence_provider.dart
│   │   │       └── screens/
│   │   │           └── evidence_vault_screen.dart
│   │   │
│   │   ├── ai/
│   │   │   ├── data/
│   │   │   │   ├── datasources/
│   │   │   │   │   └── tflite_datasource.dart
│   │   │   │   ├── models/
│   │   │   │   │   ├── keyword_detection_result.dart
│   │   │   │   │   └── threat_score_model.dart
│   │   │   │   └── repositories/
│   │   │   │       └── ai_repository_impl.dart
│   │   │   ├── domain/
│   │   │   │   ├── entities/
│   │   │   │   │   └── threat_assessment.dart
│   │   │   │   ├── repositories/
│   │   │   │   │   └── ai_repository.dart
│   │   │   │   └── usecases/
│   │   │   │       ├── detect_keywords.dart
│   │   │   │       ├── calculate_threat_score.dart
│   │   │   │       └── auto_escalate.dart
│   │   │   └── presentation/
│   │   │       ├── providers/
│   │   │       │   └── ai_provider.dart
│   │   │       └── widgets/
│   │   │           └── threat_score_indicator.dart
│   │   │
│   │   ├── contact_dashboard/
│   │   │   ├── data/
│   │   │   │   └── datasources/
│   │   │   │       └── dashboard_remote_datasource.dart
│   │   │   ├── domain/
│   │   │   │   └── usecases/
│   │   │   │       └── get_live_tracking_data.dart
│   │   │   └── presentation/
│   │   │       ├── providers/
│   │   │       │   └── dashboard_provider.dart
│   │   │       ├── screens/
│   │   │       │   └── contact_dashboard_screen.dart
│   │   │       └── widgets/
│   │   │           ├── live_map_widget.dart
│   │   │           └── alert_timeline.dart
│   │   │
│   │   ├── onboarding/
│   │   │   └── presentation/
│   │   │       ├── screens/
│   │   │       │   └── onboarding_screen.dart
│   │   │       └── widgets/
│   │   │           └── onboarding_page.dart
│   │   │
│   │   ├── settings/
│   │   │   ├── data/
│   │   │   │   ├── models/
│   │   │   │   │   └── settings_model.dart
│   │   │   │   └── repositories/
│   │   │   │       └── settings_repository_impl.dart
│   │   │   ├── domain/
│   │   │   │   ├── entities/
│   │   │   │   │   └── app_settings.dart
│   │   │   │   └── repositories/
│   │   │   │       └── settings_repository.dart
│   │   │   └── presentation/
│   │   │       ├── providers/
│   │   │       │   └── settings_provider.dart
│   │   │       ├── screens/
│   │   │       │   └── settings_screen.dart
│   │   │       └── widgets/
│   │   │           ├── sensitivity_slider.dart
│   │   │           └── language_selector.dart
│   │   │
│   │   └── home/
│   │       └── presentation/
│   │           ├── screens/
│   │           │   └── home_screen.dart
│   │           └── widgets/
│   │               ├── safety_dashboard.dart
│   │               ├── quick_actions.dart
│   │               └── ride_status_card.dart
│   │
│   └── l10n/
│       ├── app_en.arb
│       ├── app_hi.arb
│       ├── app_ta.arb
│       ├── app_te.arb
│       ├── app_bn.arb
│       └── app_mr.arb
│
├── test/
│   ├── unit/
│   │   ├── features/
│   │   │   ├── auth/
│   │   │   ├── safety/
│   │   │   ├── ride/
│   │   │   ├── alerts/
│   │   │   ├── evidence/
│   │   │   └── ai/
│   │   └── core/
│   │       └── services/
│   ├── widget/
│   │   ├── features/
│   │   │   ├── auth/
│   │   │   ├── safety/
│   │   │   └── ride/
│   │   └── core/
│   │       └── widgets/
│   └── integration/
│       ├── panic_flow_test.dart
│       ├── ride_flow_test.dart
│       └── auth_flow_test.dart
│
├── pubspec.yaml
├── analysis_options.yaml
├── l10n.yaml
├── firebase.json
├── firestore.rules
├── firestore.indexes.json
├── storage.rules
├── .firebaserc
├── .gitignore
├── CLAUDE.md
└── PROJECT_PLAN.md                         # This file
```

---

## 7. Database Schema (Firestore)

```
/users/{userId}
  ├── uid: string
  ├── phoneNumber: string
  ├── displayName: string
  ├── photoUrl: string?
  ├── bloodGroup: string?
  ├── medicalNotes: string?
  ├── fcmToken: string?
  ├── language: string                      // "en", "hi", etc.
  ├── alertSensitivity: string              // "low", "medium", "high"
  ├── createdAt: timestamp
  ├── updatedAt: timestamp
  │
  ├── /emergencyContacts/{contactId}
  │     ├── name: string
  │     ├── phoneNumber: string
  │     ├── relationship: string
  │     ├── hasApp: bool
  │     ├── fcmToken: string?
  │     └── createdAt: timestamp
  │
  ├── /rides/{rideId}
  │     ├── status: string                  // "active" | "completed" | "emergency"
  │     ├── startLocation: geopoint
  │     ├── startAddress: string
  │     ├── endLocation: geopoint?
  │     ├── endAddress: string?
  │     ├── expectedRoute: array<geopoint>
  │     ├── safetyScore: number?
  │     ├── alertsTriggered: number
  │     ├── startedAt: timestamp
  │     ├── endedAt: timestamp?
  │     ├── durationMinutes: number?
  │     ├── distanceKm: number?
  │     ├── userRating: number?             // 1-5
  │     │
  │     ├── /locationTrail/{pointId}
  │     │     ├── location: geopoint
  │     │     ├── speed: number             // km/h
  │     │     ├── bearing: number
  │     │     ├── accuracy: number
  │     │     ├── batteryLevel: number
  │     │     └── timestamp: timestamp
  │     │
  │     └── /alerts/{alertId}
  │           ├── type: string              // "panic" | "shake" | "route_deviation" |
  │           │                             //  "speed_anomaly" | "low_battery" |
  │           │                             //  "keyword_detected" | "auto_escalation"
  │           ├── severity: string          // "low" | "medium" | "high" | "critical"
  │           ├── location: geopoint
  │           ├── details: map
  │           ├── threatScore: number?
  │           ├── resolved: bool
  │           ├── notifiedContacts: array<string>
  │           └── timestamp: timestamp
  │
  └── /audioEvidence/{evidenceId}
        ├── rideId: string
        ├── alertId: string?
        ├── storageUrl: string
        ├── durationSeconds: number
        ├── encryptionKey: string
        ├── createdAt: timestamp
        └── expiresAt: timestamp            // createdAt + 30 days

/liveTracking/{rideId}                      // Top-level for real-time reads
  ├── userId: string
  ├── currentLocation: geopoint
  ├── speed: number
  ├── bearing: number
  ├── batteryLevel: number
  ├── isEmergency: bool
  ├── threatScore: number
  ├── activeAlerts: array<string>
  ├── startLocation: geopoint
  ├── expectedRoute: array<geopoint>
  └── updatedAt: timestamp

/trackingTokens/{token}                     // Short-lived tokens for web dashboard
  ├── rideId: string
  ├── userId: string
  ├── contactId: string
  ├── expiresAt: timestamp
  └── createdAt: timestamp

/areaData/{geohash}                         // Aggregated safety data per area
  ├── totalRides: number
  ├── averageRating: number
  ├── incidentCount: number
  ├── lastUpdated: timestamp
  └── riskLevel: string                     // "safe" | "moderate" | "risky"
```

---

## 8. Implementation Phases

### PHASE 1: Project Setup & Foundation (3-4 days)

| Sub-phase | Tasks |
|-----------|-------|
| **1.1 Flutter Init** | `flutter create`, set min SDK versions, delete boilerplate |
| **1.2 Dependencies** | Add all packages to pubspec.yaml, run `flutter pub get` |
| **1.3 Firebase Setup** | Create project, `flutterfire configure`, enable Auth/Firestore/Storage/FCM, init Cloud Functions |
| **1.4 Core Scaffold** | Create `main.dart`, `app.dart`, error handling, theme, router, all core services, shared widgets, providers |

### PHASE 2: Authentication & User Management (4-5 days)

| Sub-phase | Tasks |
|-----------|-------|
| **2.1 OTP Auth** | Phone input → OTP verification → auth wrapper with state routing |
| **2.2 Profile Setup** | Name, photo, blood group, medical notes form |
| **2.3 Emergency Contacts** | Add/remove contacts, phone picker, 3-5 limit enforcement |

### PHASE 3: Core Safety Features (7-8 days)

| Sub-phase | Tasks |
|-----------|-------|
| **3.1 Panic Button** | Large red button, 3s long-press, triggers GPS + audio + SMS + Firestore |
| **3.2 Shake to Alert** | Accelerometer detection (3 shakes, >15 m/s², 2s window), silent panic |
| **3.3 Fake Call** | Configurable caller/delay, realistic call UI, pre-recorded audio |
| **3.4 Live Location Sharing** | Generate token, SMS tracking link, 10s GPS updates, background mode |
| **3.5 Offline Mode** | Queue SMS via native telephony, cache GPS in Hive, sync on reconnect |

### PHASE 4: Ride Management & Maps (6-7 days)

| Sub-phase | Tasks |
|-----------|-------|
| **4.1 Start/End Ride** | Safety mode toggle, optional destination, permission requests |
| **4.2 Live Map** | Google Maps, live marker, expected route (blue), actual route (green→red) |
| **4.3 Ride History** | List view with date/duration/status, summary with map + timeline |

### PHASE 5: Alert System & Emergency Protocol (5-6 days)

| Sub-phase | Tasks |
|-----------|-------|
| **5.1 Route Deviation** | Compare GPS vs route every 30s, alert if >1.5km for >2min |
| **5.2 Speed Anomaly** | Alert if >100km/h or isolated stop at night >5min |
| **5.3 Low Battery** | Send last location at <10% battery |
| **5.4 Emergency Orchestrator** | Central coordinator for all triggers → parallel GPS + audio + SMS + Firestore + push |

### PHASE 6: Evidence Storage & Data Management (4-5 days)

| Sub-phase | Tasks |
|-----------|-------|
| **6.1 Audio Vault** | 30s circular buffer, AES-256 encrypt, upload to Cloud Storage |
| **6.2 Location Trail** | GPS every 10s → Hive → batch Firestore upload every 60s |
| **6.3 Auto-Delete** | Cloud Function for 30-day expiry, user save/delete/export controls |

### PHASE 7: AI Layer (6-7 days)

| Sub-phase | Tasks |
|-----------|-------|
| **7.1 Keyword Detection** | Whisper Tiny TFLite on background Isolate, 3s audio chunks, keyword matching |
| **7.2 Threat Scoring** | Weighted signal combination → 0-100 score, recalculate every 10s |
| **7.3 Auto-Escalation** | Yellow (prompt) → Orange (notify contacts) → Red (full emergency) |

### PHASE 8: Contact Dashboard & Notifications (5-6 days)

| Sub-phase | Tasks |
|-----------|-------|
| **8.1 Web Dashboard** | Flutter Web, token-based access, live map, alert timeline, call buttons |
| **8.2 Push Notifications** | FCM setup, Cloud Function dispatch, deep linking |
| **8.3 Safety Rating** | Post-ride 1-5 stars, Cloud Function aggregates to area data |

### PHASE 9: Settings, Polish & Testing (5-6 days)

| Sub-phase | Tasks |
|-----------|-------|
| **9.1 Settings** | Sensitivity, shake toggle, fake call config, language, dark mode, data management |
| **9.2 Multi-language** | Flutter intl: English + Hindi (Phase 1), more languages later |
| **9.3 Testing** | Unit (~80%), widget, integration tests + performance benchmarks |
| **9.4 UI Polish** | Shimmer loading, error/empty states, haptics, transitions, accessibility |

### PHASE 10: Deployment & Launch (3-4 days)

| Sub-phase | Tasks |
|-----------|-------|
| **10.1 Pre-launch** | Beta distribution, Crashlytics, Analytics, app icons, splash screen |
| **10.2 Security Audit** | Firestore rules, API key restrictions, encryption verification |
| **10.3 Store Submission** | Android (Play Store), iOS (App Store), Web (Firebase Hosting) |

---

## 9. Build Order (Dependency Graph)

```
Phase 1 (Foundation)
  └── Phase 2 (Auth)
        ├── Phase 3 (Safety) ──→ Phase 5 (Alerts) ──→ Phase 7 (AI) ──→ Phase 8.2-8.3
        ├── Phase 4 (Ride)   ──→ Phase 5 (Alerts)
        └── Phase 6 (Evidence) ──→ Phase 7 (AI)

Phase 8.1 (Web Dashboard) can start after Phase 3.4 (Live Location)
Phase 9 (Polish) runs parallel to Phases 7-8
Phase 10 (Deploy) after all others complete
```

---

## 10. Timeline

| Phase | Duration | Cumulative |
|-------|----------|------------|
| Phase 1: Foundation | 3-4 days | Week 1 |
| Phase 2: Auth & Users | 4-5 days | Week 2 |
| Phase 3: Core Safety | 7-8 days | Week 3-4 |
| Phase 4: Ride & Maps | 6-7 days | Week 5 |
| Phase 5: Alert System | 5-6 days | Week 6 |
| Phase 6: Evidence | 4-5 days | Week 7 |
| Phase 7: AI Layer | 6-7 days | Week 8-9 |
| Phase 8: Dashboard & Notifs | 5-6 days | Week 10 |
| Phase 9: Settings & Polish | 5-6 days | Week 11 |
| Phase 10: Deployment | 3-4 days | Week 12 |

**Total: ~12 weeks (1 dev) or ~7-8 weeks (2 devs)**

---

## 11. Privacy & Legal Framework

```
RULE 1: Audio processed ON-DEVICE only
        → No audio sent to any server during normal rides
        → Only uploaded (encrypted) if emergency triggers
        → User can delete anytime

RULE 2: No camera usage
        → Removed entirely until legal framework established

RULE 3: Location data
        → Shared only with emergency contacts during active ride
        → Stored 30 days, auto-deleted
        → User can delete anytime

RULE 4: No driver recording
        → App does NOT record or monitor the driver
        → Keyword detection listens for passenger distress only

RULE 5: Compliance
        → India: DPDP Act 2023 (consent-first, purpose limitation)
        → GDPR (if expanding to EU)
        → Clear Terms of Service
```

---

## 12. Revenue Model

| Year | Strategy | Target |
|------|----------|--------|
| **Year 1** | Free app (growth) | 100K downloads, 10K MAU |
| **Year 2** | Freemium (basic free, premium Rs99/mo for AI features) + B2B SDK (Rs2/ride) | Rs15-20L MRR |
| **Year 3** | Platform (insurance partnerships, city safety contracts, SDK at scale) | Rs1Cr+ MRR |

---

## 13. Critical Files

| File | Importance |
|------|-----------|
| `lib/features/safety/domain/usecases/trigger_panic.dart` | Central orchestrator for the most critical feature |
| `lib/core/services/location_service.dart` | Foundation for ride tracking, panic, deviation, evidence |
| `lib/features/ai/domain/usecases/calculate_threat_score.dart` | Core AI — combines all signals into escalation decisions |
| `lib/core/router/app_router.dart` | All navigation + auth guards + deep linking |
| `firebase/functions/src/index.ts` | Server-side backbone (SMS, push, escalation, data retention) |

---

## 14. Verification & Testing Plan

| Test | How to Verify |
|------|--------------|
| **Auth** | Register → OTP → login → profile → add contacts |
| **Safety** | Start ride → live map → panic → SMS received → audio saved → Firestore alert |
| **Offline** | Airplane mode → panic → SMS queued → reconnect → verify sync |
| **AI** | Play "help" audio → detection → threat score increase → auto-escalation |
| **Dashboard** | Open tracking link on browser → live location updates real-time |
| **Evidence** | Emergency → encrypted audio in Storage → auto-delete after 30 days |
| **Performance** | GPS battery <5%/hr, audio memory <50MB, TFLite <500ms, cold start <2s |
