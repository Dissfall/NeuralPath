//
//  LanguageManager.swift
//  NeuralPath
//
//  Manages app language preferences and override

import Foundation
import SwiftUI

@Observable
final class LanguageManager {
    static let shared = LanguageManager()

    enum AppLanguage: String, CaseIterable, Identifiable {
        case system = "system"
        case english = "en"
        case belarusian = "be"
        case ukrainian = "uk"

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .system: return String(localized: "System Default")
            case .english: return "English"
            case .belarusian: return "Беларуская"
            case .ukrainian: return "Українська"
            }
        }

        var flagImageName: String {
            switch self {
            case .system: return "globe"
            case .english: return "flag_en"
            case .belarusian: return "flag_be"
            case .ukrainian: return "flag_uk"
            }
        }

        var isSystemFlag: Bool {
            self == .system
        }
    }

    private let languageKey = "appLanguage"

    var currentLanguage: AppLanguage {
        didSet {
            guard currentLanguage != oldValue else { return }
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: languageKey)
            applyLanguage()
        }
    }

    var needsRestart: Bool = false

    private init() {
        let savedValue = UserDefaults.standard.string(forKey: languageKey) ?? "system"
        self.currentLanguage = AppLanguage(rawValue: savedValue) ?? .system
    }

    private func applyLanguage() {
        if currentLanguage == .system {
            UserDefaults.standard.removeObject(forKey: "AppleLanguages")
        } else {
            UserDefaults.standard.set([currentLanguage.rawValue], forKey: "AppleLanguages")
        }
        UserDefaults.standard.synchronize()
        needsRestart = true
    }

    func selectLanguage(_ language: AppLanguage) -> Bool {
        guard language != currentLanguage else { return false }
        currentLanguage = language
        return true
    }

    var effectiveLanguageCode: String {
        if currentLanguage == .system {
            return Locale.current.language.languageCode?.identifier ?? "en"
        }
        return currentLanguage.rawValue
    }
}
