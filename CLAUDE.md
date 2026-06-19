# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

时光家 (TimeHouse) is a family photo album app for the Chinese mainland market. V1.0 (MVP) is complete. It consists of a Flutter mobile app and a Node.js/Express backend, using Volcano Engine TOS for cloud storage.

## Commands

### Backend (`backend/`)

```bash
npm install                     # Install dependencies
npm run dev                     # Start with nodemon (auto-reload)
npm start                       # Start production server (port 3000)
npm test                        # Run Jest tests
npm run lint                    # ESLint check
node scripts/initDb.js          # Initialize MySQL database tables
node scripts/migrate-add-family-id.js  # Run migration for family_id field
```

### Frontend (`timehouse/`)

```bash
flutter pub get                 # Install dependencies
flutter run                     # Run on connected device/emulator
flutter test                    # Run Flutter tests
flutter build apk               # Build Android APK
```

### Docker (database containers)

MySQL on port 23306, MongoDB on 27017, Redis on 6379. MySQL root password: `112358`.

## Architecture

### Backend (`backend/src/`)

Standard Express.js layered architecture:

- **`routes/`** — Route definitions, thin; delegates to controllers. Registered under `/api/v1`.
- **`controllers/`** — Request handling, parameter extraction, response formatting. Delegates business logic to services.
- **`services/`** — Business logic layer. The core of the application.
  - `authService.js` — Registration, login, password change, JWT generation (7-day expiry)
  - `photoService.js` — Photo CRUD, family photo queries. **Critical detail:** on every photo list/detail response, the service generates fresh pre-signed download URLs via `tosService` because the TOS bucket is private.
  - `familyService.js` — Family group creation, invite code management, member permissions (RBAC: owner/admin/member/guest)
  - `tosService.js` — Singleton wrapper around `@volcengine/tos-sdk`. Generates pre-signed PUT URLs (upload) and GET URLs (download).
- **`models/mysql/`** — Data access classes (not ORM models — static methods using raw SQL via `mysql2/promise`). All main data is in MySQL. MongoDB is connected but not actively used in V1.0.
- **`middleware/`** — `auth.js` (JWT Bearer token verification, attaches `req.user`), `errorHandler.js` (unified error response format), `rateLimiter.js` (express-rate-limit).
- **`config/`** — Loads `.env` via dotenv, exports centralized config object. `database.js` creates MySQL pool and MongoDB connection. `redis.js` creates ioredis client.
- **`utils/`** — `response.js` (unified `{ code, message, data }` response helpers), `codeGenerator.js` (6-char invite codes, default RBAC permissions).

All responses follow the format `{ code: 0, message: "操作成功", data: ... }`. Code 0 = success. Error codes: 9001 (missing params), 9003 (unauthorized), 9004 (forbidden), 9005 (not found), 9007 (rate limit), 9008 (server error). Auth errors: 1001-1005.

API route structure:
- `POST /api/v1/auth/register|login` (public), `PUT /auth/password`, `GET /auth/profile` (authenticated)
- `POST /api/v1/photos/upload`, `GET /`, `GET /:id`, `PUT /:id`, `DELETE /:id`, `POST /batch-delete`, `POST /tos-upload-signature`, `PUT /:id/family` (all authenticated)
- Full CRUD for `/api/v1/families` including members, invites, permissions (authenticated)

### Frontend (`timehouse/lib/src/`)

Flutter app with Provider for state management and GoRouter for navigation.

**App structure** — 3-tab bottom navigation: 共享组 (`/`) | 我的空间 (`/my-space`) | 我的 (`/profile`).

- **`screens/`** — Page widgets:
  - `families_screen.dart` — Tab 1: horizontal ChoiceChip family selector, photo grid via FutureBuilder + PhotoProvider cache, UploadFAB
  - `my_space_screen.dart` — Tab 2: dual sub-tabs「照片」|「共享组」, long-press multi-select, batch delete/visibility change
  - `photo_detail_screen.dart` — StatefulWidget, loads photo from local cache or API fallback, family-aware delete (remove from group vs full delete), swipe navigation
  - `family_members_screen.dart` — Member list, add member (via showModalBottomSheet), permission editing
  - `login_screen.dart`, `profile_screen.dart` — V1.0 auth and account screens
- **`providers/`** — State management via `ChangeNotifier` + Provider:
  - `PhotoProvider` — photo CRUD, upload (returns photoId), getPhoto(id) with API fallback, `getFamilyPhotosCached(familyId)` / `invalidateFamilyPhotos(familyId)` for shared family photo cache
  - `FamilyProvider` — family group list and CRUD
  - `UserProvider` — auth state, token persistence
- **`services/`** — `ApiService` (Dio singleton, retry interceptor: 3 retries, exponential backoff; base URL `http://10.0.2.2:3000/api/v1` for Android emulator; auto-attaches Bearer token). `StorageService` (sqflite for offline photo cache, SharedPreferences for userId/token).
- **`models/`** — Plain Dart data classes: `User`, `Photo`, `Family`, `FamilyMember`.
- **`routes/app_router.dart`** — GoRouter with auth redirect guard. `/photo/:id` accepts optional `familyId` via `state.extra` as `Map<String, dynamic>`.
- **`widgets/`** — Shared widgets: `BottomNavBar`, `UploadFAB` (global upload button: pick images → upload → visibility picker → assign family), `PhotoGridView` (reusable grid with date grouping, selection mode).

### Photo Upload Flow

1. Frontend calls `POST /photos/tos-upload-signature` → backend returns pre-signed PUT URL
2. Frontend uploads file bytes directly to TOS via `http.put(preSignedUrl, ...)`
3. Frontend calls `POST /photos/upload` with the resulting TOS URL → backend saves metadata in MySQL

### Photo Display Flow

1. Frontend requests photo list from `GET /photos`
2. Backend queries MySQL for metadata, then calls `tosService.generateDownloadUrl()` for each photo to produce pre-signed GET URLs (private bucket requires this)
3. Frontend renders images using `CachedNetworkImage` with the signed URLs

### Database Schema (MySQL)

4 tables: `users`, `families`, `family_members`, `photos`. Photos belong to a user and optionally to a family group (`family_id` FK). `family_members` has a `role` enum (owner/admin/member/guest) and JSON `permissions` field. All tables use InnoDB with foreign key constraints.

## Critical Rules (from project history)

- **All services must be mainland-China accessible.** Never use overseas placeholder image services (e.g., via.placeholder.com). Use Volcano Engine TOS or equivalent domestic cloud storage.
- **Never hardcode mock data in the frontend.** All data operations must go through real API calls. The project was badly burned by fake data that masked real bugs.
- **TOS SDK v2 must be imported as** `const { TosClient } = require('@volcengine/tos-sdk')` — not the old default import.
- **The TOS bucket is private.** All access requires pre-signed URLs. The backend must generate fresh signed download URLs when returning photo lists.
- **URL fields must be cleaned** of backticks and whitespace before storage (see `Photo.create()` which calls `.replace(/`/g, '').trim()`).
- **Flutter base URL is `10.0.2.2:3000`** — this is the Android emulator alias for host localhost. Change for iOS simulator (`localhost:3000`) or physical device (use LAN IP).

## Flutter Environment Config (added V2.1)

Base URL and environment are injected at compile time via `--dart-define`:

```bash
# Development (Android emulator — default)
flutter run

# Development (iOS simulator)
flutter run --dart-define=API_BASE_URL=http://localhost:3000/api/v1

# Development (physical device on LAN)
flutter run --dart-define=API_BASE_URL=http://192.168.x.x:3000/api/v1

# Production build
flutter build apk --dart-define=API_BASE_URL=https://api.shiguangjia.cn/api/v1 --dart-define=APP_ENV=production
```

The values are read at `api_service.dart:49` (`kApiBaseUrl`) and `main.dart:11` (`AppConfig`).

## Deployment Artifacts (added V2.1)

- `backend/ecosystem.config.js` — PM2 cluster mode (2 instances, 512M memory limit)
- `backend/nginx/timehouse.conf` — Nginx HTTPS reverse proxy + security headers
- `backend/Dockerfile` — Node.js 20 Alpine container
- `backend/deploy.sh` — Rsync + PM2 reload deployment script
- `backend/.env.production` — Production env template (fill RDS/domain/JWT before deploy)
- `backend/.gitignore` — Excludes .env, .env.production, logs

MongoDB and Redis connections have been removed from startup (unused in V1.0/V2.0). Redis config file kept as placeholder for V3.0.

## Production Environment (migrated to Alibaba Cloud 2026-06-07, ICP filing approved 2026-06)

| Component | Detail |
|-----------|--------|
| API URL | `https://api.timehouse.top` (port 443) |
| ECS | `121.40.161.137`, Alibaba Cloud 99-plan, Ubuntu 22.04, 2C2G 3M |
| SSH | `ssh -i ~/.ssh/id_ed25519_timehouse root@121.40.161.137` |
| MySQL | Docker 8.0, 127.0.0.1:3306, root password `112358` |
| Redis | Docker 7.0, 127.0.0.1:6379 |
| App path | `/opt/timehouse` |
| Process | PM2 fork single instance, 127.0.0.1:3000 |
| Logs | `/var/log/timehouse/` |
| Backups | crontab daily 3am → `/opt/backups/mysql/`, retained 7 days |
| Nginx | `/etc/nginx/sites-available/timehouse`, 80→443 HTTPS, reverse proxy to 127.0.0.1:3000 |
| SSL cert | Let's Encrypt, `api.timehouse.top`, auto-renew via certbot (expires 2026-09-05) |
| Health | `curl https://api.timehouse.top/api/v1/health` |

### Production Frontend Build
```bash
cd timehouse && flutter build apk --dart-define=API_BASE_URL=https://api.timehouse.top/api/v1 --dart-define=APP_ENV=production
```

## Flutter Patterns (from V2.0 development)

- **Navigation:** Use `context.push()` for secondary pages, never `context.go()` — go() replaces the route stack and breaks bottom-nav selection state. Default AppBar back button calls `pop()` automatically.
- **Dialogs:** Always use `showModalBottomSheet()` and return results via `Navigator.pop(value)`. Never use `Scaffold.bottomSheet` — setting it to `null` does not close an already-open sheet.
- **Parent-child page data sync:** Use `await context.push(...)` in the parent, then refresh data after the await resolves (child popped). Clearer than callback passing.
- **Cross-widget shared cache:** Put cached data in Provider (e.g., `PhotoProvider.getFamilyPhotosCached`), not in widget local state. Call `invalidateXxx()` + `notifyListeners()` from any widget that modifies the data. Use `context.watch<T>()` in consuming widgets to auto-rebuild.
- **Photo detail page:** Must work standalone (API fallback) — cannot assume `photoProvider.photos` is pre-populated. Use `PhotoProvider.getPhoto(id)` which tries `data['photo'] ?? data` to handle inconsistent API response formats.
- **FutureBuilder:** The future must be stable across rebuilds. Use a Provider method with internal cache — cached data returns synchronously, so FutureBuilder sees a completed Future and does not re-execute.

## Backend Cross-User Photo Access

`Photo.findById` filters by `user_id`, which blocks viewing photos uploaded by other family members. `getPhotoDetail` now has a two-step fallback:
1. Try `Photo.findById(photoId, userId)` — owner access
2. If not found, try `Photo.findByIdOnly(photoId)` — then verify `FamilyMember.isMember(familyId, userId)`

This allows family members to view each other's photos in shared groups while keeping the owner-only restriction for delete/update operations.
