//
//  RecordingView.swift
//  Prayerful
//
//  Created by Josiah Pederson on 10/28/24.
//

import SwiftUI
import OSLog
import AVFAudio
import SwiftData

/// View for recording a prayer
struct RecordingView: View {
	
	/// The engine for recording audio
	@State private var audioRecorder = AudioRecorder()
	
	/// Tracks iOS microphone permissions for this app
	@State private var microphonePermissionDenied = false
	
	@Environment(\.scenePhase) private var phase: ScenePhase
	
	@Bindable private var prayerThread: PrayerThread
	
	@Query private var matchingPrayerThreads: [PrayerThread]
		
	init(_ prayerThread: PrayerThread) {
		self.prayerThread = prayerThread
		let id = prayerThread.persistentModelID
		
		let predicate = #Predicate<PrayerThread> { thread in
			thread.persistentModelID == id
		}
		
		_matchingPrayerThreads = Query(filter: predicate)
	}
	
	@FocusState private var titleFocus: Bool
	
	@Environment(\.modelContext) private var modelContext
	
	@Environment(\.dismiss) private var dismiss
	
	var body: some View {
		VStack {
			if prayerThread.count > 0 {
				TextField("Name this prayer thread", text: $prayerThread.title)
					.focused($titleFocus)
					.multilineTextAlignment(.center)
					.font(.title)
			}
			if audioRecorder.recordingStatus == .stopped {
				ThreadPlaybackView(prayerThread)
			}
			Group {
				switch audioRecorder.recordingStatus {
				case .recording:
					Button {
						if let (recordingURL, duration) = audioRecorder.stopRecording() {
							// Handle the saved recording URL (e.g., add to session)
							Logger.shared.info("Recording saved at: \(recordingURL)")
							let prayer = PrayerRecording(url: recordingURL, duration: duration)
							prayerThread.addRecording(prayer)
							
							if !prayerThread.hasTitle {
								self.titleFocus = true
							}
						}
					} label: {
						Image(systemName: "square.circle.fill")
							.resizable()
					}
				case .paused:
					Button {
						audioRecorder.startRecording()
					} label: {
						Image(systemName: "waveform.circle.fill")
							.resizable()
					}
				case .stopped:
					Button {
						audioRecorder.startRecording()
					} label: {
						Image(systemName: "waveform.circle.fill")
							.resizable()
					}
					Button("Logs") {
						fileFinder.cleanUpOldRecordings()
					}
				case .error:
					Button {
						audioRecorder.recordingStatus = .stopped
					} label: {
						Image(systemName: "exclamationmark.arrow.circlepath")
							.resizable()
					}
				case .preparing:
					ProgressView()
				case .finalizing:
					ProgressView()
				}
			}
			.scaledToFit()
			.frame(width: 50)
			
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
			self.handleDisappear()
		}
		.onChange(of: phase) { oldPhase, newPhase in
			switch newPhase {
			case .background:
				Logger.shared.info("Recording paused because app entered background")
				audioRecorder.pauseRecording()
			case .active:
				do {
					try audioRecorder.activateAudioSession()
					Logger.shared.info("Recording engine reactivated because app is now active")
					
				} catch {
					let recordingError = AudioRecorderError.sessionActivationFailed(error)
					Logger.shared.error("\(recordingError.localizedDescription)")
					DispatchQueue.main.async {
						audioRecorder.recordingStatus = .error(recordingError)
					}
				}
			default:
				return
			}
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
		.toolbar {
			ToolbarItem(placement: .topBarTrailing) {
				if self.prayerThread.isEmpty {
					Button("Delete", systemImage: "trash", role: .destructive) {
						self.dismiss()
					}
				} else {
					Button("Save", systemImage: "checkmark") {
						self.save()
						self.dismiss()
					}
				}
			}
		}
	}
}

extension RecordingView {
	
	// MARK: Methods
	
	/// Saves the prayer thread to the model context
	private func save() {
		self.modelContext.insert(self.prayerThread)
	}
	
	/// Cancels and deletes the current recording
	private func cancelRecording() {
		do {
			try audioRecorder.cancelRecording()
		} catch {
			Logger.shared.error("\(error.localizedDescription)")
		}
	}
	
	/// Deletes ``PrayerThread`` recordings from file system if it was never saved to the database
	private func deleteThreadRecordingsIfNotSaved() {
		do {
			if self.matchingPrayerThreads.isEmpty {
				do {
					try self.prayerThread.deleteAllRecordingFiles()
					Logger.shared.info("This prayer thread was not found in the database. All recordings deleted")
				} catch {
					Logger.shared.error("\(error.localizedDescription)")
				}
			}
		} catch {
			Logger.shared.error("Unable to fetch threads from database: \(error.localizedDescription)")
		}
	}
	
	/// Ensures files are deleted if recording was never saved when the view disappears
	private func handleDisappear() {
		self.cancelRecording()
//		self.deleteThreadRecordingsIfNotSaved()
	}
}

#Preview {
	do {
		let previewer = try Previewer()
		
		return RecordingView(previewer.thread)
			.modelContainer(previewer.container)
	} catch {
		return Text("Failed to make container")
	}
	
}
