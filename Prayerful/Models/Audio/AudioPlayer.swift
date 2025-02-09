//
//  AudioPlayer.swift
//  Prayerful
//
//  Created by Josiah Pederson on 11/3/24.
//

import Foundation
import AVFoundation
import OSLog
import Accelerate



/// A class that manages audio playback using `AVAudioEngine`.
///
/// `AudioPlayer` supports a queue of audio files and plays them sequentially.
/// It integrates a visualizer using FFT and handles audio session interruptions.
@Observable
class AudioPlayer {
	
	// MARK: - Properties
	
	/// The audio engine used for playback.
	@ObservationIgnored
	private var engine = AVAudioEngine()
	
	/// The player node responsible for playing audio.
	@ObservationIgnored
	private var playerNode = AVAudioPlayerNode()
	
	/// The queue of playable prayers to be played sequentially.
	@ObservationIgnored
	private var queue = [PlayablePrayer]()
	
	/// A Boolean value indicating whether audio is currently playing.
	var isPlaying = false
	
	/// The index of the currently playing item in the queue.
	private(set) var currentIndex = 0
	
	/// The size of the FFT buffer for the visualizer.
	private let bufferSize = 1024
	
	/// Stores FFT magnitudes for visualization purposes.
	@ObservationIgnored
	var fftMagnitudes = [Float]()
	
	// MARK: - Initialization
	
	/// Initializes a new instance of `AudioPlayer`, setting up the audio engine
	/// and observing interruption notifications.
	init() {
		observeInterruptionNotifications()
		setupAudioEngine()
	}
	
	// MARK: - Queue Management
	
	/// Checks if a specific prayer recording is currently selected and playing.
	/// - Parameter prayer: The `PrayerRecording` to check.
	/// - Returns: `true` if the given prayer is currently playing; otherwise, `false`.
	func isSelected(_ prayer: PrayerRecording) -> Bool {
		guard !queue.isEmpty else { return false }
		return queue[currentIndex].url == prayer.url && isPlaying
	}
	
	/// Enqueues a list of `PrayerRecording` objects for playback.
	/// - Parameter prayers: An array of `PrayerRecording` objects to enqueue.
	func enqueue(_ prayers: [PrayerRecording]) {
		let urls = prayers.map { $0.url }
		let prayerQueue = urls.compactMap { PlayablePrayer(url: $0) }
		queue = prayerQueue
	}
	
	// MARK: - Audio Engine Setup
	
	/// Configures the audio engine and attaches the player node.
	private func setupAudioEngine() {
		engine.attach(playerNode)
		let outputFormat = engine.mainMixerNode.outputFormat(forBus: 0)
		engine.connect(playerNode, to: engine.mainMixerNode, format: outputFormat)
		
		let fftSetup = vDSP_DFT_zop_CreateSetup(
			nil,
			UInt(bufferSize),
			vDSP_DFT_Direction.FORWARD
		)
		
		engine.mainMixerNode.installTap(
			onBus: 0,
			bufferSize: UInt32(bufferSize),
			format: nil
		) { [self] buffer, _ in
			let channelData = buffer.floatChannelData?[0]
			fftMagnitudes = fft(data: channelData!, setup: fftSetup!)
		}
	}
	
	// MARK: - Playback Controls
	
	/// Starts playback from the current file in the queue.
	/// - Parameter url: An optional URL to specify a file to start playback from.
	func play(url: URL? = nil) {
		guard !queue.isEmpty, currentIndex < queue.count else {
			print("Playback stopped: Queue empty or index out of range")
			return
		}
		
		if !engine.isRunning {
			try? engine.start()
		}
		
		if let url, let index = queue.firstIndex(where: { $0.url == url }) {
			currentIndex = index
		}
		
		let currentPrayer = queue[currentIndex]
		print("Playing file: \(currentPrayer.url.lastPathComponent), index: \(currentIndex)")
		
		playerNode.scheduleFile(currentPrayer.audioFile, at: nil, completionCallbackType: .dataRendered) { [weak self] _ in
			DispatchQueue.main.async {
				print("Completion handler triggered for: \(currentPrayer.url.lastPathComponent)")
				self?.handlePlaybackCompletion()
			}
		}
		
		playerNode.play()
		isPlaying = true
	}
	
	/// Pauses the currently playing audio.
	func pause() {
		playerNode.pause()
		isPlaying = false
	}
	
	/// Stops playback and resets the queue.
	func stop() {
		playerNode.stop()
		playerNode.reset()
		engine.stop()
		currentIndex = 0
		isPlaying = false
	}
	
	/// Handles the completion of audio playback and plays the next file if available.
	private func handlePlaybackCompletion() {
		guard isPlaying else {
			print("Playback completion ignored, isPlaying is false")
			return
		}
		
		currentIndex += 1
		print("Moving to next file, new index: \(currentIndex)")
		
		if currentIndex < queue.count {
			play()
		} else {
			print("Playback complete, stopping")
			stop()
		}
	}
	
	// MARK: - FFT Visualizer
	
	/// Computes the FFT of the given audio data.
	/// - Parameters:
	///   - data: The raw float data of the audio buffer.
	///   - setup: The FFT setup object.
	/// - Returns: An array of magnitudes representing the FFT result.
	func fft(data: UnsafeMutablePointer<Float>, setup: OpaquePointer) -> [Float] {
		var realIn = [Float](repeating: 0, count: bufferSize)
		var imagIn = [Float](repeating: 0, count: bufferSize)
		var realOut = [Float](repeating: 0, count: bufferSize)
		var imagOut = [Float](repeating: 0, count: bufferSize)
		
		for i in 0 ..< bufferSize {
			realIn[i] = data[i]
		}
		
		vDSP_DFT_Execute(setup, &realIn, &imagIn, &realOut, &imagOut)
		
		var magnitudes = [Float](repeating: 0, count: Constants.barAmount)
		realOut.withUnsafeMutableBufferPointer { realBP in
			imagOut.withUnsafeMutableBufferPointer { imagBP in
				var complex = DSPSplitComplex(realp: realBP.baseAddress!, imagp: imagBP.baseAddress!)
				vDSP_zvabs(&complex, 1, &magnitudes, 1, UInt(Constants.barAmount))
			}
		}
		
		var normalizedMagnitudes = [Float](repeating: 0.0, count: Constants.barAmount)
		var scalingFactor = Float(1)
		vDSP_vsmul(&magnitudes, 1, &scalingFactor, &normalizedMagnitudes, 1, UInt(Constants.barAmount))
		
		return normalizedMagnitudes
	}
	
	// MARK: - Audio Session Handling
	
	/// Observes audio session interruptions and pauses playback when necessary.
	private func observeInterruptionNotifications() {
		NotificationCenter.default.addObserver(self, selector: #selector(handleInterruption), name: AVAudioSession.interruptionNotification, object: nil)
	}
	
	/// Handles audio session interruptions.
	@objc private func handleInterruption(notification: Notification) {
		guard let info = notification.userInfo,
			  let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
			  let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }
		
		if type == .began {
			pause()
		}
	}
}
