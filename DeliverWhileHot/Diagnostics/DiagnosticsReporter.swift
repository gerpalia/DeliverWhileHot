//
//  DiagnosticsReporter.swift
//  DeliverWhileHot
//
//  Lightweight, opt-in diagnostics for prototype builds. No endpoint is
//  bundled with the app and no event is sent unless the developer supplies
//  DELIVER_WHILE_HOT_MONITORING_ENDPOINT at launch time.
//

import Foundation
import OSLog

final class DiagnosticsReporter {
    static let shared = DiagnosticsReporter()

    private let logger = Logger(subsystem: "com.deliverwhilehot.app", category: "diagnostics")
    private let session: URLSession
    private let encoder = JSONEncoder()
    private let endpoint: URL?

    private init(environment: [String: String] = ProcessInfo.processInfo.environment) {
        endpoint = environment["DELIVER_WHILE_HOT_MONITORING_ENDPOINT"].flatMap(URL.init(string:))
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 5
        configuration.timeoutIntervalForResource = 5
        session = URLSession(configuration: configuration)
    }

    func start() {
        logger.info("Diagnostics ready. Remote reporting is \(self.endpoint == nil ? "disabled" : "enabled")")
        record("app_launched")
    }

    func record(_ event: String, metadata: [String: String] = [:]) {
        let payload = EventPayload(
            event: event,
            appVersion: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown",
            osVersion: ProcessInfo.processInfo.operatingSystemVersionString,
            metadata: metadata
        )
        logger.debug("event=\(event, privacy: .public)")

        guard let endpoint else { return }
        guard let body = try? encoder.encode(payload) else { return }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        session.dataTask(with: request) { [logger] _, response, error in
            if let error {
                logger.error("Remote diagnostics failed: \(error.localizedDescription, privacy: .public)")
                return
            }
            if let statusCode = (response as? HTTPURLResponse)?.statusCode,
               !(200..<300).contains(statusCode) {
                logger.error("Remote diagnostics returned HTTP \(statusCode, privacy: .public)")
            }
        }.resume()
    }

    private struct EventPayload: Encodable {
        let event: String
        let appVersion: String
        let osVersion: String
        let metadata: [String: String]
    }
}
