# NeuralPath

A comprehensive iOS mental health symptom tracking application with HealthKit integration.

## Features

### Symptom Tracking
- **Mood Tracking**: 5-level mood scale with emoji visualization (Very Low to Excellent)
- **Anxiety Monitoring**: Track anxiety levels from None to Extreme
- **Anhedonia Assessment**: Monitor pleasure/interest loss with detailed descriptions
- **Sleep Tracking**: Log sleep hours and quality ratings
- **Medication Management**: Track medication adherence and effects

### HealthKit Integration
- Automatic sleep data import from HealthKit
- Read medication adherence from Health app (iOS 16+)
- View medication history logged in Health app
- Read heart rate and activity data
- Save mindful sessions
- Secure permission-based access

### Visualization
- **Charts & Graphs**: Visualize symptom trends over time
  - Line charts for mood and anhedonia
  - Bar charts for anxiety and sleep
  - Multiple time ranges: Week, Month, 3 Months, Year
- **Statistics**: View averages and trends for each metric

### Reminders
- Daily notifications to log symptoms
- Customizable reminder time
- User-controlled notification preferences

### Data Export
- Export data in CSV or JSON format
- Share reports with healthcare providers
- Complete data portability

## Architecture

### Data Models
- **SymptomEntry**: Main model storing all symptom data with SwiftData
- **Medication**: Tracks individual medications with dosage and adherence
- **MoodLevel/AnxietyLevel/AnhedoniaLevel**: Type-safe enums for symptom levels

### Services
- **HealthKitManager**: Handles all HealthKit integration
  - Authorization management
  - Sleep data fetching
  - Mindful session logging

### Views
- **ContentView**: Main tab-based interface
- **AddSymptomView**: Form for creating new entries
- **SymptomDetailView**: Detailed view of individual entries
- **ChartsView**: Data visualization with Charts framework
- **SettingsView**: App configuration and integrations
- **ExportView**: Data export functionality

## Technology Stack

- **SwiftUI**: Modern declarative UI framework
- **SwiftData**: Data persistence and management
- **HealthKit**: Health data integration
- **Charts**: Native data visualization
- **UserNotifications**: Daily reminder system

## Privacy & Security

- All data stored locally with SwiftData
- HealthKit integration with explicit user permission
- Privacy-focused design with no cloud sync
- User controls all data exports

## Getting Started

1. Open `NeuralPath.xcodeproj` in Xcode
2. Select an iOS device or simulator (iOS 17.0+)
3. Build and run the project
4. On first launch:
   - Grant notification permissions for reminders
   - Connect to HealthKit for automatic sleep tracking
   - Add your first symptom entry

## Usage

### Adding an Entry
1. Tap the `+` button on the main screen
2. Select the date/time for your entry
3. Fill in relevant symptoms (all fields are optional)
4. Import sleep data from HealthKit if available
5. Add medications if needed
6. Include notes for context
7. Tap "Save"

### Viewing Charts
1. Switch to the "Charts" tab
2. Select time range (Week/Month/3 Months/Year)
3. Choose metric to visualize (Mood/Anxiety/Anhedonia/Sleep)
4. Review statistics below the chart

### Setting Up Reminders
1. Tap the gear icon to open Settings
2. Toggle "Daily Reminders"
3. Set your preferred reminder time
4. Grant notification permissions when prompted

### Viewing Medication History from Health App
1. Connect to HealthKit in Settings (if not already connected)
2. Tap "Medication History" in Settings
3. View medications logged in the Health app
4. Select time range (Week/Month/3 Months/Year)
5. See medication adherence status (Taken/Skipped)

Note: Medications are logged in the Health app separately. NeuralPath can read this data but cannot write to it directly.

### Exporting Data
1. Open Settings
2. Tap "Export Data"
3. Choose format (CSV or JSON)
4. Share via any available method

## Requirements

- iOS 17.0 or later
- Xcode 16.0 or later
- HealthKit-capable device (for HealthKit features)

## File Structure

```
NeuralPath/
├── Models/
│   ├── SymptomEntry.swift
│   ├── Medication.swift
│   ├── MoodLevel.swift
│   ├── AnxietyLevel.swift
│   └── AnhedoniaLevel.swift
├── Views/
│   ├── AddSymptomView.swift
│   ├── SymptomDetailView.swift
│   ├── ChartsView.swift
│   ├── SettingsView.swift
│   ├── ExportView.swift
│   └── MedicationHistoryView.swift
├── Services/
│   └── HealthKitManager.swift
├── ContentView.swift
├── NeuralPathApp.swift
├── Info.plist
└── NeuralPath.entitlements
```

## License

This project is created for personal mental health tracking purposes.

## Disclaimer

This app is a tracking tool and not a substitute for professional medical advice, diagnosis, or treatment. Always seek the advice of your physician or other qualified health provider with any questions you may have regarding a medical condition.
