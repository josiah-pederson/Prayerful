//
//  RecordingView.swift
//  Prayerful
//
//  Created by Josiah Pederson on 10/28/24.
//

import SwiftUI
import OSLog

struct RecordingView: View {
	@StateObject private var audioRecorder = AudioRecorder()
	
	var body: some View {
		VStack {
			if audioRecorder.isRecording {
				Button(action: {
					if let recordingURL = audioRecorder.stopRecording() {
						// Handle the saved recording URL (e.g., add to session)
						print("Recording saved at: \(recordingURL)")
					}
				}) {
					Text("Stop Recording")
				}
			} else {
				Button(action: {
					audioRecorder.startRecording()
				}) {
					Text("Start Recording")
				}
			}
		}
		.padding()
		.onAppear {
			// Request microphone permission when the view appears
			PermissionsRequester.requestMicrophonePermission { granted in
				if !granted {
					Logger.shared.error("Microphone access not granted")
				}
			}
		}
	}
}

#Preview {
	RecordingView()
}
