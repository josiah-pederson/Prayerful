//
//  ThreadPlaybackView.swift
//  Prayerful
//
//  Created by Josiah Pederson on 11/3/24.
//

import SwiftUI

struct ThreadPlaybackView: View {
	var prayerThread: PrayerThread
	
	@State private var audioPlayer = AudioPlayer()
	
	init(_ prayerThread: PrayerThread) {
		self.prayerThread = prayerThread
	}
	
	var body: some View {
		VStack {
			GeometryReader { geo in
				HStack {
					ForEach(prayerThread.recordings) { prayer in
						let durationPercentage = prayer.duration / prayerThread.duration
						let width = durationPercentage * geo.size.width
						Button {
							self.audioPlayer.play(from: prayer)
						} label: {
							RoundedRectangle(cornerRadius: 3)
								.padding(3)
								.frame(maxWidth: width)
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
	}
}

#Preview {
	ThreadPlaybackView(.init())
}
