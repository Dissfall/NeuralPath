# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

NeuralPath is an iOS mental health tracking app built with SwiftUI and SwiftData. It enables users to track mood, anxiety, anhedonia, sleep, exercise, daylight exposure, medications, and substances. Features include HealthKit integration for automatic sleep data import, CloudKit sync, and Core ML-powered predictions.

## Build & Run Commands

```bash
# Open project in Xcode
open NeuralPath.xcodeproj

# Build from command line
xcodebuild -project NeuralPath.xcodeproj -scheme NeuralPath -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 15' build

# Clean build folder
xcodebuild clean -project NeuralPath.xcodeproj -scheme NeuralPath
```

**Requirements:**
- iOS 26.0+ deployment target
- Xcode 26.0+
- HealthKit-capable device for full functionality

## Architecture

### SwiftData Model Layer

The app uses SwiftData for persistence with a seven-model schema:

**Core Models:**
- **SymptomEntry** (`Models/SymptomEntry.swift`): Primary model with mood, anxiety, anhedonia, sleep data, exercise, daylight, notes, and relationships to medications/substances
- **Medication** (`Models/Medication.swift`): Historical medication data tied to symptom entries (cascade delete)
- **Substance** (`Models/Substance.swift`): Historical substance tracking tied to entries (cascade delete)

**User Library Models:**
- **UserMedication** (`Models/UserMedication.swift`): User-configured medication library with category, frequency, active status
- **UserSubstance** (`Models/UserSubstance.swift`): User-configured substance library with default units
- **MedicationLog** (`Models/MedicationLog.swift`): Quick medication logging records
- **SubstanceLog** (`Models/SubstanceLog.swift`): Quick substance logging records

**Model Container Setup:** Configured in `NeuralPathApp.swift` with three-tier fallback:
1. CloudKit-enabled configuration (if available)
2. Local-only fallback (if CloudKit fails)
3. In-memory fallback (last resort)

**Important:** All SwiftData queries use `@Query` property wrapper. The `@Environment(\.modelContext)` provides access for mutations.

### Services Layer

**CloudKitManager** (`Services/CloudKitManager.swift`):
- Singleton managing CloudKit availability and sync status
- Automatic simulator detection (disables CloudKit)
- Environment variable override: `DISABLE_CLOUDKIT`
- Posts `CloudKitAvailabilityChanged` notifications

**HealthKitManager** (`Services/HealthKitManager.swift`):
- Observable singleton for HealthKit operations
- `requestAuthorization()`: Sleep, heart rate, activity, State of Mind (iOS 18+)
- `requestMedicationAuthorization()`: iOS 16+ per-object authorization
- `fetchSleepData()`: Aggregates sleep stages, calculates quality score (1-5)

**MLManager** (`Services/MLManager.swift`):
- Loads 3 Core ML models: MoodPredictor, AnxietyPredictor, AnhedoniaPredictor
- Inputs: sleep hours/quality, daylight, exercise, medication status, substance amount, day of week, previous day metrics
- Optional return values with error handling

**SimpleStatisticalAnalyzer** (`Services/SimpleStatisticalAnalyzer.swift`):
- Mathematical insights without ML dependency
- Factor impact analysis with confidence scoring
- Trend detection and recommendations

**TestDataGenerator** (`Services/TestDataGenerator.swift`):
- Development utility for generating realistic test data
- Configurable patterns: improving, worsening, stable, variable

### View Architecture

**Navigation structure:** 3-tab TabView

**Tab 0 - Entries:**
- `ContentView.swift`: Entries list with NavigationStack, add menu (medication/substance/full entry)
- `SymptomEntryRow.swift`: List row component
- `SymptomDetailView.swift`: Read-only detail view with edit capability
- `AddSymptomView.swift`: Full entry form with HealthKit sleep import

**Tab 1 - Charts:**
- `ChartsView.swift`: Swift Charts visualization with time ranges (week/month/3 months/year), single or comparison mode

**Tab 2 - Analysis:**
- `ComprehensiveAnalysisView.swift`: Health score, trends, factor impacts using SimpleStatisticalAnalyzer

**Management Views:**
- `SettingsView.swift`: Reminders, medication/substance management, CloudKit status, export, hidden developer menu
- `MedicationManagementView.swift` / `AddUserMedicationView.swift`: Medication library CRUD
- `SubstanceManagementView.swift` / `AddUserSubstanceView.swift`: Substance library CRUD
- `QuickLogMedicationView.swift` / `QuickLogSubstanceView.swift`: Quick logging interfaces

**Utility Views:**
- `CloudKitStatusView.swift`: Sync status display
- `ExportView.swift`: CSV/JSON export
- `InsightsView.swift`: ML-powered predictions (requires 30+ entries)
- `DeveloperMenuView.swift`: Test data generation (Easter egg: 7 rapid taps in Settings)

### Type-safe Enums

**Symptom Levels:**
- `MoodLevel`: 5 levels with emoji, iOS 18+ `stateOfMindValence` support
- `AnxietyLevel`: 5 levels from None to Extreme with color coding
- `AnhedoniaLevel`: 5 levels with detailed descriptions

**Medication/Substance:**
- `MedicationCategory`: 9 categories (SSRI, SNRI, Benzodiazepine, etc.) with SF Symbol icons
- `MedicationFrequency`: 7 options (daily, twice daily, weekly, as needed, etc.)
- `SubstanceUnit`: 8 units (ml, oz, mg, g, cups, drinks, cigarettes, other)

## Required Permissions

**Info.plist:**
- `UIBackgroundModes`: remote-notification

**Entitlements:**
- `com.apple.developer.healthkit`: HealthKit access
- `com.apple.developer.icloud-container-identifiers`: iCloud.NeuralPath
- `com.apple.developer.icloud-services`: CloudKit
- `aps-environment`: development (push notifications)

## Core ML Models

Three tabular regression models in project root:
- `MoodPredictor.mlmodel`
- `AnxietyPredictor.mlmodel`
- `AnhedoniaPredictor.mlmodel`

ML project at `NeuralPath.mlproj/` with training data.

## Code Style

- Avoid `any` types - use `unknown` for uncertain data structures
- Minimize comments - use markers like `NOTE:`, `HACK:`, `BUG:` when necessary
- SwiftData models must be marked `@Model` and use `final class`
- HealthKit/CloudKit operations should use async/await with proper error handling
- Version-specific APIs must use `@available` checks
- Services use `@Observable` singleton pattern accessed via `.shared`
