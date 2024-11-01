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
	
	@Environment(\.scenePhase) var phase: ScenePhase
	
	@Bindable private var prayerThread: PrayerThread
	
	init(prayerThread: PrayerThread) {
		self.prayerThread = prayerThread
	}
	
	@FocusState private var titleFocus: Bool
	
	var body: some View {
		VStack {
			if prayerThread.count > 0 {
				TextField("Prayer thread title", text: $prayerThread.title)
					.focused($titleFocus)
					.multilineTextAlignment(.center)
					.font(.title)
			}
			
			// This probably won't be used here, it is just a concept
			if prayerThread.count > 0 {
				GeometryReader { geo in
					HStack {
						ForEach(prayerThread.recordings) { prayer in
							let durationPercentage = prayer.duration / prayerThread.duration
							let width = durationPercentage * geo.size.width
							RoundedRectangle(cornerRadius: 3)
								.padding(3)
								.frame(maxWidth: width)
						}
					}
				}
				.frame(maxWidth: .infinity, maxHeight: 30)
				
			}
			Text(audioRecorder.recordingStatus.description)
			Group {
				switch audioRecorder.recordingStatus {
				case .recording:
					Button {
						if let (recordingURL, duration) = audioRecorder.stopRecording() {
							// Handle the saved recording URL (e.g., add to session)
							Logger.shared.info("Recording saved at: \(recordingURL)")
							let prayer = PrayerRecording(filePath: recordingURL, duration: duration)
							prayerThread.recordings.append(prayer)
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
						audioRecorder.cleanUpOldRecordings()
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
			// This may need to be stopRecording
			audioRecorder.pauseRecording()
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
	}
}

@MainActor
struct Previewer {
	let container: ModelContainer
	let thread: PrayerThread
	
	init() throws {
		let config = ModelConfiguration(isStoredInMemoryOnly: true)
		container = try ModelContainer(for: PrayerThread.self, configurations: config)
		
		thread = .init()
		
		container.mainContext.insert(thread)
	}
}



#Preview {
	do {
		let previewer = try Previewer()
		
		return RecordingView(prayerThread: previewer.thread)
			.modelContainer(previewer.container)
	} catch {
		return Text("Failed to make container")
	}
	
}
