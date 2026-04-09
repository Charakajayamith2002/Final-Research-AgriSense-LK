# AgriSense LK — Setup Guide

Agricultural Intelligence Platform  
Flask Backend + Flutter Mobile/Web App

---

## Requirements

### Software to Install

| Software | Version | Download |
|---|---|---|
| Python | 3.10 or higher | https://www.python.org/downloads/ |
| Flutter | 3.0 or higher | https://flutter.dev/docs/get-started/install |
| MongoDB | 6.0 or higher | https://www.mongodb.com/try/download/community |
| Android Studio | Latest | https://developer.android.com/studio (for APK only) |
| Google Chrome | Latest | Already installed on most PCs |

---

## Step 1 — Setup Python (Flask Backend)

### 1.1 Create Virtual Environment
```cmd
cd AgriSense-LK
python -m venv .venv
```

### 1.2 Activate Virtual Environment
```cmd
# Windows CMD:
.venv\Scripts\activate.bat

# Windows PowerShell:
.venv\Scripts\Activate.ps1
```

### 1.3 Install Python Packages
```cmd
pip install -r requirements.txt
```
> This will take 10-20 minutes (TensorFlow, PyTorch, OpenCV are large packages)

### 1.4 Start MongoDB
Make sure MongoDB is running on your PC.  
Default connection: `mongodb://localhost:27017`

### 1.5 Run Flask Server
```cmd
python app.py
```
You should see:
```
* Running on http://127.0.0.1:5001
```
Keep this CMD window open.

---

## Step 2 — Setup Flutter (Mobile/Web App)

### 2.1 Install Flutter
1. Download Flutter zip from https://flutter.dev
2. Extract to `C:\flutter`
3. Add `C:\flutter\bin` to PATH:
   - Search "Environment Variables" in Windows
   - System Variables → Path → Edit → New → `C:\flutter\bin`
   - Click OK and restart CMD

### 2.2 Verify Flutter
Open a new CMD and run:
```cmd
flutter doctor
```
You need at least Chrome (for web) or Android Studio (for APK).

### 2.3 Update Your PC's IP Address
Open this file:
```
agrisense_flutter\lib\config\api_config.dart
```
Find your PC's IP address:
```cmd
ipconfig
```
Look for "Wireless LAN adapter Wi-Fi → IPv4 Address"

Update the file:
```dart
// For web testing (Chrome on same PC):
static const String baseUrl = 'http://localhost:5001';

// For Android phone (same WiFi network):
static const String baseUrl = 'http://YOUR_IP_HERE:5001';
// Example: static const String baseUrl = 'http://192.168.1.5:5001';
```

### 2.4 Install Flutter Packages
```cmd
cd agrisense_flutter
flutter pub get
```

---

## Step 3 — Run the Project

### Option A: Run as Web App (Chrome)
Open 2 CMD windows:

**CMD 1 — Flask:**
```cmd
cd AgriSense-LK
.venv\Scripts\activate.bat
python app.py
```

**CMD 2 — Flutter Web:**
```cmd
cd AgriSense-LK\agrisense_flutter
flutter run -d chrome --web-browser-flag "--disable-web-security"
```

Flutter app opens at: `http://localhost:XXXXX`  
Flask web app at: `http://localhost:5001`

---

### Option B: Build Android APK

**Step 1** — Install Android Studio
Download from https://developer.android.com/studio and install with default settings.

**Step 2** — Install Android SDK Command-line Tools
1. Open Android Studio
2. Go to: `Languages & Frameworks → Android SDK → SDK Tools tab`
3. Check **"Android SDK Command-line Tools (latest)"**
4. Click Apply → OK → wait for download

**Step 3** — Tell Flutter where the Android SDK is
Open Android Studio → SDK Manager → note the "Android SDK Location" path.
Then run:
```cmd
C:\flutter\bin\flutter config --android-sdk "C:\Android\Sdk"
```
> Replace `C:\Android\Sdk` with your actual SDK Location path shown in Android Studio

**Step 4** — Accept Android licenses
```cmd
C:\flutter\bin\flutter doctor --android-licenses
```
Press **`y`** then Enter for every question until you see:
```
All SDK package licenses accepted
```

**Step 5** — Update IP for phone (same WiFi as PC):
```dart
static const String baseUrl = 'http://192.168.1.X:5001';
```

**Step 6** — Build APK:
```cmd
cd agrisense_flutter
C:\flutter\bin\flutter build apk --release
```
Wait 3-5 minutes.

**Step 7** — Find APK:
```
agrisense_flutter\build\app\outputs\flutter-apk\app-release.apk
```

**Step 8** — Install on phone:
- Transfer APK via USB or WhatsApp to your phone
- On phone: Settings → Apps → Special app access → Install unknown apps → WhatsApp → Allow
- Tap the APK file on your phone → Install → Open

> Phone and PC must be on the same WiFi network during demo

---

## Project Structure

```
AgriSense-LK/
├── app.py                  ← Flask main application
├── model_loader.py         ← ML model loader
├── db_config.py            ← MongoDB configuration
├── component_5.py          ← Business strategy model
├── model_4.py              ← Yield quality model
├── requirements.txt        ← Python dependencies
├── models/                 ← Trained ML model files
│   ├── 1/  Price-Demand model
│   ├── 2/  Market-Ranking model
│   ├── 3/  Cultivation-Targeting model
│   ├── 4/  Yield-Quality model
│   └── 5/  Profitable-Strategy model
├── templates/              ← Flask HTML templates
├── static/                 ← CSS, JS, images
│   ├── css/style.css
│   ├── js/main.js
│   └── js/translations.js  ← EN / සිංහල / தமிழ்
└── agrisense_flutter/      ← Flutter mobile app
    ├── pubspec.yaml
    ├── lib/
    │   ├── main.dart
    │   ├── config/api_config.dart   ← Change IP here
    │   ├── services/
    │   ├── screens/
    │   └── widgets/
    └── android/
```

---

## Features

| Feature | Description |
|---|---|
| Price & Demand | Predict crop prices using ML |
| Market Ranking | Find best markets for crops |
| Cultivation Targeting | AI crop recommendations |
| Yield & Quality | Image-based quality grading (Grade A/B/C) |
| Profitable Strategy | Business strategy recommendations |
| Language Support | English / සිංහල / தமிழ் |
| History | Save and export predictions |
| Profile | User account management |

---

## Common Issues

| Problem | Solution |
|---|---|
| Flask not starting | Check MongoDB is running |
| `flutter` not recognized | Add `C:\flutter\bin` to PATH, restart CMD |
| Cannot connect to server | Check Flask is running, check IP in api_config.dart |
| APK cannot connect | Phone and PC must be on same WiFi |
| pip install fails | Try `pip install -r requirements.txt --timeout 120` |
| Models not loading | Make sure `models/` folder is included in zip |
| `Android sdkmanager not found` | Install "Android SDK Command-line Tools" in Android Studio → SDK Tools tab |
| `Unable to locate Android SDK` | Run: `flutter config --android-sdk "C:\Android\Sdk"` (use your SDK path) |
| `flutter doctor --android-licenses` fails | Open Android Studio → SDK Manager → SDK Tools → install Command-line Tools first |
| APK install blocked on phone | Settings → Apps → Special app access → Install unknown apps → Allow |

---

## Demo Setup (Presentation Day)

1. Connect PC to WiFi
2. Run `ipconfig` → note WiFi IPv4 address
3. Update `api_config.dart` with that IP
4. Start Flask: `python app.py`
5. Start Flutter: `flutter run -d chrome` OR install APK on phone
6. Both PC and phone on same WiFi

---

*AgriSense LK — Final Year Research Project*  
*SLIIT — 2026*
