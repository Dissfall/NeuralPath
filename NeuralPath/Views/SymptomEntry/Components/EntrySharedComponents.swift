import SwiftUI

// MARK: - Substance Amount (for QuickLogSubstanceView)

struct SubstanceAmount {
    var amount: String
    var unit: SubstanceUnit
    var timestamp: Date
}

// MARK: - Entry Edit Time Sheet

struct EntryEditTimeSheet: View {
    let title: String
    let subtitle: String
    @Binding var time: Date
    let onSave: () -> Void
    let onCancel: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("Time", selection: $time, displayedComponents: [.hourAndMinute])
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: onSave)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Time Warning Banner

struct TimeWarningBanner: View {
    let onDismiss: () -> Void
    let onNeverShow: () -> Void

    @State private var neverShowChecked = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(.blue)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Best time to log")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Text("We recommend logging entries at the end of the day for more accurate reflections on your mood and symptoms.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }

            Toggle(isOn: $neverShowChecked) {
                Text("Don't remind me again")
                    .font(.caption)
            }
            .toggleStyle(.checkboxStyle)
            .onChange(of: neverShowChecked) { _, newValue in
                if newValue {
                    onNeverShow()
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Checkbox Toggle Style

struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            HStack {
                Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                    .foregroundStyle(configuration.isOn ? .blue : .secondary)
                configuration.label
            }
        }
        .buttonStyle(.plain)
    }
}

extension ToggleStyle where Self == CheckboxToggleStyle {
    static var checkboxStyle: CheckboxToggleStyle { CheckboxToggleStyle() }
}
