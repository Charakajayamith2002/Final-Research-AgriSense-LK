# AgriSense LK - Flutter Mobile App

Mobile frontend for the AgriSense LK agricultural intelligence platform.

## Setup

### 1. Install Flutter
Download from https://flutter.dev and add to PATH.

### 2. Install dependencies
```bash
flutter pub get
```

### 3. Set your Flask server IP
Edit `lib/config/api_config.dart`:
```dart
// For Android emulator:
static const String baseUrl = 'http://10.0.2.2:5000';

// For real phone (replace with your PC's IP):
static const String baseUrl = 'http://192.168.1.XXX:5000';
// Find your IP: run "ipconfig" in cmd
```

### 4. Start Flask backend
```bash
cd ..   # back to main project
python app.py
```

### 5. Run Flutter app
```bash
# Web browser
flutter run -d chrome

# Android emulator
flutter run -d android

# Build APK
flutter build apk --release
# APK at: build/app/outputs/flutter-apk/app-release.apk
```

## Project Structure
```
lib/
├── main.dart              # App entry point + splash screen
├── config/
│   └── api_config.dart    # Flask server URL config
├── services/
│   └── api_service.dart   # All HTTP calls to Flask
├── screens/
│   ├── login_screen.dart
│   ├── register_screen.dart
│   ├── home_screen.dart
│   ├── price_demand_screen.dart
│   ├── market_ranking_screen.dart
│   ├── cultivation_targeting_screen.dart
│   ├── yield_quality_screen.dart      # Image upload
│   ├── profitable_strategy_screen.dart
│   ├── history_screen.dart
│   └── profile_screen.dart
└── widgets/
    └── result_webview.dart
```
