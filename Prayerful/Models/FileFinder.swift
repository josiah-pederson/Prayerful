//
//  FileFinder.swift
//  Prayerful
//
//  Created by Josiah Pederson on 11/3/24.
//

import Foundation

class FileFinder {
	
	/// Acquires the system directory to save recordings.
	///
	/// - Returns: A URL pointing to the app's documents directory.
	static var documentsDirectory: URL {
		FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
	}
	
	static var prayersDirectory: URL {
		documentsDirectory.appendingPathComponent("prayers")
	}
}
