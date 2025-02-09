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
		.map { _ in Float.random(in: 1 ... Constants.magnitudeLimit) }
	let timer = Timer.publish(
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
							RoundedRectangle(cornerRadius: 3)
								.padding(3)
								.frame(maxWidth: width)
								.opacity(audioPlayer.isSelected(prayer) ? 0.5 : 1)
							//								.opacity(self.isPlaying(prayer) ? 0.5 : 1)
						}
						//						.overlay(alignment: .leading) {
						//							if self.isPlaying(prayer) {
						//								Rectangle()
						//									.fill(Color.red.opacity(0.2))
						//									.frame(width: width * self.playbackPercentage)
						//							}
						//						}
					}
				}
			}
			.onChange(of: audioPlayer.currentIndex) { _, _ in }
			.frame(maxWidth: .infinity, maxHeight: 30)
			//			HStack {
			//				Text(Int(self.currentAllTime).description)
			//				Spacer()
			//				Text(Int(self.duration).description)
			//			}
			switch audioPlayer.isPlaying {
			case true:
				HStack {
					Button("Stop", systemImage: "stop.circle") {
						audioPlayer.stop()
					}
					.labelStyle(.iconOnly)
					.font(.title)
					Button("Pause", systemImage: "pause.circle") {
						audioPlayer.pause()
					}
					.labelStyle(.iconOnly)
					.font(.title)
				}
				WaveformChartView(data: data)
					.frame(width: 250, height: 100)
					.onReceive(timer, perform: updateData)
			case false:
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
