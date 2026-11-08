# Melora — Build & Release Guide

This guide describes how to build, run, archive, and release **Melora** on macOS with Xcode 16+ for iOS 18+.

---

## 1. Prerequisites & System Requirements

- **macOS**: Sonoma 14.5+ or Sequoia 15.0+
- **Xcode**: 16.0 or later (Swift 6 toolchain, iOS 18 SDK)
- **Homebrew** (recommended): For installing developer utilities
- **XcodeGen** (optional, recommended): `brew install xcodegen`
- **SwiftLint** (optional): `brew install swiftlint`
- **Apple Developer Account**: Required for physical device testing with capabilities (background audio) and TestFlight distribution.

---

## 2. Project Setup & Opening

Melora provides two convenient workflows for opening the project in Xcode:

### Option A: Open Committed Xcode Project Directly (Zero Setup)
Double-click `Melora.xcodeproj` or execute:
```bash
open Melora.xcodeproj
```
Xcode will resolve local Swift package dependencies (`MeloraCore`, `MeloraData`, `MeloraAudio`, `MeloraUI`) automatically.

### Option B: Regenerate with XcodeGen (Recommended for Contributors)
To regenerate the project deterministically from [`project.yml`](file:///e:/Downloads/app/project.yml):
```bash
xcodegen generate
open Melora.xcodeproj
```

---

## 3. Running on the iOS Simulator

1. Launch Xcode and select the **MeloraApp** scheme in the top toolbar.
2. Select an iOS 18+ simulator (e.g., **iPhone 16**, **iPhone 16 Pro**).
3. Press **Cmd + R** (or click the **Play** button).
4. The simulator will boot and launch Melora.

### Command-Line Simulator Build & Run
You can also compile and run directly from Terminal:
```bash
# Build for iOS Simulator
xcodebuild \
  -project Melora.xcodeproj \
  -scheme MeloraApp \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.0' \
  build

# Boot simulator and install app
xcrun simctl boot "iPhone 16" || true
xcrun simctl install booted .build/DerivedData/Build/Products/Debug-iphonesimulator/Melora.app
xcrun simctl launch booted com.melora.music
```

---

## 4. Running on a Physical iOS Device

1. Connect your iPhone running **iOS 18+** via USB-C or Lightning.
2. In Xcode, select the **MeloraApp** target -> **Signing & Capabilities**.
3. Under **Signing**, check **Automatically manage signing** and choose your Apple Developer Team.
4. Select your connected physical device in the device menu.
5. Press **Cmd + R** to build, sign, and install.
6. On your iPhone: Go to **Settings > General > VPN & Device Management** and trust your Developer App certificate.

---

## 5. Creating a Release Archive

To prepare a production or TestFlight build, create an `.xcarchive` file:

```bash
# 1. Clean previous builds
rm -rf build/Melora.xcarchive build/IPA

# 2. Build Release Archive
xcodebuild \
  -project Melora.xcodeproj \
  -scheme MeloraApp \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath build/Melora.xcarchive \
  archive
```

---

## 6. Exporting the IPA for TestFlight / App Store

Melora provides ready-to-use export configuration templates in [`Release/ExportOptions.plist.template`](file:///e:/Downloads/app/Release/ExportOptions.plist.template).

### Step 1: Prepare ExportOptions.plist
Copy the template and replace `REPLACE_WITH_APPLE_TEAM_ID` with your 10-character Apple Team ID:

```bash
cp Release/ExportOptions.plist.template Release/ExportOptions.plist
sed -i '' 's/REPLACE_WITH_APPLE_TEAM_ID/YOUR_TEAM_ID_HERE/g' Release/ExportOptions.plist
```

### Step 2: Export Archive to IPA
```bash
xcodebuild \
  -exportArchive \
  -archivePath build/Melora.xcarchive \
  -exportPath build/IPA \
  -exportOptionsPlist Release/ExportOptions.plist
```
Upon successful execution, the signed `Melora.ipa` file will be generated in `build/IPA/`.

---

## 7. Uploading to TestFlight

### Via App Store Connect API (Recommended for CI/CD)
```bash
xcrun altool --upload-app \
  --type ios \
  --file build/IPA/Melora.ipa \
  --apiKey YOUR_API_KEY_ID \
  --apiIssuer YOUR_ISSUER_UUID
```

Or using `xcrun notarytool` / Fastlane:
```bash
fastlane pilot upload --ipa build/IPA/Melora.ipa
```

### Via Apple Transporter App (GUI)
1. Download **Transporter** from the Mac App Store.
2. Sign in with your Apple Developer credentials.
3. Drag and drop `build/IPA/Melora.ipa` into Transporter.
4. Click **Deliver**.

---

## 8. App Store Review & Policy Checklist

Before submitting to App Store Review:

- [x] **Background Audio Justification**: Melora plays user-owned audio files. `UIBackgroundModes = ["audio"]` is strictly required. Provide audio sample files and playback instructions in App Review notes.
- [x] **No Spotify Audio Ripping**: Adhere 100% to Spotify Terms of Service. Verify that Spotify tracks only open Spotify metadata and that audio files are exclusively local files.
- [x] **Document Picker**: Verify `LSSupportsOpeningDocumentsInPlace` and `UIFileSharingEnabled` are enabled to permit local file management.
- [x] **Export Compliance**: Set `<key>ITSAppUsesNonExemptEncryption</key><false/>` in `Info.plist` to prevent manual encryption questionnaires.
- [x] **Privacy Policy**: Provide a valid URL stating that no user audio data, listening history, or Spotify tokens are sold or sent to third-party ad networks.
