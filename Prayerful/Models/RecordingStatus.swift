//
//  RecordingStatus.swift
//  Prayerful
//
//  Created by Josiah Pederson on 10/29/24.
//

import Foundation

/// Tracks the status of an audio recorder
enum RecordingStatus: Equatable {
	case stopped
	case recording
	case paused
	case preparing
	case finalizing
	case error(Error)

	static func == (lhs: RecordingStatus, rhs: RecordingStatus) -> Bool {
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
