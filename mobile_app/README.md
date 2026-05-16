# Fitness Care Bagerhat — Mobile App

A world-class gym management mobile application for **Fitness Care Bagerhat**, built with Flutter.

## 🚀 Key Features

### 🎭 Administrative Suite
- **Member CRM:** Complete member lifecycle management (Create, Search, Filter, Status).
- **Membership Plans:** Tiered membership management with direct subscription assignment.
- **Financial Tracking:** Monthly revenue summaries, transaction history, and support for multiple payment methods (Cash, bKash, Nagad, Card).
- **Communication Hub:** Single and bulk broadcast messaging (SMS & Push).
- **Analytics:** Real-time business dashboard with interactive charts (fl_chart).

### 🌿 Member Portal
- **Motivation Dashboard:** Personalized greetings, active subscription progress, and mini-stats.
- **Progress Tracking:** Interactive Weight Tracker with trend charts and logging history.
- **Gym Support:** Real-time chat support for members to communicate with admins.
- **Account Management:** Profile settings, theme toggles, and secure authentication.

## 🎨 Design System
- **8-Point Grid:** Consistent spacing and layout rhythm.
- **Premium Aesthetics:** HSL-tailored colors, smooth gradients, and Jakarta Sans typography.
- **Dark Mode:** Full system dark mode support with tailored surface/card colors.
- **Interactive UX:** Haptic feedback, smooth animations, and pull-to-refresh on all lists.

## 🛠️ Tech Stack
- **State Management:** Riverpod (Notifier + AsyncValue)
- **Navigation:** GoRouter with Shell Routes
- **Networking:** Dio with TokenInterceptor (Silent Refresh)
- **Models:** Freezed & JsonSerializable
- **Charts:** fl_chart

## 🏗️ Getting Started

1. **Prerequisites:**
   - Flutter SDK (Latest Stable)
   - Dart SDK
   - Android Studio / Xcode

2. **Environment Setup:**
   Create a `.env` file in the root directory:
   ```env
   API_BASE_URL=http://localhost:9000
   ```

3. **Install Dependencies:**
   ```bash
   flutter pub get
   ```

4. **Run Code Generation:**
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

5. **Run the App:**
   ```bash
   flutter run
   ```

## 🔐 Authentication
- **Admin Login:** Requires employee credentials.
- **Member Login:** Requires registered phone number and password.
- **Security:** Automatic Bearer token injection and secure local storage.

## 🌐 Localization
The app supports **English** and **Bengali**.
- L10n files: `lib/l10n/arb/`
- Command to regenerate: `flutter gen-l10n`

---
Built with ❤️ by Fitness Care Bagerhat Team.
