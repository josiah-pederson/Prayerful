//
//  ContentView.swift
//  Prayerful
//
//  Created by Josiah Pederson on 10/28/24.
//

import SwiftUI
import SwiftData
import OSLog

struct ContentView: View {
	@Environment(\.modelContext) var modelContext
	
	@State private var navigationPath = NavigationPath()
	
    var body: some View {
		NavigationStack(path: $navigationPath) {
			ThreadListView()
				.overlay(alignment: .bottom) {
					NavigationLink {
						RecordingView(.init())
					} label: {
						Image(systemName: "waveform.circle.fill")
							.resizable()
					}
					.scaledToFit()
					.padding()
					.frame(maxWidth: .infinity, maxHeight: 100)
					.background()
				}
				.toolbar {
					ToolbarItem(placement: .topBarTrailing) {
						Menu {
							Button("Erase all prayer threads", role: .destructive) {
								do {
									try modelContext.delete(model: PrayerThread.self)
									Logger.shared.info("Erased prayer threads")
								} catch {
									Logger.shared.error("Failed to erase prayer threads")
								}
							}
						} label: {
							Image(systemName: "ellipsis.circle")
						}
					}
				}
		}
    }
	
	func newPrayerThread() {
		let thread = PrayerThread()
		self.navigationPath.append(thread)
	}
}

#Preview {
    ContentView()
}
