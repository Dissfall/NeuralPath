import SwiftUI

struct PhysicalHealthStep: View {
    @Bindable var viewModel: StepperEntryViewModel
    @FocusState private var focusedField: Field?

    enum Field: Hashable {
        case sleepHours
        case exerciseMinutes
        case daylightMinutes
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Sleep Section
                StepSectionCard(title: "Sleep", icon: "moon.zzz.fill", color: .indigo) {
                    VStack(spacing: 16) {
                        HStack {
                            Text("Hours")
                            Spacer()
                            TextField("0.0", text: $viewModel.sleepHours)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
                                .focused($focusedField, equals: .sleepHours)
                            Text("hrs")
                                .foregroundStyle(.secondary)
                        }

                        Divider()

                        HStack {
                            Text("Quality")
                            Spacer()
                            if let rating = viewModel.sleepQualityRating {
                                ForEach(1...5, id: \.self) { star in
                                    Image(systemName: star <= rating ? "star.fill" : "star")
                                        .foregroundStyle(star <= rating ? .yellow : .gray)
                                        .onTapGesture {
                                            viewModel.sleepQualityRating = star
                                        }
                                }
                            } else {
                                Button("Add Rating") {
                                    viewModel.sleepQualityRating = 3
                                }
                                .font(.subheadline)
                            }
                        }
                    }
                }

                // Exercise Section
                StepSectionCard(title: "Exercise", icon: "figure.run", color: .green) {
                    HStack {
                        Text("Duration")
                        Spacer()
                        TextField("0", text: $viewModel.exerciseMinutes)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                            .focused($focusedField, equals: .exerciseMinutes)
                        Text("min")
                            .foregroundStyle(.secondary)
                    }
                }

                // Daylight Section
                StepSectionCard(title: "Daylight", icon: "sun.max.fill", color: .orange) {
                    HStack {
                        Text("Time Outdoors")
                        Spacer()
                        TextField("0", text: $viewModel.timeInDaylightMinutes)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                            .focused($focusedField, equals: .daylightMinutes)
                        Text("min")
                            .foregroundStyle(.secondary)
                    }
                }

                // HealthKit Loading Indicator
                if viewModel.isLoadingHealthData {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Loading data from Apple Health...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                }
            }
            .padding()
        }
        .scrollDismissesKeyboard(.interactively)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    focusedField = nil
                }
            }
        }
        .onChange(of: viewModel.currentStep) { _, _ in
            focusedField = nil
        }
    }
}

#Preview {
    PhysicalHealthStep(viewModel: StepperEntryViewModel())
}
