import SwiftUI
import SwiftData

struct StepperEntryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // SwiftData queries
    @Query private var allEntries: [SymptomEntry]
    @Query(
        filter: #Predicate<UserMedication> { $0.isActive == true },
        sort: \UserMedication.name
    ) private var userMedications: [UserMedication]
    @Query(
        filter: #Predicate<UserSubstance> { $0.isActive == true },
        sort: \UserSubstance.name
    ) private var userSubstances: [UserSubstance]
    @Query(
        filter: #Predicate<UserMindfulness> { $0.isActive == true },
        sort: \UserMindfulness.name
    ) private var userMindfulness: [UserMindfulness]
    @Query(
        filter: #Predicate<UserSelfCare> { $0.isActive == true },
        sort: \UserSelfCare.name
    ) private var userSelfCare: [UserSelfCare]
    @Query(sort: \MedicationLog.timestamp, order: .forward) private var allMedicationLogs: [MedicationLog]
    @Query(sort: \SubstanceLog.timestamp, order: .forward) private var allSubstanceLogs: [SubstanceLog]
    @Query(sort: \MindfulnessLog.timestamp, order: .forward) private var allMindfulnessLogs: [MindfulnessLog]
    @Query(sort: \SelfCareLog.timestamp, order: .forward) private var allSelfCareLogs: [SelfCareLog]

    @State private var viewModel: StepperEntryViewModel
    @State private var showingDiscardAlert = false

    private let healthKitManager = HealthKitManager.shared

    init(entryToEdit: SymptomEntry? = nil) {
        _viewModel = State(initialValue: StepperEntryViewModel(entryToEdit: entryToEdit))
    }

    var body: some View {
        navigationContent
            .modifier(EntryAlertsModifier(
                showingDiscardAlert: $showingDiscardAlert,
                showingDuplicateAlert: $viewModel.showingDuplicateAlert,
                showEarlyMorningAlert: $viewModel.showEarlyMorningAlert,
                onDiscard: { dismiss() },
                onUseYesterday: { viewModel.useYesterdayDate() }
            ))
            .modifier(EntrySheetsModifier(
                viewModel: viewModel,
                medicationToEditTime: $viewModel.medicationToEditTime,
                substanceToEditTime: $viewModel.substanceToEditTime,
                mindfulnessToEditTime: $viewModel.mindfulnessToEditTime,
                selfCareToEditTime: $viewModel.selfCareToEditTime,
                showingHealthKitImport: $viewModel.showingHealthKitImport
            ))
            .modifier(SubstanceAlertsModifier(
                substanceToEditAmount: $viewModel.substanceToEditAmount,
                substanceToAdd: $viewModel.substanceToAdd,
                editSubstanceAmount: $viewModel.editSubstanceAmount,
                newSubstanceAmount: $viewModel.newSubstanceAmount,
                onSaveAmount: { entry, amount in viewModel.updateSubstanceAmount(entry, amount: amount) },
                onAddSubstance: { substance, amount in viewModel.addSubstance(substance, amount: amount) }
            ))
    }

    private var navigationContent: some View {
        NavigationStack {
            mainContent
                .navigationTitle(viewModel.isEditMode ? "Edit Entry" : "New Entry")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { toolbarContent }
                .task { await loadInitialData() }
                .onChange(of: viewModel.selectedDate) { _, _ in
                    viewModel.loadLogsForDate()
                    Task { await viewModel.loadHealthKitData() }
                }
                .interactiveDismissDisabled(viewModel.hasUnsavedChanges)
        }
    }

    // MARK: - Main Content

    @ViewBuilder
    private var mainContent: some View {
        VStack(spacing: 0) {
            StepProgressIndicator(
                currentStep: viewModel.currentStep,
                allowTapping: true,
                onStepTap: { viewModel.goToStep($0) }
            )
            .padding(.horizontal, 24)
            .padding(.top, 16)

            EntryDateSelector(
                selectedDate: $viewModel.selectedDate,
                hasEntryForSelectedDate: viewModel.hasEntryForSelectedDate
            )
            .padding(.horizontal)
            .padding(.top, 12)

            if viewModel.showNotEndOfDayBanner {
                TimeWarningBanner(
                    onDismiss: { viewModel.showNotEndOfDayBanner = false },
                    onNeverShow: { viewModel.setNeverShowTimeWarning() }
                )
                .padding(.horizontal)
                .padding(.top, 8)
            }

            stepTabView

            navigationButtons
                .padding(.horizontal)
                .padding(.bottom, 8)
        }
    }

    @ViewBuilder
    private var stepTabView: some View {
        TabView(selection: $viewModel.currentStep) {
            CoreFeelingsStep(viewModel: viewModel)
                .tag(EntryStep.coreFeelings)
            PhysicalHealthStep(viewModel: viewModel)
                .tag(EntryStep.physicalHealth)
            MedicationsStep(viewModel: viewModel)
                .tag(EntryStep.medications)
            WellnessStep(viewModel: viewModel)
                .tag(EntryStep.wellness)
            ReviewStep(viewModel: viewModel)
                .tag(EntryStep.review)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .animation(.easeInOut(duration: 0.3), value: viewModel.currentStep)
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") {
                if viewModel.hasUnsavedChanges {
                    showingDiscardAlert = true
                } else {
                    dismiss()
                }
            }
        }
    }

    // MARK: - Navigation Buttons

    @ViewBuilder
    private var navigationButtons: some View {
        HStack(spacing: 12) {
            if viewModel.currentStep != .coreFeelings {
                backButton
            }
            if viewModel.currentStep == .review {
                saveButton
            } else {
                nextButton
            }
        }
    }

    private var backButton: some View {
        Button { viewModel.previousStep() } label: {
            HStack {
                Image(systemName: "chevron.left")
                Text("Back")
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color(.secondarySystemBackground))
            .foregroundStyle(.primary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var nextButton: some View {
        Button { viewModel.nextStep() } label: {
            HStack {
                Text("Next")
                Image(systemName: "chevron.right")
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.blue)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var saveButton: some View {
        Button { saveEntry() } label: {
            Text(viewModel.isEditMode ? "Update Entry" : "Save Entry")
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.blue)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Data Loading

    private func loadInitialData() async {
        viewModel.setModelContext(modelContext)
        viewModel.userMedications = userMedications
        viewModel.userSubstances = userSubstances
        viewModel.userMindfulness = userMindfulness
        viewModel.userSelfCare = userSelfCare
        viewModel.allEntries = allEntries
        viewModel.allMedicationLogs = allMedicationLogs
        viewModel.allSubstanceLogs = allSubstanceLogs
        viewModel.allMindfulnessLogs = allMindfulnessLogs
        viewModel.allSelfCareLogs = allSelfCareLogs

        if let entry = viewModel.entryToEdit {
            viewModel.loadEntryData(entry)
        } else {
            viewModel.checkTimeAndShowWarnings()
            viewModel.loadLogsForDate()
            await viewModel.loadHealthKitData()
        }
    }

    private func saveEntry() {
        do {
            try viewModel.saveEntry()
            dismiss()
        } catch {
            // Error is handled by the duplicate alert
        }
    }
}

// MARK: - Entry Date Selector

struct EntryDateSelector: View {
    @Binding var selectedDate: Date
    let hasEntryForSelectedDate: Bool

    var body: some View {
        VStack(spacing: 8) {
            DatePicker(
                "Entry Date",
                selection: $selectedDate,
                in: ...Date(),
                displayedComponents: [.date]
            )
            .datePickerStyle(.compact)

            if hasEntryForSelectedDate {
                warningBanner
            }
        }
    }

    private var warningBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            Text("Entry already exists for this date")
                .font(.caption)
                .foregroundStyle(.orange)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    StepperEntryView()
        .modelContainer(for: [SymptomEntry.self, UserMedication.self], inMemory: true)
}

// MARK: - Entry Alerts Modifier

private struct EntryAlertsModifier: ViewModifier {
    @Binding var showingDiscardAlert: Bool
    @Binding var showingDuplicateAlert: Bool
    @Binding var showEarlyMorningAlert: Bool
    let onDiscard: () -> Void
    let onUseYesterday: () -> Void

    func body(content: Content) -> some View {
        content
            .confirmationDialog("Discard Changes?", isPresented: $showingDiscardAlert, titleVisibility: .visible) {
                Button("Discard", role: .destructive) { onDiscard() }
                Button("Keep Editing", role: .cancel) {}
            } message: {
                Text("You have unsaved changes that will be lost.")
            }
            .alert("Entry Exists", isPresented: $showingDuplicateAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("An entry already exists for this date. Please select a different date or edit the existing entry.")
            }
            .alert("Log for Yesterday?", isPresented: $showEarlyMorningAlert) {
                Button("Yes, use yesterday") { onUseYesterday() }
                Button("No, use today", role: .cancel) {}
            } message: {
                Text("It's early morning. Would you like to log this entry for yesterday instead?")
            }
    }
}

// MARK: - Entry Sheets Modifier

private struct EntrySheetsModifier: ViewModifier {
    let viewModel: StepperEntryViewModel
    @Binding var medicationToEditTime: UserMedication?
    @Binding var substanceToEditTime: SubstanceEntry?
    @Binding var mindfulnessToEditTime: MindfulnessLogEntry?
    @Binding var selfCareToEditTime: SelfCareLogEntry?
    @Binding var showingHealthKitImport: Bool

    func body(content: Content) -> some View {
        content
            .sheet(item: $medicationToEditTime) { medication in
                medicationEditSheet(medication)
            }
            .sheet(item: $substanceToEditTime) { entry in
                substanceTimeEditSheet(entry)
            }
            .sheet(item: $mindfulnessToEditTime) { entry in
                mindfulnessEditSheet(entry)
            }
            .sheet(item: $selfCareToEditTime) { entry in
                selfCareEditSheet(entry)
            }
            .sheet(isPresented: $showingHealthKitImport) {
                HealthKitImportView { _ in
                    showingHealthKitImport = false
                }
            }
    }

    private func medicationEditSheet(_ medication: UserMedication) -> some View {
        EntryEditTimeSheet(
            title: "Edit Time",
            subtitle: medication.name ?? "Medication",
            time: .init(
                get: { viewModel.editMedicationTime },
                set: { viewModel.editMedicationTime = $0 }
            ),
            onSave: {
                viewModel.updateMedicationTime(medication, time: viewModel.editMedicationTime)
                medicationToEditTime = nil
            },
            onCancel: { medicationToEditTime = nil }
        )
    }

    private func substanceTimeEditSheet(_ entry: SubstanceEntry) -> some View {
        let name = viewModel.userSubstances.first { $0.id == entry.userSubstanceId }?.name ?? "Substance"
        return EntryEditTimeSheet(
            title: "Edit Time",
            subtitle: name,
            time: .init(
                get: { viewModel.editSubstanceTime },
                set: { viewModel.editSubstanceTime = $0 }
            ),
            onSave: {
                viewModel.updateSubstanceTime(entry, time: viewModel.editSubstanceTime)
                substanceToEditTime = nil
            },
            onCancel: { substanceToEditTime = nil }
        )
    }

    private func mindfulnessEditSheet(_ entry: MindfulnessLogEntry) -> some View {
        let name = viewModel.userMindfulness.first { $0.id == entry.userMindfulnessId }?.name ?? "Practice"
        return EntryEditTimeSheet(
            title: "Edit Time",
            subtitle: name,
            time: .init(
                get: { viewModel.editMindfulnessTime },
                set: { viewModel.editMindfulnessTime = $0 }
            ),
            onSave: {
                viewModel.updateMindfulnessTime(entry, time: viewModel.editMindfulnessTime)
                mindfulnessToEditTime = nil
            },
            onCancel: { mindfulnessToEditTime = nil }
        )
    }

    private func selfCareEditSheet(_ entry: SelfCareLogEntry) -> some View {
        let name = viewModel.userSelfCare.first { $0.id == entry.userSelfCareId }?.name ?? "Practice"
        return EntryEditTimeSheet(
            title: "Edit Time",
            subtitle: name,
            time: .init(
                get: { viewModel.editSelfCareTime },
                set: { viewModel.editSelfCareTime = $0 }
            ),
            onSave: {
                viewModel.updateSelfCareTime(entry, time: viewModel.editSelfCareTime)
                selfCareToEditTime = nil
            },
            onCancel: { selfCareToEditTime = nil }
        )
    }
}

// MARK: - Substance Alerts Modifier

private struct SubstanceAlertsModifier: ViewModifier {
    @Binding var substanceToEditAmount: SubstanceEntry?
    @Binding var substanceToAdd: UserSubstance?
    @Binding var editSubstanceAmount: String
    @Binding var newSubstanceAmount: String
    let onSaveAmount: (SubstanceEntry, String) -> Void
    let onAddSubstance: (UserSubstance, String) -> Void

    func body(content: Content) -> some View {
        content
            .alert("Edit Amount", isPresented: editAmountBinding) {
                TextField("Amount", text: $editSubstanceAmount)
                    .keyboardType(.decimalPad)
                Button("Save") {
                    if let entry = substanceToEditAmount {
                        onSaveAmount(entry, editSubstanceAmount)
                    }
                    substanceToEditAmount = nil
                }
                Button("Cancel", role: .cancel) {
                    substanceToEditAmount = nil
                }
            }
            .alert("Add Substance", isPresented: addSubstanceBinding) {
                TextField("Amount", text: $newSubstanceAmount)
                    .keyboardType(.decimalPad)
                Button("Add") {
                    if let substance = substanceToAdd {
                        onAddSubstance(substance, newSubstanceAmount)
                    }
                    substanceToAdd = nil
                }
                Button("Cancel", role: .cancel) {
                    substanceToAdd = nil
                }
            } message: {
                if let substance = substanceToAdd {
                    Text("Enter amount for \(substance.name ?? "substance")")
                }
            }
    }

    private var editAmountBinding: Binding<Bool> {
        Binding(
            get: { substanceToEditAmount != nil },
            set: { if !$0 { substanceToEditAmount = nil } }
        )
    }

    private var addSubstanceBinding: Binding<Bool> {
        Binding(
            get: { substanceToAdd != nil },
            set: { if !$0 { substanceToAdd = nil } }
        )
    }
}
