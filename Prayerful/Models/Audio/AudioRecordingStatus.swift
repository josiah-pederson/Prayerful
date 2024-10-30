//
//  RecordingStatus.swift
//  Prayerful
//
//  Created by Josiah Pederson on 10/29/24.
//

import Foundation

/// Tracks the status of an audio recorder
enum AudioRecordingStatus {
	case stopped
	case recording
	case paused
	case preparing
	case finalizing
	case error(Error)
}

extension AudioRecordingStatus: Equatable {
	
	// MARK: - Equatable conformance
	
	/// Compares two instances of Self to determine if they are equal
	/// - Parameters:
	///   - lhs: The first (left hand side) AudioRecordingStatus to compare
	///   - rhs: The second (right hand side) AudioRecordingStatus to compare
	/// - Returns: A boolean indicating if they are the same or not
	static func == (lhs: Self, rhs: Self) -> Bool {
		switch (lhs, rhs) {
		case (.recording, .recording), (.stopped, .stopped), (.paused, .paused), (.preparing, .preparing), (.finalizing, .finalizing):
			return true
		case (.error(let lError), .error(let rError)):
			return lError.localizedDescription == rError.localizedDescription
		default:
			return false
		}
	}
}
