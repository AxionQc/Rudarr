import os
import SwiftUI

class Notifications {
    static let shared: Notifications = Notifications()
    static let url = "https://notify.ruddarr.com"

    private let center: UNUserNotificationCenter
    private let log: Logger

    init() {
        center = UNUserNotificationCenter.current()
        log = logger("notifications")
    }

    func requestAuthorization() async {
        do {
            try await center.requestAuthorization(options: [.alert, .sound])
        } catch {
            log.warning("Failed to obtain user notifications authorization: \(error.localizedDescription)")
        }
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        let settings = await center.notificationSettings()

        return settings.authorizationStatus
    }
}

struct InstanceNotification: Identifiable, Codable {
    let id: Int
    let name: String?

    var implementation: String = "Webhook"
    var configContract: String = "WebhookSettings"

    var fields: [InstanceNotificationField] = []

    var onGrab: Bool = false
    var onDownload: Bool = false
    var onUpgrade: Bool = false
    var onMovieAdded: Bool = false
    var onHealthIssue: Bool = false
    var onHealthRestored: Bool = false
    var onApplicationUpdate: Bool = false
    // var onManualInteractionRequired: Bool = false

    var isEnabled: Bool {
        onGrab
        || onDownload
        || onUpgrade
        || onMovieAdded
        || onHealthIssue
        || onHealthRestored
        || onApplicationUpdate
    }

    mutating func disable() {
        onGrab = false
        onDownload = false
        onUpgrade = false
        onMovieAdded = false
        onHealthIssue = false
        onHealthRestored = false
        onApplicationUpdate = false
    }
}

struct InstanceNotificationField: Codable {
    let name: String
    var value: String = ""

    enum CodingKeys: String, CodingKey {
        case name
        case value
    }

    init(name: String, value: String) {
        self.name = name
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        name = try container.decode(String.self, forKey: .name)

        if let string = try? container.decode(String.self, forKey: .value) {
            value = string
        }
    }
}
