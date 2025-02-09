//
//  PlayablePrayer.swift
//  Prayerful
//
//  Created by Josiah Pederson on 2/8/25.
//

import Foundation
import AVFoundation

struct PlayablePrayer: Identifiable {
	let url: URL
	let audioFile: AVAudioFile
	let duration: TimeInterval
	
	var id: String { url.absoluteString }
	
	init?(_ prayer: PrayerRecording) {
		guard let audioFile = try? AVAudioFile(forReading: prayer.url) else {
			return nil
		}
		url = prayer.url
		self.audioFile = audioFile
		duration = prayer.duration
	}
}
