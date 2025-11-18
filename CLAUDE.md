# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

NeuralPath is an iOS mental health tracking app built with SwiftUI and SwiftData. It allows users to track mood, anxiety, anhedonia, sleep, and medications with HealthKit integration for automatic sleep data import and medication adherence tracking.

## Build & Run Commands

```bash
# Open project in Xcode
open NeuralPath.xcodeproj

# Build from command line (requires selecting a scheme first)
xcodebuild -project NeuralPath.xcodeproj -scheme NeuralPath -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 15' build

# Clean build folder
xcodebuild clean -project NeuralPath.xcodeproj -scheme NeuralPath
```

**Requirements:**
- iOS 17.0+ deployment target
- Xcode 16.0+
- HealthKit-capable device for full functionality

## Architecture

### SwiftData Model Layer

The app uses SwiftData for persistence with a two-model schema:

- **SymptomEntry** (`Models/SymptomEntry.swift`): Primary model containing timestamp, mood, anxiety, anhedonia, sleep data, notes, and medications relationship
- **Medication** (`Models/Medication.swift`): Related model with cascade delete rule, tracks name, dosage, taken status, and notes

**Model Container Setup:** Configured in `NeuralPathApp.swift:13-25` with persistent storage (not in-memory). The schema is injected via `.modelContainer()` modifier on the WindowGroup.

**Important:** All SwiftData queries use `@Query` property wrapper and must be in SwiftUI views. The `@Environment(\.modelContext)` provides access for mutations (insert, delete, save).

### HealthKit Integration

**HealthKitManager** (`Services/HealthKitManager.swift`) is a singleton Observable class handling all HealthKit operations:

- Authorization is split into two methods:
  - `requestAuthorization()`: Standard permissions (sleep, heart rate, activity, State of Mind for iOS 18+)
  - `requestMedicationAuthorization()`: iOS 16+ per-object authorization for medication data

- Sleep data fetching (`fetchSleepData()`) aggregates multiple sleep stages (core, deep, REM) and calculates a quality score (1-5) based on total hours and deep sleep ratio

- Medication data is read-only from Health app (iOS 16+). App cannot write medication adherence to HealthKit directly

**Version-specific APIs:**
- iOS 16.0+: `HKUserAnnotatedMedicationType` for reading medications
- iOS 18.0+: `HKStateOfMind` for mental state tracking

### View Architecture

**Navigation structure:** Single TabView with two tabs (Entries list + Charts visualization)

**Main views:**
- `ContentView.swift`: Tab container and entries list using NavigationStack
- `AddSymptomView.swift`: Form for creating new SymptomEntry with HealthKit sleep import
- `SymptomDetailView.swift`: Read-only detail view of existing entries
- `ChartsView.swift`: Time-series visualization using Swift Charts framework with multiple time ranges (week/month/3 months/year)
- `SettingsView.swift`: App configuration, HealthKit connection, reminders, and export
- `ExportView.swift`: CSV/JSON export functionality
- `MedicationHistoryView.swift`: Displays medications from Health app with time range filtering

**Data flow:** Views use `@Environment(\.modelContext)` for mutations and `@Query` for fetching. HealthKitManager is accessed via `.shared` singleton.

### Type-safe Enums

All symptom levels use custom enums (not raw integers):
- `MoodLevel`: 5 levels with emoji representation
- `AnxietyLevel`: 5 levels from None to Extreme
- `AnhedoniaLevel`: 5 levels describing pleasure/interest loss

These enums provide `.displayName` and `.emoji` properties for UI display and should conform to Codable for persistence.

## Required Permissions

**Info.plist:**
- `NSHealthShareUsageDescription`: Required for reading HealthKit data
- `NSHealthUpdateUsageDescription`: Required for writing to HealthKit

**Entitlements:**
- `com.apple.developer.healthkit`: Must be enabled
- CloudKit capabilities are configured but may not be actively used

## Code Style

- Avoid `any` types - use `unknown` for uncertain data structures
- Minimize comments - use markers like `NOTE:`, `HACK:`, `BUG:` when necessary
- Keep JSDoc concise and informative
- SwiftData models must be marked `@Model` and use `final class`
- HealthKit operations should use async/await with proper error handling
- Version-specific APIs must use `@available` checks
