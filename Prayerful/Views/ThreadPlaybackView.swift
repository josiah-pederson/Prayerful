//
//  ThreadPlaybackView.swift
//  Prayerful
//
//  Created by Josiah Pederson on 11/3/24.
//

import SwiftUI
import Charts

struct ThreadPlaybackView: View {
	private var prayerThread: PrayerThread
	
	@State private var audioPlayer = AudioPlayer()
	
	@State var data: [Float] = Array(repeating: 0, count: Constants.barAmount)
	
	private let timer = Timer.publish(
		every: Constants.updateInterval,
		on: .main,
		in: .common
	).autoconnect()
	
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
							if audioPlayer.isSelected(prayer) {
								audioPlayer.pause()
							} else {
								audioPlayer.stop()
								DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
									audioPlayer.play(url: prayer.url)
								}
							}
						} label: {
							if audioPlayer.isSelected(prayer) {
								ProgressView(
									value: min(audioPlayer.currentTime, audioPlayer.currentRecordingDuration),
									total: audioPlayer.currentRecordingDuration
								)
							} else {
								ProgressView(value: 1, total: 1)
							}
						}
						.progressViewStyle(.linear)
						.frame(maxWidth: width)
						.font(.title)
					}
				}
			}
			.frame(maxHeight: 30)
			Text("Thread is \(audioPlayer.totalDuration, specifier: "%.0f") seconds.")
			if audioPlayer.isPlaying {
				HStack {
					Button("Stop", systemImage: "stop.circle") {
						audioPlayer.stop()
					}
					Button("Pause", systemImage: "pause.circle") {
						audioPlayer.pause()
					}
				}
				.labelStyle(.iconOnly)
				.font(.title)
				WaveformChartView(data: data)
					.frame(width: 250, height: 100)
					.onReceive(timer, perform: updateData)
			} else {
				Button("Play", systemImage: "play.circle") {
					audioPlayer.play()
				}
				.labelStyle(.iconOnly)
				.font(.title)
			}
		}
		.onChange(of: prayerThread.chronologicalRecordings) { _, newVal in
			audioPlayer.enqueue(newVal)
		}
		.onAppear {
			audioPlayer.enqueue(prayerThread.chronologicalRecordings)
		}
		.onDisappear {
			audioPlayer.stop()
		}
	}
}



private extension ThreadPlaybackView {
	
	// MARK: Methods
	
	/// Updates the chart data points for the audio visualizer
	/// - Parameter _: The date of the timer publisher event
	func updateData(_: Date) {
		if audioPlayer.isPlaying {
			withAnimation(.easeOut(duration: 0.08)) {
				data = audioPlayer.fftMagnitudes.map {
					min($0, Constants.magnitudeLimit)
				}
			}
		}
	}
}

#Preview {
	ThreadPlaybackView(.init())
}
