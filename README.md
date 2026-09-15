# Hotel Booking Web App

A modern Hotel Booking frontend web application built with **Flutter Web** and hosted on **Firebase Hosting**.

> **Note:** This is a client-side Flutter application with no backend. Firebase is used solely for static web hosting.

---

## 🌐 Live Demo

- **Live URL:** [https://machine-test-a84bc.web.app](https://machine-test-a84bc.web.app)

---

## 🛠️ Tech Stack & SDK Requirements

- **Flutter SDK:** `3.41.9` (Channel stable)
- **Dart SDK:** `3.11.5` (compatible with `sdk: ^3.9.0`)
- **State Management:** [flutter_bloc](https://pub.dev/packages/flutter_bloc) / Cubit
- **Routing:** [go_router](https://pub.dev/packages/go_router)
- **Hosting:** [Firebase Hosting](https://firebase.google.com/docs/hosting) (Static Hosting)

---

## 📁 Project Structure

```
lib/
├── config/             # App configuration, theme, constants
├── cubits/             # State management using BLoC / Cubit
├── models/             # Data models
├── routes/             # App routing and navigation (GoRouter)
├── screens/            # UI Screens / Pages
├── widgets/            # Reusable UI widgets
├── firebase_options.dart # Firebase configuration
└── main.dart           # App entry point
```

---

## 🚀 Getting Started & Local Setup

### Prerequisites

Make sure you have the following installed on your machine:
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`>= 3.9.0`)
- Google Chrome (or any modern web browser)

### 1. Clone the Repository

```bash
git clone https://github.com/bijithpn/hotel_booking.git
cd hotel_booking
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Run Locally in Browser

```bash
flutter run -d chrome
```

### 4. Build for Production

```bash
flutter build web
```
