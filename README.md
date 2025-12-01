# NeuralPath

A comprehensive iOS mental health tracking application built with SwiftUI and SwiftData. Features HealthKit integration, CloudKit sync, on-device ML-powered predictions, and extensive tracking capabilities for mood, anxiety, emotions, sleep, medications, substances, mindfulness, and self-care routines.

## Screenshots

<p align="center">
  <img src="https://github.com/user-attachments/assets/5f4ceb71-7213-4fff-a88e-273e25630a9f" width="250" alt="Today View" />
  &nbsp;&nbsp;&nbsp;
  <img src="https://github.com/user-attachments/assets/3c6ffe59-dd4c-44b9-87ed-1c71b26050ba" width="250" alt="Entry Form" />
  &nbsp;&nbsp;&nbsp;
  <img src="https://github.com/user-attachments/assets/9d14c84b-5ad9-4a1d-a6e0-b6957d025e7a" width="250" alt="Charts View" />
</p>

<p align="center">
  <em>Today View</em> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
  <em>Entry Form</em> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
  <em>Charts View</em>
</p>

## Features

### Symptom Tracking
- **Mood Tracking**: 5-level mood scale with emoji visualization (Very Low to Excellent)
- **Anxiety Monitoring**: Track anxiety levels from None to Extreme with color coding
- **Anhedonia Assessment**: Monitor pleasure/interest loss with detailed descriptions
- **Emotion Tracking**: 28 predefined emotions categorized by valence (positive, negative, neutral) with color-coded cloud selector
- **Sleep Tracking**: Log sleep hours and quality ratings (automatic HealthKit import available)
- **Exercise & Daylight**: Track physical activity and daylight exposure

### Medication Management
- **Medication Library**: Personal medication database with 200+ predefined medications
- **Categories**: SSRIs, SNRIs, TCAs, MAOIs, Antipsychotics, Mood Stabilizers, Benzodiazepines, Sleep Aids, ADHD medications, Supplements, and more
- **Scheduling**: Daily, twice daily, weekly, as-needed (PRN), and custom frequencies
- **Reminders**: Per-medication notification reminders
- **Quick Logging**: Fast medication logging from Today view

### Substance Tracking
- **Custom Substances**: Track coffee, alcohol, water, supplements, and more
- **Units**: Multiple unit types (ml, oz, mg, g, cups, drinks, cigarettes)
- **Quick Logging**: Easy substance logging with customizable amounts

### Mindfulness Practices
- **Practice Types**: Meditation, breathing exercises, yoga, journaling, body scan, relaxation, walking, gratitude
- **Duration Tracking**: Log practice duration
- **Reminders**: Customizable practice reminders
- **Quick Logging**: Fast practice logging from Today view

### Self-Care Routines
- **Time-of-Day Categories**: Morning, afternoon, and evening routines
- **Completion Tracking**: Visual progress for each time category
- **Celebration Alerts**: Acknowledgment when completing all practices in a category
- **Category-Level Reminders**: One reminder per time-of-day instead of per-practice

### HealthKit Integration
- Automatic sleep data import with quality scoring
- Read heart rate and activity data
- Medication adherence from Health app (iOS 16+)
- State of Mind integration (iOS 18+)
- Secure permission-based access

### CloudKit Sync
- Automatic iCloud sync across devices
- Graceful fallback to local-only storage if CloudKit unavailable
- Sync status indicator in Settings

### On-Device ML Analysis
All machine learning processing happens locally using CoreML - no data is sent to external servers.

**Tiered Activation System:**
- **7+ entries**: Basic statistics and insights
- **30+ entries**: Basic ML predictions enabled
- **90+ entries**: Hybrid AI analysis (statistical + ML blended)
- **180+ entries**: Personalized ML with full pattern detection

**ML Features:**
- Tomorrow's mood prediction with confidence scoring
- 7-day mood trend forecast
- Pattern detection (sleep correlation, exercise benefit, medication effects, seasonal trends)
- Similar days matching using k-NN algorithm
- Data quality assessment and capability tracking

### Visualization
- **Charts & Graphs**: Swift Charts visualization with multiple metrics
  - Line charts for mood and anhedonia
  - Bar charts for anxiety and sleep
  - Time ranges: Week, Month, 3 Months, Year
  - Single metric or comparison mode
- **Analysis Dashboard**: Health score, trends, factor impacts
- **ML Insights**: Prediction cards, forecast charts, pattern cards

### Reminders
- Daily check-in notifications
- Per-medication reminders with custom times
- Mindfulness practice reminders
- Self-care category reminders (morning, afternoon, evening)
- Customizable notification preferences

### Data Export
- Export data in CSV or JSON format
- Share reports with healthcare providers
- Complete data portability

## Architecture

### SwiftData Model Layer
The app uses SwiftData with an eleven-model schema:

**Core Models:**
- `SymptomEntry`: Primary model with mood, anxiety, anhedonia, emotions, sleep, exercise, daylight, and notes
- `Medication`: Historical medication data tied to symptom entries
- `Substance`: Historical substance tracking tied to entries

**User Library Models:**
- `UserMedication`: User-configured medication library
- `UserSubstance`: User-configured substance library
- `UserMindfulness`: User-configured mindfulness practices
- `UserSelfCare`: User-configured self-care practices with time-of-day
- `MedicationLog`, `SubstanceLog`, `MindfulnessLog`, `SelfCareLog`: Quick logging records

### Services Layer
- **CloudKitManager**: CloudKit availability and sync status management
- **HealthKitManager**: HealthKit operations and authorization
- **SimpleStatisticalAnalyzer**: Mathematical insights and trend detection
- **HybridAnalysisEngine**: Combined statistical + ML analysis orchestration
- **MedicationReminderService**: Medication notification scheduling
- **MindfulnessReminderService**: Practice notification scheduling
- **SelfCareReminderService**: Category-level self-care reminders

### ML Analysis Layer (`Services/ML/`)
- **MLFeatureVector**: 70+ feature schema covering emotions, medications, temporal patterns
- **FeatureTransformers**: Data transformation pipeline for ML features
- **MLDataExtractor**: SwiftData query coordination for feature extraction
- **MLAnalysisEngine**: CoreML integration, predictions, pattern detection
- **MLModelManager**: Model lifecycle management
- **AnalysisBlender**: Statistical and ML result blending

### View Architecture
**4-Tab Navigation:**
1. **Today**: Daily dashboard with medications, substances, mindfulness, self-care, and entry status
2. **Entries**: Chronological entry list with add functionality
3. **Charts**: Data visualization with time range selection
4. **Analysis**: Health score, trends, ML predictions, and insights

## Technology Stack

- **SwiftUI**: Modern declarative UI framework
- **SwiftData**: Data persistence with CloudKit sync
- **HealthKit**: Health data integration
- **CloudKit**: iCloud sync
- **CoreML**: On-device machine learning
- **Charts**: Native data visualization
- **UserNotifications**: Reminder system
- **StoreKit**: In-app donations

## Privacy & Security

- All data stored locally with SwiftData
- Optional CloudKit sync (can be disabled)
- On-device ML processing - no data sent to servers
- HealthKit integration with explicit user permission
- User controls all data exports

## Requirements

- iOS 26.0 or later
- Xcode 26.0 or later
- HealthKit-capable device (for HealthKit features)

## Getting Started

1. Open `NeuralPath.xcodeproj` in Xcode
2. Select an iOS device or simulator
3. Build and run the project
4. Complete the onboarding flow:
   - Grant notification permissions for reminders
   - Connect to HealthKit for automatic sleep tracking
   - Add your medications, substances, and practices
   - Configure your reminder preferences

## Build Commands

```bash
# Open project in Xcode
open NeuralPath.xcodeproj

# Build from command line
xcodebuild -project NeuralPath.xcodeproj -scheme NeuralPath -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build

# Clean build folder
xcodebuild clean -project NeuralPath.xcodeproj -scheme NeuralPath
```

## Usage

### Today View
The Today tab provides a daily dashboard:
- View today's entry status (mood, anxiety, anhedonia)
- Check off scheduled medications
- Log PRN (as-needed) medications
- Track substance consumption with amounts
- Log mindfulness practices
- Complete self-care routines by time-of-day

### Adding an Entry
1. Tap the `+` button and select "Full Entry"
2. Select the date/time for your entry
3. Fill in symptoms (all fields are optional)
4. Select emotions from the cloud selector
5. Import sleep data from HealthKit if available
6. Add medications and substances
7. Include notes for context
8. Tap "Save"

### Viewing Analysis
1. Switch to the "Analysis" tab
2. View your health score and trends
3. See factor impact analysis
4. Review ML predictions (if enough data)
5. Explore detected patterns and similar days

### Managing Libraries
Access Settings to manage:
- Medication library (add/edit/remove medications)
- Substance library (add/edit/remove substances)
- Mindfulness practices (add/edit/remove practices)
- Self-care routines (add/edit/remove practices by time-of-day)

### Exporting Data
1. Open Settings
2. Tap "Export Data"
3. Choose format (CSV or JSON)
4. Share via any available method

## File Structure

```
NeuralPath/
├── Components/
│   ├── EmotionCloudSelector.swift
│   ├── SymptomEntryRow.swift
│   └── WrappingHStack.swift
├── Models/
│   ├── SymptomEntry.swift
│   ├── Medication.swift / UserMedication.swift / MedicationLog.swift
│   ├── Substance.swift / UserSubstance.swift / SubstanceLog.swift
│   ├── UserMindfulness.swift / MindfulnessLog.swift
│   ├── UserSelfCare.swift / SelfCareLog.swift
│   ├── MoodLevel.swift / AnxietyLevel.swift / AnhedoniaLevel.swift
│   ├── Emotion.swift
│   ├── MedicationDatabase.swift / MedicationCategory.swift
│   ├── MindfulnessCategory.swift
│   └── SelfCareTimeOfDay.swift
├── Services/
│   ├── CloudKitManager.swift
│   ├── HealthKitManager.swift
│   ├── HybridAnalysisEngine.swift
│   ├── SimpleStatisticalAnalyzer.swift
│   ├── MedicationReminderService.swift
│   ├── MindfulnessReminderService.swift
│   ├── SelfCareReminderService.swift
│   └── ML/
│       ├── MLFeatureVector.swift
│       ├── FeatureTransformers.swift
│       ├── MLDataExtractor.swift
│       ├── MLAnalysisEngine.swift
│       ├── MLModelManager.swift
│       └── AnalysisBlender.swift
├── Views/
│   ├── TodayView.swift
│   ├── AddSymptomView.swift
│   ├── SymptomDetailView.swift
│   ├── ChartsView.swift
│   ├── ComprehensiveAnalysisView.swift
│   ├── SettingsView.swift
│   ├── OnboardingView.swift
│   ├── WhatsNewView.swift
│   ├── ExportView.swift
│   ├── *ManagementView.swift (Medication, Substance, Mindfulness, SelfCare)
│   ├── QuickLog*.swift (Medication, Substance, Mindfulness, SelfCare)
│   └── Components/
│       └── MLAnalysisComponents.swift
├── ContentView.swift
├── NeuralPathApp.swift
├── Localizable.xcstrings
├── Info.plist
└── NeuralPath.entitlements
```

## License

This project is created for personal mental health tracking purposes.

## Disclaimer

This app is a tracking tool and not a substitute for professional medical advice, diagnosis, or treatment. Always seek the advice of your physician or other qualified health provider with any questions you may have regarding a medical condition.
