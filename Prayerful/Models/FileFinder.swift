//
//  FileFinder.swift
//  Prayerful
//
//  Created by Josiah Pederson on 11/3/24.
//

import Foundation
import OSLog

let fileFinder = FileFinder.shared

class FileFinder {
	
	/// Shared instance
	static var shared: FileFinder = .init()
	
	/// File manager
	private var manager = FileManager.default
		
	init() {
		self.createDirectory(at: self.prayersDirectory)
	}
	
	/// Acquires the system directory to save prayers
	var prayersDirectory: URL {
		self.documentsDirectory.appendingPathComponent("Prayers")
	}
	
	/// Acquires the system directory for documents
	private var documentsDirectory: URL {
		FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
	}
	
	/// Searches filesystem for file at specified URL
	/// - Parameter url: The url at which to find the file
	/// - Returns: Whether the file is in the system or not
	func fileExists(at url: URL) -> Bool {
		FileManager.default.fileExists(atPath: url.path)
	}
	
	/// Creates a directory at the given url if it does not already exist
	/// - Parameter url: The url at which to create the directory
	///
	/// - Warning: If the directory creation process fails the entire app crashes with a fatal error
	private func createDirectory(at url: URL) {
		do {
			if !manager.fileExists(atPath: url.relativePath) {
				try manager.createDirectory(
					at: url,
					withIntermediateDirectories: false,
					attributes: nil
				)
				Logger.shared.debug("Created directory at \(self.prayersDirectory.path)")
			} else {
				Logger.shared.debug("Directory at \(self.prayersDirectory.path) already exists")
			}
		} catch {
			Logger.shared.error("Unable to create directory at \(self.prayersDirectory.path) with error: \(error)")
			fatalError(error.localizedDescription)
		}
	}
}
