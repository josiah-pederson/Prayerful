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
	
	@State private var audioPlayer = AudioPlayer3()
	
	@State var data: [Float] = Array(repeating: 0, count: PlayerConstants.barAmount)
		.map { _ in Float.random(in: 1 ... PlayerConstants.magnitudeLimit) }
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
			if audioPlayer.isPlaying {
				Chart(Array(data.enumerated()), id: \.0) { index, magnitude in
					BarMark(
						x: .value("Frequency", String(index)),
						y: .value("Magnitude", magnitude)
					)
					.foregroundStyle(
						Color(
							hue: 0.3 - Double((magnitude / Constants.magnitudeLimit) / 5),
							saturation: 1,
							brightness: 1,
							opacity: 0.7
						)
					)
				}
				.chartYScale(domain: 0 ... Constants.magnitudeLimit)
				.chartXAxis(.hidden)
				.chartYAxis(.hidden)
				.frame(height: 100)
				.onReceive(timer, perform: updateData)
			}
			
		}
		.onChange(of: prayerThread.chronologicalRecordings) { _, newVal in
			audioPlayer.enqueue(newVal)
		}
		.onAppear {
			audioPlayer.enqueue(prayerThread.chronologicalRecordings)
		}
	}
	
	func updateData(_: Date) {
		if audioPlayer.isPlaying {
			withAnimation(.easeOut(duration: 0.08)) {
				data = audioPlayer.fftMagnitudes.map {
					min($0, PlayerConstants.magnitudeLimit)
				}
			}
		}
	}
	
	
	func playButtonTapped() {
		if audioPlayer.isPlaying {
			audioPlayer.pause()
		} else {
			audioPlayer.play()
		}
	}
}

#Preview {
	ThreadPlaybackView(.init())
}
