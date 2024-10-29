//
//  PermissionsRequester.swift
//  Prayerful
//
//  Created by Josiah Pederson on 10/28/24.
//

import Foundation
import AVFAudio

/// Requests permissions from users for access to various device systems
class PermissionsRequester {
	
	/// Requests a user's device for permission to use the microphone to record prayers
	/// - Parameter completion: The function to run when the permission request is completed.
	///
	/// >Note: The completion handler must handle both the successes and failures to obtain permission
	static func requestMicrophonePermission(completion: @escaping (Bool) -> Void) {
		AVAudioApplication.requestRecordPermission { granted in
			DispatchQueue.main.async {
				completion(granted)
			}
		}
	}
}
