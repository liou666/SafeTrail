# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

SafeTrail is an iOS safety app designed for users who frequently travel alone at night, particularly women or anyone seeking enhanced security. The app provides "one-tap departure", "real-time location sharing", and "covert emergency assistance" features to improve travel safety and peace of mind for family and friends.

## Architecture

This is a native iOS app built with:
- **SwiftUI** for the user interface
- **SwiftData** for local data persistence 
- **Xcode project** structure with standard iOS app targets

The project uses a standard iOS app architecture:
- `SafeTrailApp.swift` - Main app entry point with SwiftData model container setup
- `ContentView.swift` - Primary view using NavigationSplitView and SwiftData queries
- `Item.swift` - SwiftData model for persistent data storage
- Test targets for unit tests (`SafeTrailTests`) and UI tests (`SafeTrailUITests`)

## Core Features to Implement

Based on the product requirements, the app needs:
1. **One-tap safety mode** - Real-time location tracking and route recording
2. **Location sharing links** - Generate shareable links for family/friends to monitor location
3. **Destination confirmation** - Automatic "safely arrived" notifications
4. **Covert emergency assistance** - Hidden SOS functionality with fake interface overlay

## Development Commands

### Building and Running
```bash
# Build the project
xcodebuild -project SafeTrail.xcodeproj -scheme SafeTrail build

# Build and run tests
xcodebuild -project SafeTrail.xcodeproj -scheme SafeTrail test

# Build for device/simulator
xcodebuild -project SafeTrail.xcodeproj -scheme SafeTrail -configuration Debug build
```

### Testing
```bash
# Run unit tests only
xcodebuild -project SafeTrail.xcodeproj -scheme SafeTrail -destination 'platform=iOS Simulator,name=iPhone 15' test -only-testing:SafeTrailTests

# Run UI tests only  
xcodebuild -project SafeTrail.xcodeproj -scheme SafeTrail -destination 'platform=iOS Simulator,name=iPhone 15' test -only-testing:SafeTrailUITests

# Run all tests
xcodebuild -project SafeTrail.xcodeproj -scheme SafeTrail -destination 'platform=iOS Simulator,name=iPhone 15' test
```

The project uses the Swift Testing framework (`import Testing`) rather than XCTest.

## Implementation Status

✅ **Completed Features:**
- **Location Services**: Full location tracking with proper permissions
- **Safety Mode UI**: One-tap activation with beautiful gradient design
- **Real-time Tracking**: Continuous location recording during active sessions
- **Location Sharing**: Apple Maps integration for real-time location sharing
- **Emergency Contacts**: Complete contact management with enable/disable toggles
- **Emergency Mode**: Covert SOS with fake calendar interface overlay
- **Destination Confirmation**: Set destinations with arrival notifications
- **Settings Page**: Comprehensive configuration for all app features
- **Permission Guidance**: Step-by-step location permission setup with visual guide
- **Smart Sharing**: Automatically generates Apple Maps links for current location

## Recent Fixes (2025/7/12)

🔧 **Location Permission Issues Fixed:**
- Added comprehensive permission guidance UI
- Improved startSafetyMode() function to handle all permission states
- Added visual status indicators for permission states
- Enhanced error handling and user feedback

🔧 **Sharing Functionality Fixed:**
- Replaced complex server-based sharing with Apple Maps integration
- Direct location sharing via maps.apple.com links
- Real-time location updates in shared links
- Simplified and reliable sharing experience

## Key Files

- `Models.swift` - SwiftData models for contacts, sessions, and location data
- `LocationManager.swift` - Core location services and permissions
- `SharingService.swift` - Location sharing and emergency alert system
- `DestinationManager.swift` - Destination tracking and arrival detection
- `SettingsView.swift` - Emergency contacts and app configuration
- `DestinationPickerView.swift` - Destination selection with search functionality

## Key Implementation Notes

- The current codebase is a basic SwiftUI + SwiftData template that needs to be replaced with safety-focused functionality
- Location services, emergency contacts, and privacy features will be core requirements
- The app emphasizes simplicity and reliability over advanced features
- Privacy and security are paramount - no unnecessary data collection
- UI should use calming colors (light blue/green) with simple iconography