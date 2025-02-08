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

/// A class to manage audio playback using AVAudioEngine.
/// It supports a queue of audio files and plays them sequentially.
@Observable
class AudioPlayer3 {
	@ObservationIgnored
	private var engine = AVAudioEngine()
	@ObservationIgnored
	private var playerNode = AVAudioPlayerNode()
	
	/// The queue of URLs to play
	@ObservationIgnored
	private var queue = [PlayablePrayer]()
	
	/// Published property to track playback state
	var isPlaying = false
	private(set) var currentIndex = 0
	
	private let bufferSize = 1024
	@ObservationIgnored
	var fftMagnitudes = [Float]()
	
	init() {
		observeInterruptionNotifications()
		setupAudioEngine()
	}
	
	func isSelected(_ prayer: PrayerRecording) -> Bool {
		guard !queue.isEmpty else { return false }
		return queue[currentIndex].url == prayer.url && isPlaying
	}
	
	func enqueue(_ prayers: [PrayerRecording]) {
		let urls = prayers.map { $0.url }
		let prayerQueue = urls.compactMap { PlayablePrayer(url: $0) }
		queue = prayerQueue
	}
	
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
	
	/// Starts playback from the current file in the queue.
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
		
		// Stop and reset player before scheduling a new file
		//		playerNode.stop()
		//		playerNode.reset()
		
		playerNode.scheduleFile(currentPrayer.audioFile, at: nil, completionCallbackType: .dataRendered) { [weak self] _ in
			DispatchQueue.main.async {
				print("Completion handler triggered for: \(currentPrayer.url.lastPathComponent)")
				self?.handlePlaybackCompletion()
			}
		}
		
		playerNode.play()
		isPlaying = true
	}
	
	/// Pauses playback.
	func pause() {
		playerNode.pause()
		isPlaying = false
	}
	
	/// Stops playback and resets the queue.
	func stop() {
		playerNode.stop()
		playerNode.reset() // Reset the playerNode to clear scheduled playback
		engine.stop()
		
		currentIndex = 0
		isPlaying = false
	}
	
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
}

private extension AudioPlayer3 {
	
	// MARK: Visualizer methods
	
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
}

private extension AudioPlayer3 {
	
	// MARK: Notification observer methods
	
	private func observeInterruptionNotifications() {
		NotificationCenter.default.addObserver(self, selector: #selector(handleInterruption), name: AVAudioSession.interruptionNotification, object: nil)
	}
	
	@objc private func handleInterruption(notification: Notification) {
		guard let info = notification.userInfo,
			  let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
			  let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }
		
		if type == .began {
			pause()
		}
	}
}

private struct PlayablePrayer: Identifiable {
	let url: URL
	let audioFile: AVAudioFile
	
	var id: String { url.absoluteString }
	
	init?(url: URL) {
		guard let audioFile = try? AVAudioFile(forReading: url) else {
			return nil
		}
		
		self.url = url
		self.audioFile = audioFile
	}
}
