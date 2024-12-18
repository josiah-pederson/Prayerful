//
//  AudioRecorder.swift
//  Prayerful
//
//  Created by Josiah Pederson on 10/28/24.
//

import Foundation
import AVFoundation
import OSLog

/// A class responsible for managing audio recordings.
///
/// The `AudioRecorder` class provides functionality to start, stop, and pause audio recordings. It also handles interruptions from the system, such as incoming calls, to pause recordings safely and resume them if needed.
@Observable
class AudioRecorder {
	
	// MARK: - Properties
	
	/// The internal AVAudioRecorder instance used to manage audio recording operations.
	private var audioRecorder: AVAudioRecorder?
	
	/// The current status of the audio recording.
	///
	/// The `recordingStatus` property represents the state of the recording. It can be:
	/// - `.stopped`: When no active recording is taking place.
	/// - `.preparing`: When a recording session is being set up.
	/// - `.recording`: When a recording is in progress.
	/// - `.paused`: When an ongoing recording is temporarily paused.
	/// - `.finalizing`: When a recording is being stopped and finalized.
	/// - `.error`: When an error occurs during recording.
	///
	/// > Note: This is a published property to notify observers of any changes.
	var recordingStatus: AudioRecordingStatus = .stopped
	
	// MARK: - Initialization and Deinitialization
	
	/// Initializes a new `AudioRecorder` instance and sets up interruption handling.
	init() {
//		self.addInterruptionObserver() // Instead of using this, we use ScenePhase in RecordingView
		self.addRouteChangeObserver()
	}
	
	/// Removes the observer when the instance is deallocated.
	deinit {
		NotificationCenter.default.removeObserver(self)
	}
}

extension AudioRecorder {
	
	// MARK: - Private Methods

	/// Creates a file URL for a new recording.
	///
	/// - Returns: A unique file URL for saving the new recording.
	private func getNewRecordingURL() -> URL {
		// Create a unique filename using the current date and time.
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
		let dateString = dateFormatter.string(from: Date())
		let fileName = "Recording_\(dateString)"
		let directory = fileFinder.prayersDirectory
		let recordingURL = URL(fileURLWithPath: fileName, relativeTo: directory).appendingPathExtension("m4a")
		return recordingURL
	}
	
	/// Activates an audio session for a recording.
	///
	/// This method sets the audio session category to `.playAndRecord` with the default speaker output option.
	/// It then attempts to activate the audio session, making it ready for recording.
	///
	/// - Throws: `AudioRecorderError.sessionActivationFailed` if the audio session cannot be successfully activated.
	/// - Important: This method should only be called when preparing to start or resume a recording.
	func activateAudioSession() throws {
		let session = AVAudioSession.sharedInstance()
		
		do {
			try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
			try session.setActive(true, options: .notifyOthersOnDeactivation)
		} catch {
			throw AudioRecorderError.sessionActivationFailed(error)
		}
	}
	
	/// Deactivates the active audio session after recording.
	///
	/// This method deactivates the current audio session and logs any errors that occur during the deactivation process.
	/// It ensures that the audio session is released properly, allowing other audio-based operations to proceed.
	///
	/// - Note: Call this method after stopping a recording to free up the system's audio resources.
	private func deactivateAudioSession() {
		do {
			try AVAudioSession.sharedInstance().setActive(false)
		} catch {
			let deactivationError = AudioRecorderError.sessionDeactivationFailed(error)
			Logger.shared.error("\(deactivationError.localizedDescription)")
		}
	}
}

extension AudioRecorder {
	
	// MARK: - Cleanup methods
	
	/// Deletes all audio recordings in the app's documents directory.
	///
	/// This method iterates through all files in the app's documents directory and removes those that match the audio file naming convention used by the `AudioRecorder` class.
	///
	/// - Warning: This operation cannot be undone, so use it carefully.
	func cleanUpOldRecordings() {
		let fileManager = FileManager.default
		let prayersDirectory = fileFinder.prayersDirectory
		
		do {
			// Get all files in the prayers directory
			let files = try fileManager.contentsOfDirectory(at: prayersDirectory, includingPropertiesForKeys: nil)
			
			for file in files {
				// Only delete files that match the "Recording_" prefix and ".m4a" extension.
				if file.lastPathComponent.hasPrefix("Recording_") && file.pathExtension == "m4a" {
					do {
						try fileManager.removeItem(at: file)
						Logger.shared.info("Deleted recording: \(file.lastPathComponent)")
					} catch {
						Logger.shared.error("Failed to delete recording \(file.lastPathComponent): \(error.localizedDescription)")
					}
				}
			}
		} catch {
			Logger.shared.error("Failed to access recordings directory: \(error.localizedDescription)")
		}
	}
}

extension AudioRecorder {
	
	// MARK: - Recording Control Methods
	
	/// Starts a new or paused recording.
	///
	/// If the recording status is `.paused`, this method resumes the paused recording. Otherwise, it starts a new recording session.
	func startRecording() {
		guard recordingStatus == .stopped || recordingStatus == .paused else {
			Logger.shared.error("Cannot start a new recording while another one is already active.")
			return
		}
		
		do {
			
			if recordingStatus == .paused {
				// Resume the paused recording
				audioRecorder?.record()
				DispatchQueue.main.async {
					self.recordingStatus = .recording
				}
				return
			}
			
			DispatchQueue.main.async {
				self.recordingStatus = .preparing
			}
			
			// Setup and start a new recording session
			try self.activateAudioSession()
			
			let audioFilename = getNewRecordingURL()
			
			// Define audio recording settings
			let settings: [String: Any] = [
				AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
				AVSampleRateKey: 12000,
				AVNumberOfChannelsKey: 1,
				AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
			]

			// Create and start the AVAudioRecorder
			audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
			audioRecorder?.record()
			DispatchQueue.main.async {
				self.recordingStatus = .recording
			}
		} catch {
			let recordingError = AudioRecorderError.recordingInitializationFailed(error)
			Logger.shared.error("\(recordingError.localizedDescription)")
			DispatchQueue.main.async {
				self.recordingStatus = .error(recordingError)
			}
		}
	}

	/// Stops the current recording and returns the recorded file URL.
	///
	/// - Returns: The file URL of the recorded audio, if available.
	func stopRecording() -> (URL, TimeInterval)? {
		
		defer {
			self.audioRecorder = nil
		}
		
		guard recordingStatus == .recording || recordingStatus == .paused else {
			Logger.shared.error("Cannot stop a recording that is not active.")
			return nil
		}

		DispatchQueue.main.async {
			self.recordingStatus = .finalizing
		}
		
		self.audioRecorder?.stop()
		DispatchQueue.main.async {
			self.recordingStatus = .stopped
		}
		self.deactivateAudioSession()
		
		// Retrieve the recorded file URL.
		guard let recordedURL = audioRecorder?.url else {
			Logger.shared.error("Audio recorder returned a null URL.")
			return nil
		}
		
		// Ensure the file was saved.
		guard FileManager.default.fileExists(atPath: recordedURL.path) else {
			Logger.shared.error("Recording file was not saved at expected path: \(recordedURL.path)")
			return nil
		}
				
		let audioPlayer = try? AVAudioPlayer(contentsOf: recordedURL)
		
		let relativePath = recordedURL.relativePath
		Logger.shared.info("Related path: \(relativePath)")

		let duration = audioPlayer?.duration ?? 0.0
		return (recordedURL, duration)
	}
	
	/// Pauses the current recording.
	///
	/// This method pauses an ongoing recording, allowing it to be resumed later. If there is no active recording, it stops the recording.
	func pauseRecording() {
		guard let recorder = audioRecorder, recorder.isRecording else {
			_ = self.stopRecording()
			return
		}
		recorder.pause()
		DispatchQueue.main.async {
			self.recordingStatus = .paused
		}
	}
}

extension AudioRecorder {
	
	// MARK: - Interruption Handling
	
	/// Handles iOS interruption events such as phone calls.
	///
	/// This method pauses a live recording when an interruption begins and reactivates the audio session when an interruption ends.
	///
	/// - Parameter notification: The interruption notification received from the system.
	@objc private func handleInterruption(notification: Notification) {
		guard let userInfo = notification.userInfo,
			  let type = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
			  let interruptionType = AVAudioSession.InterruptionType(rawValue: type) else { return }
		
		Logger.shared.info("Audio session interruption: \(interruptionType.rawValue)")

		if interruptionType == .began {
			// Pause the recording when an interruption begins.
			self.pauseRecording()
		} else if interruptionType == .ended {
			// Try to reactivate the session after the interruption ends.
			do {
				try self.activateAudioSession()
			} catch {
				let recordingError = AudioRecorderError.sessionActivationFailed(error)
				Logger.shared.error("\(recordingError.localizedDescription)")
				DispatchQueue.main.async {
					self.recordingStatus = .error(recordingError)
				}
			}
		}
	}
	
	/// Adds an observer for system interruptions
	private func addInterruptionObserver() {
		// Adds observer for when the recording is interrupted by an iOS event such as a phone call.
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(handleInterruption),
			name: AVAudioSession.interruptionNotification,
			object: AVAudioSession.sharedInstance()
		)
	}
	
	/// Pauses the recording when the microphone device (internal mic, headphones, etc) changes
	/// - Parameter notification: The route change notification received
	@objc private func handleRouteChange(notification: Notification) {
		guard let userInfo = notification.userInfo,
			  let reason = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
			  let routeChangeReason = AVAudioSession.RouteChangeReason(rawValue: reason) else { return }
		
		switch routeChangeReason {
		case .oldDeviceUnavailable:
			// Pause the recording if previous recording device is no longer available.
			Logger.shared.info("Audio route changed, old device unavailable. Pausing recording.")
			self.pauseRecording()
		default:
			break
		}
	}
	
	/// Adds an observer for when the audio recording route changes unexpectedly.
	private func addRouteChangeObserver() {
		// Adds observer for when the audio recording device (internal mic, headphones, etc.) changes during a recording.
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(handleRouteChange),
			name: AVAudioSession.routeChangeNotification,
			object: nil
		)
	}
}


// MARK: - AudioRecorder Errors

/// Errors pertaining to the ``AudioRecorder`` class
enum AudioRecorderError: LocalizedError {
	/// An audio session could not be successfully activated
	case sessionActivationFailed(_ error: Error)
	/// A recording could not be initialized
	case recordingInitializationFailed(_ error: Error)
	/// An audio session could not be deactivated
	case sessionDeactivationFailed(_ error: Error)
	
	var errorDescription: String? {
		switch self {
		case .recordingInitializationFailed(let error):
			return "Failed to initialize recording: \(error.localizedDescription)"
		case .sessionActivationFailed(error: let error):
			return "Failed to activate audio session: \(error.localizedDescription)"
		case .sessionDeactivationFailed(error: let error):
			return "Failed to deactivate audio session: \(error.localizedDescription)"
		}
	}
}
