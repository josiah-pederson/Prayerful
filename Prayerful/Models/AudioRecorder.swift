//
//  AudioRecorder.swift
//  Prayerful
//
//  Created by Josiah Pederson on 10/28/24.
//

import Foundation
import AVFoundation

class AudioRecorder: ObservableObject {
	private var audioRecorder: AVAudioRecorder?
	private(set) var isRecording = false
	
	// Directory to save recordings
	private func getDocumentsDirectory() -> URL {
		FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
	}

	// Create a file URL for a new recording
	private func getNewRecordingURL() -> URL {
		let fileName = UUID().uuidString + ".m4a"
		return getDocumentsDirectory().appendingPathComponent(fileName)
	}

	// Start recording
	func startRecording() {
		let audioFilename = getNewRecordingURL()

		let settings: [String: Any] = [
			AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
			AVSampleRateKey: 12000,
			AVNumberOfChannelsKey: 1,
			AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
		]

		do {
			audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
			audioRecorder?.record()
			isRecording = true
		} catch {
			print("Could not start recording: \(error.localizedDescription)")
		}
	}

	// Stop recording and return the recording URL
	func stopRecording() -> URL? {
		audioRecorder?.stop()
		isRecording = false
		return audioRecorder?.url
	}
}
