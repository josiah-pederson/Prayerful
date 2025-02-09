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
	
	var id: String { url.absoluteString }
	
	init?(url: URL) {
		guard let audioFile = try? AVAudioFile(forReading: url) else {
			return nil
		}
		
		self.url = url
		self.audioFile = audioFile
	}
}
