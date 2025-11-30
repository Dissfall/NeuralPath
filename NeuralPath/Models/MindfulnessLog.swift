//
//  MindfulnessLog.swift
//  NeuralPath
//

import Foundation
import SwiftData

@Model
final class MindfulnessLog {
    var id: UUID?

    var userMindfulness: UserMindfulness?

    var practiceName: String?
    var timestamp: Date?
    var notes: String?

    init(
        id: UUID? = UUID(),
        userMindfulness: UserMindfulness? = nil,
        practiceName: String? = "",
        timestamp: Date? = Date(),
        notes: String? = ""
    ) {
        self.id = id
        self.userMindfulness = userMindfulness
        self.practiceName = practiceName
        self.timestamp = timestamp
        self.notes = notes
    }
}
