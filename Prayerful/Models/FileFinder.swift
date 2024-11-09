//
//  FileFinder.swift
//  Prayerful
//
//  Created by Josiah Pederson on 11/3/24.
//

import Foundation
import OSLog

let fileFinder = FileFinder.shared

/// Ensures recordings are saved to the correct folders
///
/// The absolute filepath to the documents folder changes from time to time and this ensures that relative paths are combined correctly with absolute base urls
class FileFinder {
	
	/// Shared instance
	static var shared: FileFinder = .init()
	
	/// File manager
	var manager = FileManager.default
	
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
	
	/// Returns the full url for a prayer's relative url
	/// - Parameter path: The relative path from the prayers folder
	/// - Returns: The full url
	func prayerURL(forRelativePath path: String) -> URL {
		self.prayersDirectory.appendingPathComponent(path)
	}
}

extension FileFinder {
	
	// MARK: Filesystem mutation operations
	
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
	
	/// Creates a file URL for a new recording in the Prayers directory.
	///
	/// - Returns: A unique file URL for saving the new recording.
	func createRecordingURL() -> URL {
		// Create a unique filename using the current date and time.
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
		let dateString = dateFormatter.string(from: Date())
		let fileName = "Recording_\(dateString)"
		let directory = self.prayersDirectory
		let recordingURL = URL(fileURLWithPath: fileName, relativeTo: directory).appendingPathExtension("m4a")
		return recordingURL
	}
	
	/// Deletes all audio recordings in the app's documents directory.
	///
	/// This method iterates through all files in the app's documents directory and removes those that match the audio file naming convention used by the `AudioRecorder` class.
	///
	/// - Warning: This operation cannot be undone, so use it carefully.
	func cleanUpOldRecordings() {
		
		do {
			// Get all files in the prayers directory
			let files = try manager.contentsOfDirectory(at: prayersDirectory, includingPropertiesForKeys: nil)
			
			for file in files {
				// Only delete files that match the "Recording_" prefix and ".m4a" extension.
				if file.lastPathComponent.hasPrefix("Recording_") && file.pathExtension == "m4a" {
					do {
						try manager.removeItem(at: file)
						Logger.shared.info("Deleted recording: \(file.lastPathComponent)")
					} catch {
						Logger.shared.error("Failed to delete recording \(file.lastPathComponent): \(error.localizedDescription)")
					}
				}
			}
		} catch {
			Logger.shared.error("Failed to access recordings directory: \(error.localizedDescription)")
		}
	}
}
