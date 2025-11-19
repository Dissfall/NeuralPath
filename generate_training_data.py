#!/usr/bin/env python3
"""
Generate realistic synthetic mental health training data for Core ML
Shows patterns of:
- Medication effectiveness (mood improves with consistent medication)
- Sleep-mood correlation
- Exercise benefits
- Daylight exposure benefits
- Substance effects (caffeine/alcohol)
- Day of week patterns
- Lagged effects (previous day impacts)
"""

import csv
import random
from datetime import datetime, timedelta

# Set seed for reproducibility
random.seed(42)

def generate_realistic_data(num_days=180):
    """Generate realistic mental health data for training"""
    data = []

    # Starting date (6 months ago)
    start_date = datetime.now() - timedelta(days=num_days)

    # Medication starts at day 60 (simulate starting antidepressant)
    medication_start_day = 60

    # Baseline values (before medication)
    baseline_mood = 2.0  # Poor mood initially
    baseline_anxiety = 3.0  # High anxiety initially

    previous_sleep = 6.5
    previous_mood = 2

    for day in range(num_days):
        current_date = start_date + timedelta(days=day)
        day_of_week = current_date.weekday() + 1  # 1-7 (Sunday=1)

        # Medication taken (starts at day 60, 85% adherence after that)
        on_medication = day >= medication_start_day
        medication_taken = 1 if (on_medication and random.random() < 0.85) else 0

        # Days on medication (for cumulative effect)
        days_on_meds = max(0, day - medication_start_day) if medication_taken else 0

        # Medication effect (builds up over 4-6 weeks)
        med_effect = 0
        if on_medication:
            # Gradual improvement over 30 days
            med_effect = min(1.5, (days_on_meds / 30) * 1.5)
            # Reduced if not taken consistently
            if not medication_taken:
                med_effect *= 0.3

        # Sleep (affects mood significantly)
        # Weekends: better sleep, weekdays: varies
        is_weekend = day_of_week in [1, 7]  # Sunday or Saturday
        base_sleep = random.uniform(7.5, 9.0) if is_weekend else random.uniform(6.0, 8.0)

        # Medication improves sleep quality
        sleep_hours = base_sleep + (med_effect * 0.5) + random.uniform(-0.5, 0.5)
        sleep_hours = max(4.0, min(10.0, sleep_hours))

        # Sleep quality (1-5)
        sleep_quality = int(min(5, max(1, (sleep_hours / 8.0) * 5 + random.uniform(-1, 1))))

        # Exercise (more likely on weekends and when feeling better)
        exercise_probability = 0.3 if is_weekend else 0.15
        # More exercise when mood is better
        if day > 0 and previous_mood >= 3:
            exercise_probability += 0.2

        exercise_minutes = 0
        if random.random() < exercise_probability:
            exercise_minutes = random.uniform(20, 60)

        # Daylight exposure (more in summer, less in winter, more on weekends)
        month = current_date.month
        seasonal_factor = 1.5 if 5 <= month <= 8 else 0.7  # Summer vs winter
        base_daylight = random.uniform(60, 180) * seasonal_factor
        daylight_minutes = base_daylight if is_weekend else base_daylight * 0.6
        daylight_minutes = max(15, min(300, daylight_minutes))

        # Substance use (caffeine/alcohol - increases anxiety, decreases mood)
        # More likely on weekdays (caffeine) and weekends (alcohol)
        substance_amount = 0
        if random.random() < 0.7:  # Caffeine on weekdays
            substance_amount += random.uniform(100, 400)  # mg caffeine
        if is_weekend and random.random() < 0.4:  # Alcohol on weekends
            substance_amount += random.uniform(200, 600)  # ml alcohol

        # Calculate mood (1-5 scale)
        mood_base = baseline_mood

        # Sleep effect (previous night's sleep)
        sleep_effect = (previous_sleep - 6.0) * 0.5  # +/- based on sleep

        # Exercise effect
        exercise_effect = (exercise_minutes / 60.0) * 0.8 if exercise_minutes > 0 else 0

        # Daylight effect
        daylight_effect = (daylight_minutes / 120.0) * 0.4

        # Substance negative effect
        substance_effect = -(substance_amount / 500.0) * 0.3

        # Day of week effect (Monday blues)
        weekday_effect = -0.3 if day_of_week == 2 else 0  # Monday

        # Previous day mood momentum
        mood_momentum = (previous_mood - 3) * 0.2

        # Calculate final mood
        mood = (mood_base + med_effect + sleep_effect + exercise_effect +
                daylight_effect + substance_effect + weekday_effect +
                mood_momentum + random.uniform(-0.3, 0.3))

        mood_level = int(max(1, min(5, round(mood))))

        # Calculate anxiety (inverse relationship with many factors)
        anxiety_base = baseline_anxiety

        # Medication reduces anxiety
        anxiety_med_effect = -med_effect * 0.8

        # Poor sleep increases anxiety
        anxiety_sleep_effect = (7.0 - sleep_hours) * 0.3

        # Exercise reduces anxiety
        anxiety_exercise_effect = -(exercise_minutes / 60.0) * 0.5

        # Substances increase anxiety
        anxiety_substance_effect = (substance_amount / 500.0) * 0.5

        anxiety = (anxiety_base + anxiety_med_effect + anxiety_sleep_effect +
                   anxiety_exercise_effect + anxiety_substance_effect +
                   random.uniform(-0.4, 0.4))

        anxiety_level = int(max(0, min(4, round(anxiety))))

        # Calculate anhedonia (lack of pleasure - improves with medication)
        anhedonia_base = 2.5

        # Medication reduces anhedonia
        anhedonia_med_effect = -med_effect * 0.7

        # Exercise reduces anhedonia
        anhedonia_exercise_effect = -(exercise_minutes / 60.0) * 0.4

        # Poor sleep increases anhedonia
        anhedonia_sleep_effect = (7.0 - sleep_hours) * 0.2

        anhedonia = (anhedonia_base + anhedonia_med_effect +
                     anhedonia_exercise_effect + anhedonia_sleep_effect +
                     random.uniform(-0.3, 0.3))

        anhedonia_level = int(max(0, min(4, round(anhedonia))))

        # Store for next iteration
        previous_sleep = sleep_hours
        previous_mood = mood_level

        # Add to dataset
        data.append({
            'moodLevel': mood_level,
            'anxietyLevel': anxiety_level,
            'anhedoniaLevel': anhedonia_level,
            'sleepHours': round(sleep_hours, 1),
            'sleepQuality': sleep_quality,
            'daylightMinutes': round(daylight_minutes, 1),
            'exerciseMinutes': round(exercise_minutes, 1),
            'medicationTaken': medication_taken,
            'substanceAmount': round(substance_amount, 1),
            'dayOfWeek': day_of_week,
            'previousDaySleep': round(previous_sleep, 1) if day > 0 else 0,
            'previousDayMood': previous_mood if day > 0 else 0
        })

    return data

def save_to_csv(data, filename='neuralpath_ml_training.csv'):
    """Save data to CSV file"""
    fieldnames = ['moodLevel', 'anxietyLevel', 'anhedoniaLevel', 'sleepHours',
                  'sleepQuality', 'daylightMinutes', 'exerciseMinutes',
                  'medicationTaken', 'substanceAmount', 'dayOfWeek',
                  'previousDaySleep', 'previousDayMood']

    with open(filename, 'w', newline='') as csvfile:
        writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(data)

    print(f"✅ Generated {len(data)} days of training data")
    print(f"📁 Saved to: {filename}")

    # Print some statistics
    med_days = sum(1 for d in data if d['medicationTaken'] == 1)
    avg_mood_before = sum(d['moodLevel'] for d in data[:60]) / 60
    avg_mood_after = sum(d['moodLevel'] for d in data[90:]) / (len(data) - 90)

    print(f"\n📊 Dataset Statistics:")
    print(f"   Days on medication: {med_days}")
    print(f"   Avg mood before medication: {avg_mood_before:.2f}")
    print(f"   Avg mood after medication: {avg_mood_after:.2f}")
    print(f"   Mood improvement: {avg_mood_after - avg_mood_before:.2f}")

if __name__ == '__main__':
    print("🧠 Generating realistic mental health training data...")
    print("=" * 60)

    data = generate_realistic_data(num_days=180)
    save_to_csv(data)

    print("\n✨ Done! Use this file with Create ML to train your model.")
    print("\nKey patterns in this data:")
    print("  ✓ Medication effectiveness (starts day 60)")
    print("  ✓ Sleep-mood correlation")
    print("  ✓ Exercise benefits")
    print("  ✓ Daylight exposure benefits")
    print("  ✓ Substance effects (negative)")
    print("  ✓ Day of week patterns")
    print("  ✓ Previous day effects")
