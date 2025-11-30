# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

NeuralPath is an iOS mental health tracking app built with SwiftUI and SwiftData. It enables users to track mood, anxiety, anhedonia, sleep, exercise, daylight exposure, medications, substances, mindfulness practices, and self-care routines. Features include HealthKit integration for automatic sleep data import, CloudKit sync, statistical analysis, and on-device ML-powered predictions using CoreML.

## Build & Run Commands

```bash
# Open project in Xcode
open NeuralPath.xcodeproj

# Build from command line
xcodebuild -project NeuralPath.xcodeproj -scheme NeuralPath -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build

# Clean build folder
xcodebuild clean -project NeuralPath.xcodeproj -scheme NeuralPath
```

**Requirements:**
- iOS 26.0+ deployment target
- Xcode 26.0+
- HealthKit-capable device for full functionality

## Architecture

### SwiftData Model Layer

The app uses SwiftData for persistence with an eleven-model schema:

**Core Models:**
- **SymptomEntry** (`Models/SymptomEntry.swift`): Primary model with mood, anxiety, anhedonia, emotions, sleep data, exercise, daylight, notes, and relationships to medications/substances
- **Medication** (`Models/Medication.swift`): Historical medication data tied to symptom entries (cascade delete)
- **Substance** (`Models/Substance.swift`): Historical substance tracking tied to entries (cascade delete)

**User Library Models:**
- **UserMedication** (`Models/UserMedication.swift`): User-configured medication library with category, frequency, active status
- **UserSubstance** (`Models/UserSubstance.swift`): User-configured substance library with default units
- **UserMindfulness** (`Models/UserMindfulness.swift`): User-configured mindfulness practices with category, duration, reminders
- **MedicationLog** (`Models/MedicationLog.swift`): Quick medication logging records
- **SubstanceLog** (`Models/SubstanceLog.swift`): Quick substance logging records
- **MindfulnessLog** (`Models/MindfulnessLog.swift`): Quick mindfulness practice logging records
- **UserSelfCare** (`Models/UserSelfCare.swift`): User-configured self-care practices with time-of-day (morning/afternoon/evening)
- **SelfCareLog** (`Models/SelfCareLog.swift`): Quick self-care practice logging records

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

**SimpleStatisticalAnalyzer** (`Services/SimpleStatisticalAnalyzer.swift`):
- Mathematical insights without ML dependency
- Factor impact analysis with confidence scoring
- Trend detection and recommendations

**TestDataGenerator** (`Services/TestDataGenerator.swift`):
- Development utility for generating realistic test data
- Configurable patterns: improving, worsening, stable, variable

**MedicationReminderService** (`Services/MedicationReminderService.swift`):
- Singleton for scheduling medication notifications via UNUserNotificationCenter
- `scheduleMedicationReminders()`: Schedules reminders for medications with `reminderEnabled=true`
- Uses `UNCalendarNotificationTrigger` with `repeats: true` for daily recurring notifications
- Identifier prefix: `"medicationReminder_"` + medication UUID
- `requestNotificationPermission()`: Requests authorization for alerts, sound, badge

**MindfulnessReminderService** (`Services/MindfulnessReminderService.swift`):
- Singleton for scheduling mindfulness practice notifications
- `scheduleMindfulnessReminders()`: Schedules reminders for practices with `reminderEnabled=true`
- Identifier prefix: `"mindfulnessReminder_"` + practice UUID
- UserDefaults key: `"mindfulnessReminderEnabled"` for global toggle

**SelfCareReminderService** (`Services/SelfCareReminderService.swift`):
- Singleton for scheduling category-level self-care reminders
- One reminder per time-of-day (morning, afternoon, evening) instead of per-practice
- Identifier format: `"selfCareReminder_morning"`, `"selfCareReminder_afternoon"`, `"selfCareReminder_evening"`
- UserDefaults keys: `selfCareMorningReminderEnabled`, `selfCareAfternoonReminderEnabled`, `selfCareEveningReminderEnabled`
- Default reminder times: 7 AM, 12 PM, 8 PM

### ML Analysis Layer

The app includes an on-device machine learning system for mood prediction and pattern detection. All ML processing happens locally using CoreML - no data is sent to external servers.

**Tiered Activation System:**
- **7+ entries**: Basic statistics only
- **30+ entries**: Basic ML predictions enabled
- **90+ entries**: Hybrid AI analysis (statistical + ML blended)
- **180+ entries**: Personalized ML with full pattern detection

**ML Services** (`Services/ML/`):

**MLFeatureVector** (`Services/ML/MLFeatureVector.swift`):
- 70+ feature schema covering emotions, medications, temporal patterns, mindfulness, self-care, lifestyle
- `EmotionFeatures`: Valence aggregation, dominant emotions, variety metrics
- `MedicationFeatures`: Category encoding, adherence tracking, regimen change detection
- `TemporalFeatures`: Day of week, time of day (cyclical sin/cos encoding), streak tracking
- `MindfulnessFeatures`: Practice completion rates, variety, duration
- `SelfCareFeatures`: Morning/afternoon/evening completion rates
- `LifestyleFeatures`: Sleep quality, exercise, daylight exposure
- `InteractionFeatures`: Cross-factor interactions (sleep×exercise, medication×mood)

**FeatureTransformers** (`Services/ML/FeatureTransformers.swift`):
- `EmotionTransformer`: Converts emotion arrays to valence-weighted features
- `MedicationTransformer`: Tracks medication adherence and regimen changes with 14-day transition periods
- `TemporalTransformer`: Cyclical encoding for time features, streak calculation
- `MindfulnessTransformer`: Practice variety and consistency metrics
- `SelfCareTransformer`: Time-of-day completion tracking
- `LifestyleTransformer`: Normalizes sleep/exercise/daylight data
- `InteractionTransformer`: Computes cross-factor feature interactions
- `MissingDataHandler`: Filters valid entries for training

**MLDataExtractor** (`Services/ML/MLDataExtractor.swift`):
- SwiftData query coordination for feature extraction
- `extractTrainingData()`: Builds feature vectors from historical entries
- `extractFeaturesForEntry()`: Single entry feature extraction for prediction
- `assessDataQuality()`: Returns `DataQualityAssessment` with completeness metrics
- `AnalysisCapability` enum: Tracks unlocked features based on entry count

**MLAnalysisEngine** (`Services/ML/MLAnalysisEngine.swift`):
- CoreML integration for predictions
- k-NN pattern matching for similar day detection
- `predictTomorrowMood()`: Next-day mood prediction with confidence
- `forecast7Days()`: 7-day mood trend forecast
- `detectPatterns()`: Identifies recurring patterns (sleep, exercise, medication effects)
- `findSimilarDays()`: Finds historical days with similar feature profiles
- `PatternType` enum: weekly, medicationEffect, substanceTrigger, sleepCorrelation, exerciseBenefit, mindfulnessImpact, seasonalTrend

**MLModelManager** (`Services/ML/MLModelManager.swift`):
- Singleton managing model lifecycle (`MLModelManager.shared`)
- `ModelState`: notInitialized, initializing, ready, needsRetraining, error
- Auto-initializes on app launch via `autoInitializeIfNeeded()`
- UserDefaults key: `"mlAnalysisEnabled"` (defaults to true)
- Tracks `lastTrainingDate`, `entriesSinceTraining`, `modelVersion`
- Retraining triggers: 7+ days since training OR 10+ new entries

**AnalysisBlender** (`Services/ML/AnalysisBlender.swift`):
- Blends statistical and ML results based on `AnalysisMode`
- Confidence-weighted score combination
- `ConfidenceMetrics`: statisticalConfidence, mlConfidence, dataQuality, blendWeights

**HybridAnalysisEngine** (`Services/HybridAnalysisEngine.swift`):
- Main orchestrator for hybrid statistical + ML analysis
- `analyze()`: Runs both statistical and ML analysis, returns `HybridAnalysis`
- `generateInsights()`: Creates `HybridInsight` array from analysis results
- Graceful fallback to statistical-only if ML fails

**ML UI Components** (`Views/Components/MLAnalysisComponents.swift`):
- `MLPredictionCard`: Tomorrow's mood prediction with contributing factors
- `ForecastChart`: 7-day forecast visualization using Swift Charts
- `PatternCard`: Individual pattern display with recommendations
- `PatternsSection`: List of detected patterns
- `SimilarDaysCard`: Historical similar days comparison
- `DataQualityCard`: Entry count, capabilities, next milestone
- `MLStatusBanner`: Current analysis mode indicator
- `ConfidenceBadge`: Confidence level indicator (High/Medium/Low)

### Medication Database

**MedicationDatabase** (`Models/MedicationDatabase.swift`):
- Static in-memory database with 200+ predefined medications
- `MedicationInfo` struct: name, category, aliases (brand names), UUID
- Categories: SSRIs, SNRIs, TCAs, MAOIs, Antipsychotics, Mood Stabilizers, Benzodiazepines, Sleep Aids, ADHD medications, Supplements, and more
- Query methods:
  - `search(_ query: String)`: Case-insensitive search by name or alias
  - `byCategory(_ category: MedicationCategory)`: Filter by category
  - `sortedByName`: Alphabetically sorted list
- Used in `AddUserMedicationView` for medication selection/autocomplete

### View Architecture

**Navigation structure:** 4-tab TabView

**Tab 0 - Today:**
- `TodayView.swift`: Daily dashboard showing today's medications, substances, mindfulness, self-care, and entry status
- Sections: Today's Entry (mood/anxiety/anhedonia), Self-Care (morning/afternoon/evening sections), Scheduled Medications (checkbox to mark taken), PRN Medications (as-needed logging), Substances (with amounts), Mindfulness (practice logging)
- Self-care sections grouped by time-of-day with completion celebration alerts
- Quick logging: Tap checkbox to create logs, swipe to edit time/amount or delete
- Uses `@Query` with date predicates to filter today's data

**Tab 1 - Entries:**
- `ContentView.swift`: Entries list with NavigationStack, add menu (medication/substance/full entry)
- `SymptomEntryRow.swift`: List row component
- `SymptomDetailView.swift`: Read-only detail view with edit capability
- `AddSymptomView.swift`: Full entry form with HealthKit sleep import

**Tab 2 - Charts:**
- `ChartsView.swift`: Swift Charts visualization with time ranges (week/month/3 months/year), single or comparison mode

**Tab 3 - Analysis:**
- `ComprehensiveAnalysisView.swift`: Health score, trends, factor impacts using hybrid statistical + ML analysis
- ML features: Tomorrow's prediction, 7-day forecast, detected patterns, similar days, data quality metrics
- Uses `HybridAnalysisEngine` for combined analysis, falls back to statistical-only if ML unavailable
- ML status banner shows current analysis mode (Statistical/Basic ML/Hybrid/Advanced)

**Management Views:**
- `SettingsView.swift`: Reminders, medication/substance/mindfulness/self-care management, CloudKit status, AI Analysis toggle, export, hidden developer menu
- `MLSettingsSection`: AI Analysis toggle (enabled by default), status indicator, model info, "About AI Analysis" navigation
- `MedicationManagementView.swift` / `AddUserMedicationView.swift`: Medication library CRUD
- `SubstanceManagementView.swift` / `AddUserSubstanceView.swift`: Substance library CRUD
- `MindfulnessManagementView.swift` / `AddUserMindfulnessView.swift`: Mindfulness practice library CRUD
- `SelfCareManagementView.swift` / `AddUserSelfCareView.swift`: Self-care practice library CRUD with per-category reminder settings
- `QuickLogMedicationView.swift` / `QuickLogSubstanceView.swift` / `QuickLogMindfulnessView.swift` / `QuickLogSelfCareView.swift`: Quick logging interfaces

**Utility Views:**
- `CloudKitStatusView.swift`: Sync status display
- `ExportView.swift`: CSV/JSON export
- `DeveloperMenuView.swift`: Test data generation (Easter egg: 7 rapid taps in Settings)

**Reusable Components** (`Components/`):
- `WrappingHStack.swift`: Custom Layout for multi-row flex layouts (used for emotion chips, substances)
- `EmotionCloudSelector.swift`: Multi-select emotion picker with color-coded chips by valence
- `SymptomEntryRow.swift`: List row for displaying symptom entries with mood, emotions, substances
- `MLAnalysisComponents.swift`: ML-specific UI components (MLPredictionCard, ForecastChart, PatternCard, DataQualityCard, etc.)

### Onboarding & First Launch

**OnboardingView** (`Views/OnboardingView.swift`):
- `OnboardingManager`: Manages state via UserDefaults key `"hasCompletedOnboarding"`
- 9 sequential steps via TabView:
  1. **Welcome**: Introduction to NeuralPath
  2. **HealthKit**: Request Apple Health authorization for sleep/exercise
  3. **Medications**: Add medications (manual entry or HealthKit import)
  4. **Substances**: Quick-add common substances (Coffee, Alcohol, Water, Tea, Energy Drink)
  5. **Mindfulness**: Quick-add mindfulness practices (Meditation, Breathing, Yoga, Journaling, etc.)
  6. **Self-Care**: Quick-add self-care practices organized by time-of-day (morning/afternoon/evening)
  7. **Reminders**: Configure daily entry and medication reminder times
  8. **How to Use**: Interactive 5-screen tutorial carousel
  9. **Complete**: Final tips and get started
- Shown via `fullScreenCover` in `NeuralPathApp.swift` on first launch
- `resetOnboarding()` available for testing via Developer Menu

### What's New Screen

**WhatsNewView** (`Views/WhatsNewView.swift`):
- `WhatsNewManager`: Tracks last seen version via UserDefaults key `"lastSeenWhatsNewVersion"`
- `checkForWhatsNew()`: Compares current app version with last seen using semantic version comparison
- `WhatsNewContent` enum: Static configuration of features per version
- Shown after onboarding or when app version upgrades
- Version 1.1 features: Mindfulness Tracking, Self-Care Routines, Emotion Cloud, Today View, Swipe Actions, PRN Medications, Privacy Notice

### Reminders System

**Daily Entry Reminder** (in `SettingsView.swift`):
- Toggle + DatePicker for daily check-in notification
- UserDefaults keys: `"dailyReminderEnabled"`, `"dailyReminderTime"`
- Identifier: `"dailyEntryReminder"`
- Default time: 9 PM (set during onboarding)

**Medication Reminders** (via `MedicationReminderService`):
- Per-medication reminders using `UserMedication.reminderTime` and `reminderEnabled`
- Scheduled via `UNCalendarNotificationTrigger` with daily repeats
- UserDefaults key: `"medicationReminderEnabled"` for global toggle

### Type-safe Enums

**Symptom Levels:**
- `MoodLevel`: 5 levels with emoji, iOS 18+ `stateOfMindValence` support
- `AnxietyLevel`: 5 levels from None to Extreme with color coding
- `AnhedoniaLevel`: 5 levels with detailed descriptions

**Emotions:**
- `Emotion` (`Models/Emotion.swift`): 28 predefined emotions with valence categorization
- `EmotionValence`: positive, negative, neutral - determines chip color
- Stored as `[String]` in SymptomEntry, accessed via `emotions` computed property

**Medication/Substance:**
- `MedicationCategory`: 9 categories (SSRI, SNRI, Benzodiazepine, etc.) with SF Symbol icons
- `MedicationFrequency`: 7 options (daily, twice daily, weekly, as needed, etc.)
- `SubstanceUnit`: 8 units (ml, oz, mg, g, cups, drinks, cigarettes, other)

**Mindfulness:**
- `MindfulnessCategory` (`Models/MindfulnessCategory.swift`): 8 practice types with SF Symbol icons
- Categories: meditation, breathing, yoga, journaling, bodyScan, relaxation, walking, gratitude

**Self-Care:**
- `SelfCareTimeOfDay` (`Models/SelfCareTimeOfDay.swift`): 3 time-of-day categories
- Cases: morning (sunrise.fill, orange), afternoon (sun.max.fill, yellow), evening (sunset.fill, indigo)
- Includes `completionMessage` for celebration alerts when all practices in a category are completed

## Required Permissions

**Info.plist:**
- `UIBackgroundModes`: remote-notification

**Entitlements:**
- `com.apple.developer.healthkit`: HealthKit access
- `com.apple.developer.icloud-container-identifiers`: iCloud.NeuralPath
- `com.apple.developer.icloud-services`: CloudKit
- `aps-environment`: development (push notifications)

## Code Style

- Avoid `any` types - use `unknown` for uncertain data structures
- Minimize comments - use markers like `NOTE:`, `HACK:`, `BUG:` when necessary
- SwiftData models must be marked `@Model` and use `final class`
- HealthKit/CloudKit operations should use async/await with proper error handling
- Version-specific APIs must use `@available` checks
- Services use `@Observable` singleton pattern accessed via `.shared`
