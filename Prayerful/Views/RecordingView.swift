//
//  RecordingView.swift
//  Prayerful
//
//  Created by Josiah Pederson on 10/28/24.
//

import SwiftUI
import OSLog

/// View for recording a prayer
struct RecordingView: View {
	/// The engine for recording audio
	@State private var audioRecorder = AudioRecorder()
	
	/// Tracks iOS microphone permissions for this app
	@State private var microphonePermissionDenied = false
	
	var body: some View {
		VStack {
			switch audioRecorder.recordingStatus {
			case .recording:
				Text("Recording in progress")
				Button("Stop Recording") {
					if let recordingURL = audioRecorder.stopRecording() {
						// Handle the saved recording URL (e.g., add to session)
						print("Recording saved at: \(recordingURL)")
					}
				}
			case .paused:
				Text("Recording is paused")
				Button("Resume Recording") {
					audioRecorder.startRecording()
				}
			case .stopped:
				Text("No current recording")
				Button("Start Recording") {
					audioRecorder.startRecording()
				}
				Button("Clean up") {
					audioRecorder.cleanUpOldRecordings()
				}
			case .error(let error):
				Text("Recording failed: \(error.localizedDescription)")
				Button("Try again") {
					audioRecorder.recordingStatus = .stopped
				}
			case .preparing:
				Text("Preparing to record")
				ProgressView()
			case .finalizing:
				Text("Finalizing recording")
				ProgressView()
			}
		}
		.padding()
		.animation(.easeIn, value: audioRecorder.recordingStatus)
		.onAppear {
			// Request microphone permission when the view appears
			PermissionsRequester.requestMicrophonePermission { granted in
				if !granted {
					Logger.shared.error("Microphone access not granted")
					self.microphonePermissionDenied = true
				}
			}
		}
		.onDisappear {
			// This may need to be stopRecording
			audioRecorder.pauseRecording()
		}
		.alert(isPresented: $microphonePermissionDenied) {
			// Show an alert where the user can go to settings to enable microphone access
			Alert(
				title: Text("Microphone Permission Needed"),
				message: Text("Please enable microphone access in Settings to record audio."),
				primaryButton: .default(Text("Open Settings")) {
					if let appSettings = URL(string: UIApplication.openSettingsURLString) {
						UIApplication.shared.open(appSettings)
					}
				},
				secondaryButton: .cancel()
			)
		}
	}
}

#Preview {
	RecordingView()
}
