//
//  ThreadPlaybackView.swift
//  Prayerful
//
//  Created by Josiah Pederson on 11/3/24.
//

import SwiftUI

struct ThreadPlaybackView: View {
	private var prayerThread: PrayerThread
	
	@State private var audioPlayer = AudioPlayer()
	
	@State private var currentTime: TimeInterval = .zero
	
	init(_ prayerThread: PrayerThread) {
		self.prayerThread = prayerThread
	}
	
	var body: some View {
		VStack {
			GeometryReader { geo in
				HStack {
					ForEach(prayerThread.chronologicalRecordings) { prayer in
						let durationPercentage = prayer.duration / prayerThread.duration
						let width = durationPercentage * geo.size.width
						Button {
							if self.isPlaying(prayer) {
								self.audioPlayer.pause()
							} else {
								self.audioPlayer.play(from: prayer)
							}
						} label: {
							RoundedRectangle(cornerRadius: 3)
								.padding(3)
								.frame(maxWidth: width)
								.opacity(self.isPlaying(prayer) ? 0.5 : 1)
						}
					}
				}
			}
			.frame(maxWidth: .infinity, maxHeight: 30)
			
			switch audioPlayer.isPlaying {
			case true:
				Button("Stop playback") {
					audioPlayer.stop()
				}
				Button("Pause playback") {
					audioPlayer.pause()
				}
			case false:
				Button("Play from start") {
					audioPlayer.play()
				}
			}
		}
		.onAppear {
			// Set the player up with all recordings in the thread
			self.audioPlayer.setRecordings(prayerThread.recordings)
		}
		.onDisappear {
			self.audioPlayer.stop()
		}
		.onChange(of: self.prayerThread.recordings) { oldVal, newVal in
			// Set player up with all updated recordings in the thread
			self.audioPlayer.setRecordings(newVal)
		}
		.onReceive(Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()) { _ in
			self.currentTime = audioPlayer.currentTime
		}
	}
	
	/// Whether the audio player is currently playing the given recording
	/// - Parameter recording: The recording in question
	/// - Returns: If the audio player is playing that recording
	private func isPlaying(_ recording: PrayerRecording) -> Bool {
		audioPlayer.isPlaying && audioPlayer.currentRecording == recording
	}
}

#Preview {
	ThreadPlaybackView(.init())
}
