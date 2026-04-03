# Tactile POS

Cloud-connected Flutter POS for cafes and small restaurant counters.  
The app is optimized for tablet use, supports manager/barista roles, and runs on Android, iOS, desktop, and web targets supported by Flutter.

## Current Reality (Important)

This codebase is now **Supabase-first** for day-to-day operations:

- Staff login and role checks
- Product/category catalog
- Orders and analytics
- Shift tracking
- Cafe settings

There is still a local `sqflite` helper in `lib/services/database_helper.dart`, but the active UI flow uses `SupabaseHelper` for business data.

## Feature Set

- PIN login (`4-digit`) scoped by a linked `cafe_id`
- Device linking flow (tablet activation by cafe ID)
- Role-aware navigation:
    - Manager: Register + Orders + Config tabs
    - Barista: Register + Orders (no Config tab)
- Shift lifecycle:
    - Barista without active shift is sent to Start Shift screen
    - Shift close calculates current-user sales and logs out
- Register workflow:
    - Product grid with category filters and search
    - Cart with quantity controls, tax calculation, checkout confirmation
    - Mobile bottom-sheet cart experience
- Orders screen:
    - Date ranges, paginated history, search
    - Manager analytics dashboard (`fl_chart`)
    - Order voiding (manager-only UI action)
    - Realtime refresh via Supabase channels
- Config screen:
    - Categories CRUD
    - Products CRUD (+ image upload to Supabase Storage bucket `product-images`)
    - Staff add/list
    - Settings (tax rate, business name, reporting email, language, unlink device)
- Shift report email:
    - Supabase Edge Function `send-shift-report`
    - Email dispatched via Brevo API

## Tech Stack

- Flutter / Dart (`sdk: ^3.11.3`)
- State management: `provider` + `ChangeNotifier`
- Backend: `supabase_flutter`
- Local persistence for device prefs: `shared_preferences`
- Charts: `fl_chart`
- Media: `image_picker`, `file_picker`, `share_plus`
- Internationalization: `flutter_localizations`, custom language map (EN/FR/AR)

## App Flow

1. `SplashScreen` initializes Supabase and auth bootstrap.
2. Device checks `linked_cafe_id` in shared preferences.
3. If no linked cafe ID: show "Activate Tablet" flow.
4. PIN login verifies staff in Supabase (`staff` table).
5. Navigation:
    - Manager -> main layout
    - Barista with active shift -> main layout
    - Barista without active shift -> Start Shift screen

## Supabase Requirements

The app expects these resources (names used directly in code):

- Tables:
    - `staff`
    - `products`
    - `categories`
    - `orders`
    - `shifts`
    - `cafe_settings`
- Storage bucket:
    - `product-images`
- RPC function:
    - `get_dashboard_analytics(p_cafe_id, p_start_date, p_end_date, p_cashier_name)`
- Edge function:
    - `send-shift-report`

The edge function source is in:

- `supabase/functions/send-shift-report/index.ts`

## Local Setup

### 1. Install dependencies

```bash
flutter pub get
```

### 2. Run the app

```bash
flutter run
```

### 3. Build examples

```bash
flutter build apk
flutter build web
```

## Project Structure (Current)

```text
lib/
  main.dart
  models/
    app_models.dart
  providers/
    auth_provider.dart
    language_provider.dart
  screens/
    splash_screen.dart
    login_screen.dart
    start_shift_screen.dart
    pos/
      center_area.dart
      active_order_sidebar.dart
    orders/
      orders_screen.dart
      analytics_dashboard.dart
      order_list_tile.dart
      summary_cards.dart
    config/
      config_screen.dart
      category_tab.dart
      product_tab.dart
      staff_tab.dart
      settings_tab.dart
  services/
    supabase_helper.dart
    database_helper.dart
  theme/
    app_theme.dart

supabase/
  config.toml
  functions/
    send-shift-report/
      index.ts
```

## Testing Status

- The repo currently contains a minimal widget test in `test/widget_test.dart`.
- Coverage is limited for business-critical flows (auth, shifts, checkout, analytics, settings sync).

## Known Gaps / Operational Notes

- Supabase URL and anon key are currently initialized in app code (`SplashScreen`) instead of environment-based config.
- `AuthProvider` contains verbose telemetry print logs intended for debugging.
- Legacy SQLite helper exists and may diverge from cloud schema if reused without alignment.

## Recommended Next Improvements

1. Move Supabase config to secure runtime/env configuration.
2. Add integration tests around login, checkout, shift close, and order voiding.
3. Document and version-control SQL schema + RPC definitions under `supabase/migrations`.
4. Add explicit role-based backend policies (RLS) documentation to this README.
