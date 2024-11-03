//
//  AudioPlayer.swift
//  Prayerful
//
//  Created by Josiah Pederson on 11/3/24.
//

import Foundation
import AVFoundation
import OSLog

import Foundation
import AVFoundation

/// `AudioPlaybackEngine` is responsible for sequentially playing back an array of `PrayerRecording` instances.
///
/// This class manages playback, including the ability to:
/// - Start playback from the first recording or a specified recording
/// - Play each recording in sequence
/// - Pause, stop, and restart playback
///
/// The `AudioPlaybackEngine` uses `AVAudioPlayer` for audio playback, and it observes the playback status to
/// automatically transition to the next recording in the sequence when one finishes.
@Observable
class AudioPlayer: NSObject {
	
	/// The current audio player responsible for playback.
	private var player: AVAudioPlayer?
	
	/// The array of recordings to be played sequentially.
	private var recordings: [PrayerRecording] = []
	
	/// The index of the current recording being played.
	private var currentIndex: Int = 0
	
	// Published
	/// A Boolean published property indicating if playback is active.
	var isPlaying: Bool = false
	
	// Published
	/// The current recording being played.
	var currentRecording: PrayerRecording?
	
	/// Initializes a new `AudioPlaybackEngine` and sets up a notification to detect when playback finishes.
	override init() {
		super.init()
	}
	
	// MARK: - Playback Control Methods
	
	/// Sets the sequence of recordings to be played.
	///
	/// - Parameter recordings: An array of `PrayerRecording` objects to play in sequence.
	///
	/// After calling this method, playback will start from the first recording in the provided array unless
	/// a specific recording is passed to the `play(from:)` method.
	func setRecordings(_ recordings: [PrayerRecording]) {
		self.recordings = recordings
		self.currentIndex = 0
		self.currentRecording = recordings.first
	}
	
	/// Starts playback from the beginning of the recording sequence or from a specific recording.
	///
	/// - Parameter recording: The specific `PrayerRecording` to start playback from. If `nil`, playback
	///   starts from the beginning of the sequence or resumes if already in progress.
	///
	/// This method sets the `currentIndex` to the specified recording if provided, then calls
	/// `playCurrentRecording()` to begin playback.
	func play(from recording: PrayerRecording? = nil) {
		if let recording = recording {
			// If a specific recording is provided, set it as the starting point.
			if let index = recordings.firstIndex(of: recording) {
				currentIndex = index
			}
		}
		do {
			try AVAudioSession.sharedInstance().setCategory(.playback)
			playCurrentRecording()
		} catch {
			Logger.shared.error("Failed to set audio session category: \(error)")
		}
	}
	
	/// Pauses playback of the current recording.
	///
	/// This method pauses the audio player if playback is active, keeping the current position.
	func pause() {
		player?.pause()
		isPlaying = false
	}
	
	/// Stops playback and resets to the first recording in the sequence.
	///
	/// After calling this method, playback will restart from the beginning when `play()` is called.
	func stop() {
		player?.stop()
		isPlaying = false
		currentIndex = 0
		currentRecording = recordings.first
	}
	
	// MARK: - Private Methods
	
	/// Plays the current recording in the sequence.
	///
	/// This method checks if there are any recordings left to play. If so, it retrieves the recording's URL,
	/// initializes an `AVAudioPlayer`, and begins playback. If all recordings have finished playing, it calls `stop()`.
	private func playCurrentRecording() {
		guard currentIndex < recordings.count else {
			stop() // End of sequence
			return
		}
		
		// Set the current recording and check the file URL.
		currentRecording = recordings[currentIndex]
		guard let recordingURL = currentRecording?.url else {
			print("Invalid file URL for recording.")
			return
		}
		
		// Check if the file exists at the path.
		guard FileManager.default.fileExists(atPath: recordingURL.path) else {
			print("File not found at path: \(recordingURL.path)")
			return
		}
		
		// Configure audio session for playback
		do {
			let session = AVAudioSession.sharedInstance()
			try session.setCategory(.playback, options: [.defaultToSpeaker])
			try session.setActive(true)
		} catch {
			print("Failed to set audio session for playback: \(error.localizedDescription)")
		}
		
		do {
			// Initialize the player with the recording URL and start playback.
			player = try AVAudioPlayer(contentsOf: recordingURL)
			player?.delegate = self
			player?.play()
			isPlaying = true
		} catch let error as NSError {
			print("Error playing audio: \(error), \(error.userInfo)")
		}
	}
	
	/// Handles the completion of audio playback for a recording.
	///
	/// This method is triggered when a recording finishes playing. It increments `currentIndex` and
	/// calls `playCurrentRecording()` to proceed to the next recording in the sequence.
	private func audioDidFinishPlaying() {
		currentIndex += 1
		playCurrentRecording()
	}
}

extension AudioPlayer: AVAudioPlayerDelegate {
	
	/// Called when `AVAudioPlayer` finishes playback of an audio recording.
	///
	/// - Parameters:
	///   - player: The `AVAudioPlayer` instance that finished playback.
	///   - flag: A Boolean indicating if playback completed successfully.
	///
	/// If playback completes successfully, this method calls `audioDidFinishPlaying(_:)` to
	/// trigger the transition to the next recording in the sequence.
	func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
		if flag {
			audioDidFinishPlaying()
		}
	}
}


/// `AudioPlaybackEngine` is responsible for sequentially playing back an array of `PrayerRecording` instances.
///
/// This class manages playback, including the ability to:
/// - Start playback from the first recording or a specified recording
/// - Play each recording in sequence
/// - Pause, stop, and restart playback
///
/// The `AudioPlaybackEngine` uses `AVAudioPlayer` for audio playback, and it observes the playback status to
/// automatically transition to the next recording in the sequence when one finishes
@Observable
class AudioPlayerOld {
	
	/// The current audio player responsible for playback.
	private var player: AVAudioPlayer?
	
	/// The array of recordings to be played sequentially.
	private var recordings: [PrayerRecording] = []
	
	/// The index of the current recording being played.
	private var currentIndex: Int = 0
	
	// Published
	/// A Boolean published property indicating if playback is active.
	var isPlaying: Bool = false
	
	// Published
	/// The current recording being played.
	var currentRecording: PrayerRecording?
	
	/// Initializes a new `AudioPlaybackEngine` and sets up a notification to detect when playback finishes.
	init() {
		// Set up notification for when playback finishes
		NotificationCenter.default.addObserver(self, selector: #selector(audioDidFinishPlaying(_:)), name: .AVPlayerItemDidPlayToEndTime, object: nil)
	}
	
	// MARK: - Playback Control Methods
	
	/// Sets the sequence of recordings to be played.
	///
	/// - Parameter recordings: An array of `PrayerRecording` objects to play in sequence.
	///
	/// After calling this method, playback will start from the first recording in the provided array unless
	/// a specific recording is passed to the `play(from:)` method.
	func setRecordings(_ recordings: [PrayerRecording]) {
		self.recordings = recordings
		self.currentIndex = 0
		self.currentRecording = recordings.first
	}
	
	/// Starts playback from the beginning of the recording sequence or from a specific recording.
	///
	/// - Parameter recording: The specific `PrayerRecording` to start playback from. If `nil`, playback
	///   starts from the beginning of the sequence or resumes if already in progress.
	///
	/// This method sets the `currentIndex` to the specified recording if provided, then calls
	/// `playCurrentRecording()` to begin playback.
	func play(from recording: PrayerRecording? = nil) {
		if let recording = recording {
			// If a specific recording is provided, set it as the starting point.
			if let index = recordings.firstIndex(of: recording) {
				currentIndex = index
			}
		}
		do {
			try AVAudioSession.sharedInstance().setCategory(.playback)
			playCurrentRecording()
		} catch {
			Logger.shared.error("Failed to set audio session category: \(error)")
		}
	}
	
	/// Pauses playback of the current recording.
	///
	/// This method pauses the audio player if playback is active, keeping the current position.
	func pause() {
		player?.pause()
		isPlaying = false
	}
	
	/// Stops playback and resets to the first recording in the sequence.
	///
	/// After calling this method, playback will restart from the beginning when `play()` is called.
	func stop() {
		player?.stop()
		isPlaying = false
		currentIndex = 0
		currentRecording = recordings.first
		do {
			try AVAudioSession.sharedInstance().setCategory(.playAndRecord)
			playCurrentRecording()
		} catch {
			Logger.shared.error("Failed to set audio session category: \(error)")
		}
	}
	
	// MARK: - Private Methods
	
	/// Plays the current recording in the sequence.
	///
	/// This method checks if there are any recordings left to play. If so, it retrieves the recording's URL,
	/// initializes an `AVAudioPlayer`, and begins playback. If all recordings have finished playing, it calls `stop()`.
	private func playCurrentRecording() {
		guard currentIndex < recordings.count else {
			stop() // End of sequence
			return
		}
		
		// Set the current recording and check the file URL.
		currentRecording = recordings[currentIndex]
		guard let recordingURL = currentRecording?.url else {
			print("Invalid file URL for recording.")
			return
		}
		
		// Check if the file exists at the path.
		guard FileManager.default.fileExists(atPath: recordingURL.path) else {
			print("File not found at path: \(recordingURL.path)")
			return
		}
		
		do {
			// Initialize the player with the recording URL and start playback.

			player = try AVAudioPlayer(contentsOf: recordingURL)
			player?.play()
			isPlaying = true
		} catch let error as NSError {
			print("Error playing audio: \(error), \(error.userInfo)")
		}
	}

	
	/// Handles the completion of audio playback for a recording.
	///
	/// This method is triggered when a recording finishes playing. It increments `currentIndex` and
	/// calls `playCurrentRecording()` to proceed to the next recording in the sequence.
	///
	/// - Parameter notification: The notification object passed when playback finishes.
	@objc private func audioDidFinishPlaying(_ notification: Notification) {
		// Move to the next recording
		currentIndex += 1
		playCurrentRecording()
	}
}

extension AudioPlayerOld {
	
	/// Called when `AVAudioPlayer` finishes playback of an audio recording.
	///
	/// - Parameters:
	///   - player: The `AVAudioPlayer` instance that finished playback.
	///   - flag: A Boolean indicating if playback completed successfully.
	///
	/// If playback completes successfully, this method calls `audioDidFinishPlaying(_:)` to
	/// trigger the transition to the next recording in the sequence.
	func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
		if flag {
			audioDidFinishPlaying(Notification(name: .AVPlayerItemDidPlayToEndTime))
		}
	}
}
