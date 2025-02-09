//
//  PlayablePrayer.swift
//  Prayerful
//
//  Created by Josiah Pederson on 2/8/25.
//

import Foundation
import AVFoundation
import OSLog

struct PlayablePrayer: Identifiable {
	let url: URL
	let audioFile: AVAudioFile
	let duration: TimeInterval
	
	var id: String { url.absoluteString }
	
	init(at url: URL, duration: TimeInterval) throws {
		let audioFile = try AVAudioFile(forReading: url)
		self.url = url
		self.audioFile = audioFile
		self.duration = duration
	}
}
