//
//  NewAudioPlayer.swift
//  Prayerful
//
//  Created by Josiah Pederson on 12/31/24.
//

import SwiftUI
import OSLog
import AVFoundation
import Accelerate

enum Constants {
	static let updateInterval = 0.03
	static let barAmount = 40
	static let magnitudeLimit: Float = 32
}

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

@Observable
class NewAudioPlayer {
	@ObservationIgnored
	private var engine = AVAudioEngine()
	@ObservationIgnored
	private var player = AVAudioPlayerNode()
	@ObservationIgnored
	private var prayerQueue = [PlayablePrayer]()
	@ObservationIgnored
	private var currentFile: PlayablePrayer? = nil
	@ObservationIgnored
	private var displayLink: CADisplayLink?
	@ObservationIgnored
	var fftMagnitudes = [Float]()
	
	private let bufferSize = 1024
	
	// Observable properties
	var isPlaying = false
	var playbackSpeed: Float = 1.0
	var currentIndex: Int? = nil
	var waveformPoints = [Float]()
	
	init() {
		configureAudioSession()
		setupAudioEngine()
		observeInterruptionNotifications()
	}
	
	private func setupAudioEngine() {
		engine.attach(player)
		let format = engine.mainMixerNode.outputFormat(forBus: 0)
		engine.connect(player, to: engine.mainMixerNode, format: format)
		engine.prepare()
		
		do {
			try engine.start()
		} catch {
			Logger.shared.error("Audio engine failed to start: \(error.localizedDescription)")
		}
	}
	
	private func configureAudioSession() {
		let session = AVAudioSession.sharedInstance()
		do {
			try session.setCategory(.playback, mode: .default, options: [])
			try session.setActive(true)
		} catch {
			Logger.shared.error("Audio session setup failed: \(error.localizedDescription)")
		}
	}
	
	func loadPrayers(_ songs: [PrayerRecording]) {
		let urls = songs.map { $0.url }
		let prayerQueue = urls.compactMap { PlayablePrayer(url: $0) }
		self.prayerQueue = prayerQueue
	}
	
	
	func setPlaybackSpeed(_ speed: Float) {
		playbackSpeed = speed
		player.rate = speed
	}
}

extension NewAudioPlayer {
	
	// MARK: Playback methods
	
	func play(at index: Int) {
		guard index < prayerQueue.count else {
			Logger.shared.error( "Couldn't find \(index)th prayer in queue")
			return
		}
		currentIndex = index
		playCurrentPrayer()
	}
	
	func play() {
		if let _ = currentFile {
			playCurrentPrayer()
		} else if let first = prayerQueue.first {
			play(url: first.url)
		}
	}
	
	func play(url: URL) {
		stop()
		guard let index = prayerQueue.firstIndex(where: { $0.url == url }) else {
			Logger.shared.error( "Couldn't find \(url.lastPathComponent) in prayer queue")
			return
		}
		play(at: index)
	}
	
	private func playCurrentPrayer() {
		guard let index = currentIndex, index < prayerQueue.count else { return }
		let file = prayerQueue[index]
		currentFile = file
		Logger.shared.info("Playing file: \(file.url.lastPathComponent)")

		player.scheduleFile(file.audioFile, at: nil) {
			Logger.shared.info("Finished playing file: \(file.url.lastPathComponent)")
			DispatchQueue.main.async { [weak self] in
				self?.nextPrayer()
			}
		}
		
		let fftSetup = vDSP_DFT_zop_CreateSetup(
			nil,
			UInt(bufferSize),
			vDSP_DFT_Direction.FORWARD
		)

//		engine.mainMixerNode.installTap(
//			onBus: 0,
//			bufferSize: UInt32(bufferSize),
//			format: nil
//		) { [self] buffer, _ in
//			let channelData = buffer.floatChannelData?[0]
//			fftMagnitudes = fft(data: channelData!, setup: fftSetup!)
//		}
		player.rate = playbackSpeed
		player.play()
		isPlaying = true
		startWaveformUpdates()
	}
	
	func pause() {
		player.pause()
		isPlaying = false
		stopWaveformUpdates()
	}
	
	func resume() {
		player.play()
		isPlaying = true
		startWaveformUpdates()
	}
	
	func stop() {
		player.pause()
		isPlaying = false
		currentIndex = nil
		currentFile = nil
	}
	
	private func nextPrayer() {
		if let index = currentIndex, index + 1 < prayerQueue.count {
			currentIndex = index + 1
			playCurrentPrayer()
		} else {
			stop()
		}
	}
	
	func isCurrentPrayer(_ prayer: PrayerRecording) -> Bool {
		return currentFile?.url == prayer.url
	}
}

private extension NewAudioPlayer {
	
	// MARK: Waveform update methods
	
	private func startWaveformUpdates() {
		displayLink = CADisplayLink(target: self, selector: #selector(updateWaveform))
		displayLink?.add(to: .main, forMode: .default)
	}
	
	private func stopWaveformUpdates() {
		displayLink?.invalidate()
		displayLink = nil
	}
	
	@objc private func updateWaveform() {
		let node = engine.mainMixerNode
		let outputBuffer = node.outputPresentationLatency
		
		// Add waveform generation logic here
		// Update the waveformPoints array for Swift Charts
	}
	
	func fft(data: UnsafeMutablePointer<Float>, setup: OpaquePointer) -> [Float] {
		var realIn = [Float](repeating: 0, count: bufferSize)
		var imagIn = [Float](repeating: 0, count: bufferSize)
		var realOut = [Float](repeating: 0, count: bufferSize)
		var imagOut = [Float](repeating: 0, count: bufferSize)
			
		for i in 0 ..< bufferSize {
			realIn[i] = data[i]
		}
		
		vDSP_DFT_Execute(setup, &realIn, &imagIn, &realOut, &imagOut)
		
		var magnitudes = [Float](repeating: 0, count: PlayerConstants.barAmount)
		
		realOut.withUnsafeMutableBufferPointer { realBP in
			imagOut.withUnsafeMutableBufferPointer { imagBP in
				var complex = DSPSplitComplex(realp: realBP.baseAddress!, imagp: imagBP.baseAddress!)
				vDSP_zvabs(&complex, 1, &magnitudes, 1, UInt(PlayerConstants.barAmount))
			}
		}
		
		var normalizedMagnitudes = [Float](repeating: 0.0, count: PlayerConstants.barAmount)
		var scalingFactor = Float(1)
		vDSP_vsmul(&magnitudes, 1, &scalingFactor, &normalizedMagnitudes, 1, UInt(PlayerConstants.barAmount))
			
		return normalizedMagnitudes
	}
}

private extension NewAudioPlayer {
	
	// MARK: Interruption notification methods
	
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

enum PlayerConstants {
	static let updateInterval = 0.03
	static let barAmount = 40
	static let magnitudeLimit: Float = 32
}
