//
//  PrivacyRequester.swift
//  Prayerful
//
//  Created by Josiah Pederson on 10/28/24.
//

import Foundation
import AVFoundation

func requestMicrophonePermission(completion: @escaping (Bool) -> Void) {
	AVAudioApplication.
	AVAudioSession.sharedInstance().requestRecordPermission { granted in
		DispatchQueue.main.async {
			completion(granted)
		}
	}
}
