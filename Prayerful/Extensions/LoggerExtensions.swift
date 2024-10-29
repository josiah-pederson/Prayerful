//
//  LoggerExtensions.swift
//  Prayerful
//
//  Created by Josiah Pederson on 10/28/24.
//

import OSLog

extension Logger {
	/// A lightweight logger accessable to the app
	static let shared = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "shared")
}
