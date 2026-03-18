# SixtyFour

Chess.com puzzle tracker for iOS with home screen widgets.

## Prerequisites

- Xcode 16+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`

## Build

```bash
# Generate Xcode project
xcodegen generate

# Build for simulator
xcodebuild -project SixtyFour.xcodeproj -scheme SixtyFour \
  -sdk iphonesimulator -destination "platform=iOS Simulator,name=iPhone 16 Pro" \
  -derivedDataPath build build

# Install on simulator
xcrun simctl install booted build/Build/Products/Debug-iphonesimulator/SixtyFour.app
xcrun simctl launch booted com.markorel.sixtyfour
```

## Publish to TestFlight

```bash
# 1. Bump CURRENT_PROJECT_VERSION in project.yml

# 2. Generate project
xcodegen generate

# 3. Archive
xcodebuild -project SixtyFour.xcodeproj -scheme SixtyFour \
  -sdk iphoneos -configuration Release \
  -archivePath build/SixtyFour.xcarchive archive \
  DEVELOPMENT_TEAM=RS3489446Y CODE_SIGN_STYLE=Automatic \
  -allowProvisioningUpdates

# 4. Upload via Xcode Organizer
open build/SixtyFour.xcarchive
# Then: Distribute App → TestFlight & App Store → Upload
```

## Setup

### Apple Developer Portal
- **Bundle IDs**: `com.markorel.sixtyfour`, `com.markorel.sixtyfour.widget`
- **App Group**: `group.com.sixtyfour.shared` (enabled on both bundle IDs)

### App Store Connect
- **Apple ID**: 6760730695
- **SKU**: sixtyfour
