# Fitness Care Bagerhat — Flutter Mobile App Prompt

> **How to use:** Paste the entire contents of this file into a new Claude session and say "Step 1".

---

## 🎭 Role

You are a **senior Flutter engineer + UI/UX designer** building a world-class mobile app
for the Fitness Care Bagerhat gym management system. Your code must be clean, testable,
and type-safe — but your UI must feel **premium, joyful, and effortless**.

Every screen must feel like it belongs on a design award showcase.
Members should open the app and *want* to use it every day.

---

## 🎯 Project Overview

Single-gym management app in Bagerhat, Bangladesh.

| Role   | Experience goal                                          |
|--------|----------------------------------------------------------|
| Admin  | Power + control — manage members, money, messages fast   |
| Member | Motivation + clarity — see progress, feel accomplished   |

Currency: **BDT (৳)**  | Timezone: **Asia/Dhaka** | Language: **English + Bengali**

---

## 🎨 Design System (non-negotiable)

### Color Palette

```dart
// lib/app/theme/app_colors.dart

// Brand
static const primary      = Color(0xFF1B5E20);   // deep forest green
static const primaryLight = Color(0xFF4CAF50);   // vibrant green
static const accent       = Color(0xFFFF6D00);   // energetic orange
static const accentLight  = Color(0xFFFF9E40);   // warm orange

// Backgrounds
static const bgLight      = Color(0xFFF5F7F0);   // off-white with green tint
static const bgDark       = Color(0xFF0D1B0F);   // deep dark green-black
static const surfaceLight = Color(0xFFFFFFFF);
static const surfaceDark  = Color(0xFF1A2B1C);

// Status
static const success      = Color(0xFF00C853);
static const warning      = Color(0xFFFFAB00);
static const error        = Color(0xFFD50000);
static const info         = Color(0xFF0091EA);

// Text hierarchy
static const textPrimary   = Color(0xFF1A1A1A);
static const textSecondary = Color(0xFF6B7280);
static const textHint      = Color(0xFF9CA3AF);
static const textOnDark    = Color(0xFFF9FAFB);

// Gradients (use on hero cards)
static const gradientGreen = LinearGradient(
  colors: [Color(0xFF1B5E20), Color(0xFF388E3C)],
  begin: Alignment.topLeft, end: Alignment.bottomRight,
);
static const gradientOrange = LinearGradient(
  colors: [Color(0xFFFF6D00), Color(0xFFFF9E40)],
  begin: Alignment.topLeft, end: Alignment.bottomRight,
);
static const gradientDark = LinearGradient(
  colors: [Color(0xFF0D1B0F), Color(0xFF1A2B1C)],
  begin: Alignment.topCenter, end: Alignment.bottomCenter,
);
```

### Typography

```dart
// lib/app/theme/app_text.dart
// Font: Google Fonts — "Plus Jakarta Sans" (primary) + "Inter" (mono/numbers)

static const displayLarge  = TextStyle(fontSize: 57, fontWeight: FontWeight.w700, height: 1.12);
static const displayMedium = TextStyle(fontSize: 45, fontWeight: FontWeight.w700, height: 1.16);
static const headlineLarge = TextStyle(fontSize: 32, fontWeight: FontWeight.w700, height: 1.25);
static const headlineMed   = TextStyle(fontSize: 28, fontWeight: FontWeight.w600, height: 1.28);
static const titleLarge    = TextStyle(fontSize: 22, fontWeight: FontWeight.w600, height: 1.27);
static const titleMedium   = TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.50, letterSpacing: 0.15);
static const bodyLarge     = TextStyle(fontSize: 16, fontWeight: FontWeight.w400, height: 1.50);
static const bodyMedium    = TextStyle(fontSize: 14, fontWeight: FontWeight.w400, height: 1.43);
static const labelLarge    = TextStyle(fontSize: 14, fontWeight: FontWeight.w600, height: 1.43, letterSpacing: 0.1);
static const labelSmall    = TextStyle(fontSize: 11, fontWeight: FontWeight.w500, height: 1.45, letterSpacing: 0.5);
static const mono          = TextStyle(fontSize: 24, fontWeight: FontWeight.w700, fontFamily: 'Inter');
```

### Spacing & Layout

```dart
// 8-point grid system
static const s4  =  4.0;
static const s8  =  8.0;
static const s12 = 12.0;
static const s16 = 16.0;
static const s20 = 20.0;
static const s24 = 24.0;
static const s32 = 32.0;
static const s40 = 40.0;
static const s48 = 48.0;
static const s64 = 64.0;

// Border radius
static const r8  = BorderRadius.all(Radius.circular(8));
static const r12 = BorderRadius.all(Radius.circular(12));
static const r16 = BorderRadius.all(Radius.circular(16));
static const r20 = BorderRadius.all(Radius.circular(20));
static const r24 = BorderRadius.all(Radius.circular(24));
static const rFull = BorderRadius.all(Radius.circular(100));
```

### Elevation & Shadow

```dart
// lib/app/theme/app_shadows.dart
static const cardShadow = [
  BoxShadow(color: Color(0x0D000000), blurRadius: 8,  offset: Offset(0, 2)),
  BoxShadow(color: Color(0x0A000000), blurRadius: 24, offset: Offset(0, 8)),
];
static const floatShadow = [
  BoxShadow(color: Color(0x1A1B5E20), blurRadius: 16, offset: Offset(0, 4)),
  BoxShadow(color: Color(0x0D000000), blurRadius: 40, offset: Offset(0, 12)),
];
static const buttonShadow = [
  BoxShadow(color: Color(0x3D1B5E20), blurRadius: 12, offset: Offset(0, 4)),
];
```

### Animation Durations

```dart
// lib/app/theme/app_animations.dart
static const dFast    = Duration(milliseconds: 150);
static const dNormal  = Duration(milliseconds: 280);
static const dSlow    = Duration(milliseconds: 420);
static const dPage    = Duration(milliseconds: 350);

static const curveEnter  = Curves.easeOutCubic;
static const curveExit   = Curves.easeInCubic;
static const curveSpring = Curves.elasticOut;
static const curveBounce = Curves.bounceOut;
```

---

## 🧱 Tech Stack

| Layer            | Package                        | Version  |
|------------------|--------------------------------|----------|
| State            | riverpod + riverpod_annotation  | ^2.5     |
| Navigation       | go_router                      | ^14      |
| HTTP             | dio                            | ^5       |
| Models           | freezed + json_serializable     | ^2       |
| Secure storage   | flutter_secure_storage          | ^9       |
| Local prefs      | shared_preferences              | ^2       |
| Charts           | fl_chart                       | ^0.68    |
| Shimmer          | shimmer                        | ^3       |
| Lottie           | lottie                         | ^3       |
| Pull-to-refresh  | custom_refresh_indicator        | ^4       |
| Haptics          | (built-in HapticFeedback)      | SDK      |
| Fonts            | google_fonts                   | ^6       |
| Icons            | phosphor_flutter                | ^2       |
| FCM              | firebase_messaging              | ^15      |
| Cached image     | cached_network_image            | ^3       |
| Intl             | intl                           | ^0.19    |
| Env              | flutter_dotenv                 | ^5       |
| Debounce         | rxdart                         | ^0.28    |
| Build runner     | build_runner                   | ^2       |
| Lint             | very_good_analysis             | ^6       |
| Test             | flutter_test + mocktail         | SDK / ^0.3 |

---

## 📁 Project Structure

```
lib/
├── main.dart
├── bootstrap.dart                     # Firebase, env, error boundary
├── app/
│   ├── app.dart                       # MaterialApp.router with theme
│   ├── router/
│   │   ├── router.dart                # GoRouter + shell routes
│   │   ├── routes.dart                # Named route constants
│   │   └── guards.dart                # AuthGuard + RoleGuard
│   └── theme/
│       ├── app_theme.dart             # ThemeData light + dark
│       ├── app_colors.dart
│       ├── app_text.dart
│       ├── app_shadows.dart
│       └── app_animations.dart
├── core/
│   ├── api/
│   │   ├── api_client.dart            # Dio instance + base options
│   │   ├── interceptors/
│   │   │   ├── token_interceptor.dart # Inject Bearer + silent refresh
│   │   │   └── logging_interceptor.dart
│   │   ├── api_response.dart          # Generic API envelope parser
│   │   └── api_exception.dart        # Sealed exception hierarchy
│   ├── auth/
│   │   ├── auth_repository.dart
│   │   ├── auth_provider.dart         # Riverpod: AuthState
│   │   └── token_storage.dart
│   ├── extensions/
│   │   ├── datetime_ext.dart          # .toDisplay(), .toApiDate()
│   │   ├── num_ext.dart               # .toBDT(), .toKg()
│   │   └── string_ext.dart            # .capitalize(), .initials()
│   └── widgets/
│       ├── gym_button.dart            # Primary, secondary, text, icon variants
│       ├── gym_card.dart              # Rounded card with shadow
│       ├── gym_text_field.dart        # Themed input with validation
│       ├── gym_avatar.dart            # Initials avatar with color ring
│       ├── gym_badge.dart             # Status chip (active/inactive/expiring)
│       ├── gym_empty_state.dart       # Lottie illustration + message
│       ├── gym_error_state.dart       # Error with retry button
│       ├── gym_shimmer.dart           # Skeleton loader variants
│       ├── gym_bottom_sheet.dart      # Draggable bottom sheet wrapper
│       └── gym_snackbar.dart          # Success / error / info toasts
├── features/
│   ├── auth/
│   │   ├── login/
│   │   │   ├── login_screen.dart
│   │   │   ├── login_controller.dart
│   │   │   └── widgets/
│   │   │       ├── role_selector.dart
│   │   │       └── login_form.dart
│   │   └── change_password/
│   ├── admin/
│   │   ├── shell/
│   │   │   ├── admin_shell.dart       # Bottom nav shell
│   │   │   └── admin_nav_items.dart
│   │   ├── dashboard/
│   │   ├── members/
│   │   │   ├── list/
│   │   │   ├── detail/
│   │   │   ├── create/
│   │   │   └── edit/
│   │   ├── plans/
│   │   ├── subscriptions/
│   │   ├── payments/
│   │   ├── messages/
│   │   │   ├── conversations/
│   │   │   ├── chat/
│   │   │   └── broadcast/
│   │   └── settings/
│   └── member/
│       ├── shell/
│       │   ├── member_shell.dart
│       │   └── member_nav_items.dart
│       ├── home/
│       ├── profile/
│       ├── subscription/
│       ├── payments/
│       ├── logs/
│       │   ├── weight/
│       │   ├── workout/
│       │   └── diet/
│       └── messages/
├── gen/
│   └── assets.gen.dart                # FlutterGen output
└── l10n/
    ├── arb/app_en.arb
    └── arb/app_bn.arb

assets/
├── animations/                        # Lottie JSON files
│   ├── success.json
│   ├── empty_members.json
│   ├── empty_messages.json
│   └── gym_loading.json
├── images/
│   ├── logo.png
│   └── splash_bg.png
└── fonts/
    └── PlusJakartaSans/
```

---

## ✨ Component Specifications

### GymButton

```dart
/// Primary action button with gradient background and subtle shadow.
/// Supports loading state (spinner replaces label) and haptic feedback.
///
/// Usage:
/// ```dart
/// GymButton(
///   label: 'Create Member',
///   icon: PhosphorIcons.userPlus(),
///   onPressed: controller.submit,
///   isLoading: state.isLoading,
/// )
/// ```
class GymButton extends StatelessWidget { ... }

// Variants:
// GymButton.primary   → green gradient + white text
// GymButton.secondary → outlined green border + green text
// GymButton.danger    → red gradient
// GymButton.text      → no background, green text
// GymButton.icon      → circular icon button
```

### GymCard

```dart
/// Base card with consistent shadow, border radius, and padding.
/// All content cards in the app extend or use this.
///
/// Example:
/// ```dart
/// GymCard(
///   child: SubscriptionInfo(subscription: sub),
///   onTap: () => router.push(Routes.subscription),
/// )
/// ```
class GymCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final Color? color;
  final Gradient? gradient;
  // ...
}
```

### StatCard

```dart
/// Displays a metric with icon, animated number, and optional trend.
///
/// Used on Admin Dashboard for revenue, members, active plans, etc.
///
/// ```dart
/// StatCard(
///   icon: PhosphorIcons.users(),
///   label: 'Active Members',
///   value: '47',
///   trend: TrendDirection.up,
///   trendLabel: '+3 this week',
///   color: AppColors.primaryLight,
/// )
/// ```
class StatCard extends StatelessWidget { ... }
```

### MemberListTile

```dart
/// Rich list tile for a gym member.
/// Shows avatar, name, phone, status badge, subscription expiry warning.
///
/// ```dart
/// MemberListTile(
///   member: member,
///   onTap: () => router.push(Routes.memberDetail(member.id)),
///   trailing: ExpiryBadge(daysLeft: 3),
/// )
/// ```
class MemberListTile extends StatelessWidget { ... }
```

### WeightChart

```dart
/// Line chart showing weight trend over time using fl_chart.
/// Animated draw-in on first load. Tap a point to see exact value.
///
/// ```dart
/// WeightChart(
///   logs: weightLogs,
///   dateRange: DateRange(from: from, to: to),
///   targetWeight: member.currentWeight,
/// )
/// ```
class WeightChart extends StatelessWidget { ... }
```

### ChatBubble

```dart
/// Message bubble with tail, timestamp, and read receipt.
/// Admin messages align left (green bubble), member aligns right (white bubble).
///
/// ```dart
/// ChatBubble(
///   message: message,
///   isMe: message.senderRole == 'member',
/// )
/// ```
class ChatBubble extends StatelessWidget { ... }
```

---

## 📱 Screen-by-Screen UI Specifications

### Login Screen

```
┌─────────────────────────────────────┐
│  [Logo + "Fitness Care" wordmark]   │  ← Hero animation on load
│                                     │
│  "Welcome back 👋"                  │  ← Display font, bold
│  "Sign in to continue"              │  ← Body, muted
│                                     │
│  ┌─────────────────────────────┐    │
│  │  Admin    │    Member       │    │  ← Segmented role picker
│  └─────────────────────────────┘    │    (slide animation between)
│                                     │
│  [Email / Phone field]              │  ← Switches label based on role
│  [Password field + show/hide]       │
│                                     │
│  [Sign In ──────────────────────]   │  ← Full-width gradient button
│                                     │
│  v1.0.0                            │  ← Version at bottom
└─────────────────────────────────────┘
```

- **Background:** subtle gym image with dark overlay (30% opacity)
- **Card:** frosted glass effect (BackdropFilter blur 20)
- **Entry animation:** card slides up + fades in (300 ms, easeOut)
- **Error animation:** text fields shake horizontally (100 ms)
- **Success animation:** Lottie check → navigate

---

### Admin Dashboard

```
┌─────────────────────────────────────┐
│  Good morning, Owner 👋   [🔔] [👤] │  ← Greeting + notification badge
├─────────────────────────────────────┤
│                                     │
│  ┌──────────┐  ┌──────────┐         │
│  │ ৳ 45,000 │  │  47      │         │  ← StatCard (animated count-up)
│  │ Revenue  │  │ Members  │         │
│  └──────────┘  └──────────┘         │
│  ┌──────────┐  ┌──────────┐         │
│  │  12      │  │  3       │         │
│  │ Plans    │  │ Expiring │         │  ← Expiring card: orange accent
│  └──────────┘  └──────────┘         │
│                                     │
│  "Members Expiring Soon"            │
│  ┌─────────────────────────────┐    │
│  │  [Avatar] Karim Ahmed   3d  │    │  ← Swipeable cards
│  │  [Avatar] Rahim Uddin   7d  │    │
│  └─────────────────────────────┘    │
│                                     │
│  "Recent Payments"                  │
│  [Payment tile list...]             │
└─────────────────────────────────────┘

Bottom Nav: Members | Plans | Payments | Messages | Settings
```

- **Scroll behavior:** SliverAppBar collapses greeting on scroll
- **Stat cards:** staggered entrance animation (50 ms offset each)
- **Count-up:** numbers animate from 0 to actual value (600 ms)
- **Expiring cards:** horizontal scroll, orange left border accent

---

### Member Detail (Admin view)

```
┌─────────────────────────────────────┐
│  ← Back          [Edit] [⋯]        │
├─────────────────────────────────────┤
│                                     │
│        [Large Avatar — initials]    │  ← Colored by name hash
│          Karim Ahmed                │
│          01711-000001               │
│     ● Active  ·  Joined 12 May 2025 │
│                                     │
│  ┌────────────────────────────────┐ │
│  │  📋 Monthly Basic             │ │  ← Active subscription card
│  │  Started 01 May · Ends 31 May  │ │     (gradient green)
│  │  ████████░░░░░░░  21 days left │ │  ← Progress bar
│  │  ৳ 1,500 paid                  │ │
│  └────────────────────────────────┘ │
│                                     │
│  [Assign Plan] [Record Payment]     │  ← Action buttons
│                                     │
│  ──────────── Tabs ─────────────   │
│  [History] [Payments] [Logs]        │
│                                     │
│  [Tab content...]                   │
└─────────────────────────────────────┘
```

- **Avatar color:** deterministic from name hash (12 hue options)
- **Subscription card:** `Hero` widget (shared with subscription screen)
- **Progress bar:** animated fill on page load
- **Action buttons:** row of secondary buttons with icons

---

### Member Home (Member's view)

```
┌─────────────────────────────────────┐
│  Assalamu Alaikum, Karim 🌿        │  ← Time-aware greeting
│  Friday, 16 May 2026                │
├─────────────────────────────────────┤
│                                     │
│  ┌──────────────────────────────┐   │
│  │   Monthly Basic              │   │  ← Hero subscription card
│  │   ██████████░░░  21 days     │   │     full-width gradient
│  │   Renews 31 May 2026         │   │
│  └──────────────────────────────┘   │
│                                     │
│  "Your Progress"                    │
│  ┌──────┐ ┌──────┐ ┌──────┐        │
│  │  72  │ │  14  │ │  21  │        │  ← StatMini: weight, workouts, days
│  │  kg  │ │  wkt │ │  day │        │
│  └──────┘ └──────┘ └──────┘        │
│                                     │
│  "Quick Log"                        │
│  ┌─────────────────────────────┐   │
│  │  🏋️ Log Workout  🥗 Log Diet│   │  ← Quick action chips
│  └─────────────────────────────┘   │
│                                     │
│  "Weight This Week"                 │
│  [Mini line chart — last 7 days]    │
└─────────────────────────────────────┘

Bottom Nav: Home | Logs | Messages | Profile
```

- **Greeting:** "Good morning" / "Good afternoon" / "Assalamu Alaikum" (time-based)
- **Subscription card:** countdown timer, color shifts orange when < 7 days
- **Mini chart:** sparkline with 7-day weight trend, draws in on load

---

### Weight Log Screen (Member)

```
┌─────────────────────────────────────┐
│  Weight Tracker             [+ Log] │
├─────────────────────────────────────┤
│                                     │
│   72.5 kg  ↓ 1.5 kg this month     │  ← Current + trend (green/red)
│                                     │
│  ┌──────────────────────────────┐   │
│  │                              │   │
│  │    [fl_chart line chart]     │   │  ← Animated, date axis
│  │                              │   │
│  └──────────────────────────────┘   │
│  [1W] [1M] [3M] [6M] [1Y] [All]    │  ← Range selector pills
│                                     │
│  ─── History ───────────────────   │
│  16 May  ·  72.5 kg                 │
│  14 May  ·  73.0 kg    ↑ 0.5       │
│  12 May  ·  73.2 kg    ↑ 0.2       │
│  ...                               │
└─────────────────────────────────────┘
```

**Log Weight Bottom Sheet:**
```
┌──────────────────────────────────────┐
│  ▬ (drag handle)                     │
│  Log Your Weight                     │
│                                      │
│         [ 72 . 5 ] kg                │  ← Large number picker (scroll wheel)
│                                      │
│  Date: Today, 16 May 2026  [Change]  │
│                                      │
│  [   Save Weight   ────────────]     │  ← Green gradient button
└──────────────────────────────────────┘
```

- **Chart animation:** line draws left to right on load (800 ms)
- **Range switch:** smooth data transition, no flash
- **Number wheel:** CupertinoPicker-style weight selector
- **Trend indicator:** color-coded ↑↓ with percentage

---

### Messages / Chat

```
┌─────────────────────────────────────┐
│  ← Gym Support              [📞]    │
│  Admin • usually replies in 1 hr    │
├─────────────────────────────────────┤
│                                     │
│  ── Today ─────────────────────    │
│                                     │
│  ┌──────────────────────┐           │  ← Admin message (left, green)
│  │ Welcome to the gym!  │           │
│  │ Your plan is active. │ 10:00 ✓  │
│  └──────────────────────┘           │
│                                     │
│            ┌──────────────────────┐ │  ← Member message (right, white)
│            │ Thank you! When does │ │
│            │ the gym open?       │ │
│            │               10:01 │ │
│            └──────────────────────┘ │
│                                     │
├─────────────────────────────────────┤
│  [📎]  Type a message...   [Send →] │  ← Sticky input bar
└─────────────────────────────────────┘
```

- **Send button:** morphs from icon → circle on text focus (animation)
- **Message entrance:** each new message slides up + fades in
- **Timestamps:** grouped by day separator
- **Read receipts:** single ✓ sent, double ✓✓ read (blue when read)
- **Keyboard:** scroll to bottom when keyboard opens

---

### Record Payment (Admin bottom sheet)

```
┌──────────────────────────────────────┐
│  ▬                                   │
│  Record Payment                      │
│                                      │
│  Member ──────────────────────────   │
│  [🔍 Search member...]               │  ← Search as you type
│                                      │
│  Amount (৳) ──────────────────────   │
│  [    1,500.00    ]                  │  ← Numpad input, large text
│                                      │
│  Payment Method ──────────────────   │
│  ┌──────┐ ┌──────┐ ┌──────┐ ┌────┐  │
│  │ Cash │ │bKash │ │Nagad │ │Card│  │  ← Selection chips with logos
│  └──────┘ └──────┘ └──────┘ └────┘  │
│                                      │
│  Date ────────────────────────────   │
│  Today, 16 May 2026        [Change]  │
│                                      │
│  [   Record Payment ─────────────]  │
└──────────────────────────────────────┘
```

---

## 🏗️ Architecture

```
View (StatelessWidget, ConsumerWidget)
  │  ref.watch(xxxProvider)
  ▼
Controller (AsyncNotifier / Notifier)
  │  await repository.method()
  ▼
Repository (abstract interface)
  │  implemented by DioXxxRepository
  ▼
ApiClient (Dio + interceptors)
  │  throws ApiException subclasses
  ▼
Backend REST API
```

### State Shape (per feature)

```dart
@freezed
class MembersState with _$MembersState {
  const factory MembersState({
    @Default([])     List<Member> members,
    @Default(false)  bool isLoading,
    @Default(false)  bool isLoadingMore,
    @Default(1)      int  page,
    @Default(false)  bool hasMore,
                     ApiException? error,
                     String?       searchQuery,
                     String?       statusFilter,
  }) = _MembersState;
}
```

### Error Handling

```dart
/// Sealed hierarchy — handlers switch exhaustively.
sealed class ApiException implements Exception {
  final String message;
  final String? code;
  const ApiException(this.message, {this.code});
}

final class UnauthorizedException  extends ApiException { ... }
final class ForbiddenException     extends ApiException { ... }
final class NotFoundException      extends ApiException { ... }
final class ConflictException      extends ApiException { ... }
final class ValidationException    extends ApiException {
  final Map<String, String> fields;
  const ValidationException(super.message, {required this.fields, super.code});
}
final class RateLimitException     extends ApiException { ... }
final class ServerException        extends ApiException { ... }
final class NetworkException       extends ApiException { ... }
```

---

## 🔐 Auth & Token Flow

```
App start
  │
  ├─ tokens exist? ──yes──► validate access token
  │                          ├─ valid ──► navigate to role home
  │                          └─ expired ──► refresh ──► navigate to role home
  │                                         └─ refresh failed ──► login
  └─ no tokens ──────────────────────────────────────────────────► login

Login success:
  ├─ store access + refresh token (flutter_secure_storage)
  ├─ store user_id + role
  ├─ must_change_password? ──yes──► ChangePasswordScreen (cannot skip)
  └─ navigate to role home

Silent refresh (TokenInterceptor):
  ├─ 401 received ──► POST /api/v1/auth/refresh
  │   ├─ success ──► store new pair ──► retry original request
  │   └─ failure ──► clear storage ──► push /login (replace stack)
  └─ other errors ──► throw ApiException

Logout:
  ├─ clear flutter_secure_storage
  ├─ cancel FCM token (DELETE not implemented; token simply expires)
  └─ router.go('/login')
```

---

## 🔔 FCM Push Notifications

```dart
// bootstrap.dart — run on every cold start after auth
Future<void> setupFCM(WidgetRef ref) async {
  final messaging = FirebaseMessaging.instance;

  // 1. Request permission (iOS) / notify-enabled check (Android 13+)
  await messaging.requestPermission();

  // 2. Get token and register with backend
  final token = await messaging.getToken();
  if (token != null) {
    await ref.read(fcmRepositoryProvider).register(
      token: token,
      deviceInfo: '${Platform.operatingSystem} ${Platform.operatingSystemVersion}',
    );
  }

  // 3. Handle token refresh
  messaging.onTokenRefresh.listen((newToken) async {
    await ref.read(fcmRepositoryProvider).register(token: newToken);
  });

  // 4. Foreground messages → show in-app banner (GymSnackbar)
  FirebaseMessaging.onMessage.listen((msg) {
    showInAppNotification(msg);
  });

  // 5. Background/terminated tap → navigate
  FirebaseMessaging.onMessageOpenedApp.listen((msg) {
    handleNotificationNavigation(msg.data['type']);
  });
}

void handleNotificationNavigation(String? type) {
  switch (type) {
    case 'renewal'         => router.go(Routes.memberSubscription);
    case 'weight_reminder' => router.go(Routes.memberWeightLog);
    case 'message'         => router.go(Routes.memberMessages);
  }
}
```

---

## 📖 Documentation Standards

Every public class, method, and provider must have a Dart doc comment:

```dart
/// Repository for managing gym member data.
///
/// Communicates with the backend via [ApiClient].
/// Throws [ApiException] subclasses on error — never raw [DioException].
///
/// See also:
/// - [MembersController] which consumes this repository
/// - [Member] for the domain model
abstract class MemberRepository {
  /// Creates a new gym member with a server-generated temp password.
  ///
  /// Returns a [CreateMemberResult] containing the new [Member] and
  /// the one-time [tempPassword] that must be shown to the admin.
  ///
  /// Throws:
  /// - [ConflictException] if [phone] is already registered
  /// - [ValidationException] if required fields fail server validation
  /// - [ServerException] on unexpected server error
  Future<CreateMemberResult> createMember(CreateMemberRequest request);
}
```

Each **screen file** must start with:
```dart
/// ## MembersListScreen
///
/// Admin view showing a searchable, filterable, paginated list of all gym members.
///
/// ### Features
/// - Real-time search with 300 ms debounce
/// - Filter by status (active / inactive / expiring soon)
/// - Pull-to-refresh
/// - Infinite scroll pagination (20 per page)
///
/// ### Navigation
/// - Tap member → [MemberDetailScreen]
/// - FAB → [CreateMemberScreen]
///
/// ### State
/// Managed by [MembersController] via [membersControllerProvider].
```

---

## 📐 UX Rules (non-negotiable)

| Rule | Implementation |
|---|---|
| **Never show raw errors** | Map every `ApiException` to a friendly message |
| **Never block with spinner > 300 ms** | Show skeleton immediately; spinner only for actions |
| **Skeleton on every list** | `GymShimmer` with exact shape of the real item |
| **Empty states with purpose** | Lottie illustration + context-aware message + action button |
| **Optimistic UI** | Status toggle, read receipts, likes — update UI before server confirms |
| **Pull-to-refresh everywhere** | `RefreshIndicator` on every scrollable |
| **Haptic on every action** | `HapticFeedback.lightImpact()` on tap, `mediumImpact()` on success |
| **No orphaned modals** | Pop all sheets on back navigation |
| **Keyboard avoidance** | `resizeToAvoidBottomInset: true` on all form screens |
| **Safe area** | All screens respect `SafeArea` top and bottom |
| **Debounce search** | 300 ms `rxdart` debounce on every search field |
| **Paginate, never load all** | Max 20 items per page; `InfiniteScroll` pattern |
| **Currency formatting** | Always `৳ 1,500` (space between symbol and amount) |
| **Date formatting** | Display: `16 May 2026` · API: `2026-05-16` |

---

## 🌙 Dark Mode

All screens support system dark mode automatically via `ThemeData.dark()`.

Key overrides:
- Background: `AppColors.bgDark` (`#0D1B0F`)
- Surface: `AppColors.surfaceDark` (`#1A2B1C`)
- Cards: slightly lighter surface with reduced shadow opacity
- Charts: dark grid lines, bright data lines

---

## 🌐 Localization

Support English (default) and Bengali using Flutter's built-in `l10n`:

```arb
// app_en.arb
{
  "@@locale": "en",
  "welcomeBack": "Welcome back 👋",
  "signIn": "Sign In",
  "memberCount": "{count, plural, =0{No members} =1{1 member} other{{count} members}}",
  "@memberCount": { "placeholders": { "count": { "type": "int" } } }
}

// app_bn.arb
{
  "@@locale": "bn",
  "welcomeBack": "আবার স্বাগতম 👋",
  "signIn": "সাইন ইন",
  "memberCount": "{count} জন সদস্য"
}
```

Language selector in Settings → stored in `shared_preferences`.

---

## 🧪 Testing Requirements

```dart
// Every controller (notifier) must have a unit test:
void main() {
  group('MembersController', () {
    late MockMemberRepository mockRepo;
    late ProviderContainer container;

    setUp(() {
      mockRepo = MockMemberRepository();
      container = ProviderContainer(
        overrides: [memberRepositoryProvider.overrideWithValue(mockRepo)],
      );
    });

    tearDown(() => container.dispose());

    test('loads members on init', () async {
      when(() => mockRepo.list(any())).thenAnswer((_) async =>
          MemberListResult(members: fakeMembers, total: 2));

      final notifier = container.read(membersControllerProvider.notifier);
      await notifier.load();

      expect(
        container.read(membersControllerProvider).members,
        hasLength(2),
      );
    });

    test('shows error on network failure', () async {
      when(() => mockRepo.list(any())).thenThrow(NetworkException('offline'));

      final notifier = container.read(membersControllerProvider.notifier);
      await notifier.load();

      expect(
        container.read(membersControllerProvider).error,
        isA<NetworkException>(),
      );
    });
  });
}
```

Minimum coverage: **60 % on all notifiers**.

---

## 📦 Deliverables (build in this order)

Stop after each step and let me review before continuing.

| Step | What to build |
|---|---|
| **1** | Project scaffold: packages, theme system, design tokens, GoRouter skeleton, auth guard, Dio client with TokenInterceptor, GymButton/GymCard/GymTextField base components |
| **2** | Auth: Login screen (animated), ChangePassword screen, AuthProvider, TokenStorage |
| **3** | Admin shell + Members: list (search + filter + skeleton), detail, create (with temp password dialog), edit, status toggle |
| **4** | Admin: Plans list + form, Subscription assign/edit sheets |
| **5** | Admin: Payments list + monthly summary card + record payment sheet |
| **6** | Admin: Conversations list + Chat screen + Broadcast composer |
| **7** | Admin: Settings screen (quiet window time pickers, nudge days, reminder days) |
| **8** | Member: Home dashboard + Profile + Active subscription + Payment history |
| **9** | Member: Weight log (fl_chart trend + log sheet + date range) + Workout log + Diet log |
| **10** | Member: Messages inbox + Send sheet + Notification settings (mute toggle + FCM registration) |
| **11** | FCM integration, app icon, splash screen, README, release Gradle/Xcode config |

---

## 🌐 Backend API Reference

Base URL (from `.env`): `API_BASE_URL=http://localhost:9000`  
Swagger UI: `http://localhost:9000/swagger/index.html`

All requests need `Authorization: Bearer <access_token>` except `/api/v1/auth/*`.

**Error envelope:**
```json
{ "success": false, "error": { "code": "CONFLICT", "message": "...", "details": {} } }
```

**Success envelope:**
```json
{ "success": true, "data": { ... } }
```

**Paginated:**
```json
{ "success": true, "data": [...], "meta": { "page": 1, "limit": 20, "total": 45 } }
```

---

*Start with Step 1.*
```

---

## How to use this prompt

```bash
# The prompt is saved at:
cat /Users/asad/go/src/fitness-care-bagerhat/FLUTTER_PROMPT.md
```

1. Open a **new Claude session**
2. Paste the entire `FLUTTER_PROMPT.md` content
3. Say **"Step 1"**

---

### What's different in this enhanced version

| Area | Previous prompt | This prompt |
|---|---|---|
| **Colors** | Generic green | Full 6-tone palette with dark-mode variants + gradients |
| **Typography** | Basic scale | Plus Jakarta Sans + Inter, 10-level scale with exact metrics |
| **Spacing** | Not specified | 8-point grid, named constants (s4…s64) |
| **Shadows** | Not specified | 3 levels (card, float, button) with green-tinted shadow |
| **Animations** | Mentioned | Durations (150/280/420 ms), specific curves per use case |
| **Components** | Names only | Full API with code, usage examples, variant list |
| **Screen specs** | Text descriptions | ASCII wireframes with exact element placement and behavior |
| **Dark mode** | "honor system" | Specific hex values, card/chart overrides |
| **Docs** | Mentioned | Full Dart doc template with `/// ## Screen`, `Throws:`, `See also:` |
| **Localization** | Mentioned | ARB examples with plurals + Bengali |
| **UX rules** | Mentioned | Table: 12 rules, each with concrete implementation |
| **FCM** | Brief | Full lifecycle: permission → register → refresh → tap navigation |
| **Charts** | fl_chart | Animated draw-in, date range pills, sparkline variant |
| **Chat** | Basic | Bubble specs, timestamps, read receipts, keyboard handling |