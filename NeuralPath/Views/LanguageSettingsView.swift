//
//  LanguageSettingsView.swift
//  NeuralPath
//
//  Language selection view for Settings

import SwiftUI

struct LanguageSettingsView: View {
    var languageManager = LanguageManager.shared
    @State private var showRestartAlert = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            Section {
                ForEach(LanguageManager.AppLanguage.allCases) { language in
                    Button {
                        if languageManager.selectLanguage(language) {
                            showRestartAlert = true
                        }
                    } label: {
                        HStack(spacing: 12) {
                            if language.isSystemFlag {
                                Image(systemName: language.flagImageName)
                                    .font(.title2)
                                    .foregroundStyle(.secondary)
                                    .frame(width: 28, height: 20)
                            } else {
                                Image(language.flagImageName)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 28, height: 20)
                                    .clipShape(RoundedRectangle(cornerRadius: 2))
                            }

                            Text(language.displayName)
                                .foregroundStyle(.primary)

                            Spacer()

                            if languageManager.currentLanguage == language {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                }
            } footer: {
                Text("The app will restart to apply the new language.")
                    .font(.caption)
            }
        }
        .navigationTitle("Language")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Restart Required", isPresented: $showRestartAlert) {
            Button("Restart Now") {
                exit(0)
            }
            Button("Later", role: .cancel) {
                dismiss()
            }
        } message: {
            Text("Please restart the app for the language change to take effect.")
        }
    }
}

#Preview {
    NavigationStack {
        LanguageSettingsView()
    }
}
