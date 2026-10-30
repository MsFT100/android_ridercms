# Maxtekhub

An EV battery swap and charging app. (Formerly codenamed "ridercms": the package ID `com.ridercms.ridercms`, Dart package name `ridercms`, Firebase project and API URL still use the old code name on purpose.)

## Build commands

Run everything from the `android_ridercms` folder (PowerShell).

### Prerequisites

- **JDK 17 to 21.** Gradle 8.14 fails on JDK 25/26 with a bare version number as the error (for example `26.0.1`). Point Flutter at a supported JDK once:
  ```powershell
  flutter config --jdk-dir "C:\Users\lenno\.jdks\temurin-21"
  ```
  or set it for the current shell only:
  ```powershell
  $env:JAVA_HOME = "C:\Users\lenno\.jdks\temurin-21"
  ```
- **Dependencies:** `flutter pub get`
- **Clean build** (after changing `google-services.json`, signing or Gradle files): `flutter clean; flutter pub get`

### Signing

| Build | Signed with | Setup |
|---|---|---|
| Debug (`flutter run`, `--debug`) | Android debug key (`~/.android/debug.keystore`) | None. Register its SHA-1/SHA-256 and the App Check debug token in Firebase. |
| Release (`--release`) | Release key from `android/key.properties` | Copy `android/key.properties.example` to `android/key.properties` and fill in the passwords. |

If `android/key.properties` is missing, the release build falls back to the **debug** key and prints a warning. That build must not be uploaded to Google Play. Both `key.properties` and `ridercms-release.jks` are git-ignored, so keep a backup of the keystore and its passwords.

Show a build's fingerprints (register these in Firebase and the Cloud Console API key):
```powershell
& "C:\Users\lenno\.jdks\temurin-21\bin\keytool.exe" -list -v -keystore android\ridercms-release.jks -alias ridercms
```

### App bundle (.aab), for Google Play

```powershell
# Release bundle (upload this to Play Console)
flutter build appbundle --release

# With an explicit version (name = versionName, number = versionCode; the number must increase for every Play upload)
flutter build appbundle --release --build-name=1.0.1 --build-number=2

# Obfuscated, with symbols kept for crash reports (keep build/symbols for each release)
flutter build appbundle --release --obfuscate --split-debug-info=build/symbols

# Debug and profile bundles (rarely needed)
flutter build appbundle --debug
flutter build appbundle --profile
```

Output: `build\app\outputs\bundle\release\app-release.aab`

### APK, for direct install and testing

```powershell
# Release APK, one fat APK containing all CPU architectures
flutter build apk --release

# One smaller APK per CPU architecture (arm64-v8a, armeabi-v7a, x86_64)
flutter build apk --release --split-per-abi

# With an explicit version
flutter build apk --release --build-name=1.0.1 --build-number=2

# Obfuscated release APK
flutter build apk --release --obfuscate --split-debug-info=build/symbols

# Debug and profile APKs
flutter build apk --debug
flutter build apk --profile
```

Output (in `build\app\outputs\flutter-apk\`):
- `app-release.apk` (fat APK)
- `app-arm64-v8a-release.apk`, `app-armeabi-v7a-release.apk`, `app-x86_64-release.apk` (with `--split-per-abi`; most modern phones use `arm64-v8a`)
- `app-debug.apk`, `app-profile.apk`

### Run and install

```powershell
flutter run                      # debug build on the connected device or emulator
flutter run --release            # release mode on the device
flutter install                  # install the last built APK on the connected device
adb install -r build\app\outputs\flutter-apk\app-release.apk
```

### Backend target

Debug builds talk to whatever `lib/config/app_config.dart` selects, which is the production Cloud Run API unless you change it. Release builds always use `AppConstants.prodBaseUrl`. To test against a local backend from the Android emulator, use `http://10.0.2.2:3001/api`.

### Tests and analysis

```powershell
flutter analyze
flutter test
```

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
