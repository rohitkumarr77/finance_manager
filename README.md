# 💰 Finance Manager

A cross-platform personal finance app built with **Flutter** and **Firebase**. Track income and expenses, set budgets, automate recurring transactions, chase savings goals, and see where your money actually goes — all in one place.

<!-- Add screenshots or a demo GIF here -->
<!-- ![Dashboard Screenshot](docs/screenshots/dashboard.png) -->

## ✨ Features

### Core
- 🔐 **Authentication** — email/password sign up, login, and password reset via Firebase Auth
- 📊 **Dashboard** — at-a-glance income, expense, and balance with recent activity
- 💵 **Transactions** — add, view, filter, and delete income/expense entries
- 🧮 **Unit Converter** — bonus utility for length, weight, currency, temperature, and more

### Money Management
- 💰 **Budget Management** — set monthly budgets per category, track spend vs. limit with progress bars, and get alerted when you go over
- 🔔 **Recurring Transactions** — automate subscriptions, salary, and bills on a weekly or monthly schedule, with pause/edit/delete controls
- 💳 **Payment Method Tracking** — tag transactions as Cash, Card, or UPI and see a breakdown of your most-used method
- 🎯 **Savings Goals** — set multiple goals with priority ranking, log contributions, and get a completion alert when you hit the target
- 📈 **Advanced Analytics** — 6-month income/expense trend line chart, monthly comparison bar chart, category pie chart, and a top-5-expenses list

### UX
- 🌗 Light/dark theme with persisted preference
- ☁️ Fully cloud-backed with Firestore — no local database, syncs across devices

## 🛠️ Tech Stack

| Layer          | Technology                                   |
|----------------|-----------------------------------------------|
| Framework      | [Flutter](https://flutter.dev)                |
| Auth           | Firebase Authentication                       |
| Database       | Cloud Firestore                               |
| Charts         | [fl_chart](https://pub.dev/packages/fl_chart) |
| Local prefs    | shared_preferences                            |
| Formatting     | intl                                          |

## 📂 Project Structure

```
lib/
├── main.dart                      # App entry point, theming, routes
├── screens/
│   ├── splash_screen.dart
│   ├── login_screen.dart
│   ├── register_screen.dart
│   ├── forgot_password_screen.dart
│   ├── dashboard_screen.dart
│   ├── add_transaction_screen.dart
│   ├── transactions_screen.dart
│   ├── report_screen.dart         # Analytics & charts
│   ├── budget_screen.dart
│   ├── recurring_screen.dart
│   ├── goals_screen.dart
│   ├── payment_analytics_screen.dart
│   └── converter_screen.dart
└── services/
    ├── auth_service.dart
    ├── budget_service.dart
    ├── recurring_service.dart
    ├── goals_service.dart
    ├── them_service.dart          # Theme persistence
    └── unit_converter.dart
```

## 🔥 Firestore Data Model

All user data lives under a per-user document:

```
users/{uid}
├── username, email, created_at
├── transactions/{id}      { type, amount, category, description, date, paymentMethod, created_at }
├── budgets/{month_category} { category, limit, month }              // month = 'yyyy-MM'
├── recurring/{id}          { type, amount, category, description, frequency, paymentMethod, nextDate, isPaused }
└── goals/{id}               { name, targetAmount, savedAmount, priority, deadline, isCompleted }
```

### Suggested Security Rules

```js
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;

      match /{collection}/{docId} {
        allow read, write: if request.auth != null
          && request.auth.uid == userId
          && collection in ['transactions', 'budgets', 'recurring', 'goals'];
      }
    }
  }
}
```

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.x recommended)
- A [Firebase](https://console.firebase.google.com/) project with **Authentication** (Email/Password) and **Cloud Firestore** enabled

### Setup

1. **Clone the repo**
   ```bash
   git clone https://github.com/<rohitkumarr77>/finance-manager.git
   cd finance-manager
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Connect Firebase**

   Install the FlutterFire CLI and run the configure command from the project root — this generates `lib/firebase_options.dart` and the platform config files automatically:
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```
   Then initialize it in `main.dart`:
   ```dart
   await Firebase.initializeApp(
     options: DefaultFirebaseOptions.currentPlatform,
   );
   ```
   (Alternatively, manually add `google-services.json` to `android/app/` and `GoogleService-Info.plist` to `ios/Runner/`.)

4. **Enable Firebase services**
    - In the Firebase Console, enable **Authentication → Email/Password**
    - Enable **Firestore Database** and apply the security rules above

5. **Run the app**
   ```bash
   flutter run
   ```

## 📦 Key Dependencies

Add these to `pubspec.yaml` if not already present:

```yaml
dependencies:
  flutter:
    sdk: flutter
  firebase_core: ^latest
  firebase_auth: ^latest
  cloud_firestore: ^latest
  fl_chart: ^latest
  intl: ^latest
  shared_preferences: ^latest
```

Run `flutter pub outdated` to check for current recommended versions.

## 🗺️ Roadmap

- [ ] Export transactions to CSV/PDF
- [ ] Multi-currency support
- [ ] Shared/family budgets
- [ ] Push notifications for bill reminders and budget alerts
- [ ] Biometric app lock

## 🤝 Contributing

Contributions are welcome!

1. Fork the repo
2. Create a feature branch (`git checkout -b feature/my-feature`)
3. Commit your changes (`git commit -m 'Add my feature'`)
4. Push to the branch (`git push origin feature/my-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

##  Acknowledgements

- [Flutter](https://flutter.dev)
- [Firebase](https://firebase.google.com)
- [fl_chart](https://pub.dev/packages/fl_chart)