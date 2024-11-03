//
//  ContentView.swift
//  Prayerful
//
//  Created by Josiah Pederson on 10/28/24.
//

import SwiftUI
import SwiftData

struct ContentView: View {
	@Environment(\.modelContext) var modelContext
	
	@State private var navigationPath = NavigationPath()
	
    var body: some View {
		NavigationStack(path: $navigationPath) {
			ThreadListView()
				.overlay(alignment: .top) {
					Button("Erase all") {
						do {
							try modelContext.delete(model: PrayerThread.self)
						} catch {
							print("Failed to clear all Country and City data.")
						}
					}
				}
				.overlay(alignment: .bottom) {
					Button {
						newPrayerThread()
					} label: {
						Image(systemName: "waveform.circle.fill")
							.resizable()
					}
					.scaledToFit()
					.padding()
					.frame(maxWidth: .infinity, maxHeight: 100)
					.background()
				}
				.navigationDestination(for: PrayerThread.self) { prayerThread in
					RecordingView(prayerThread)
				}
		}
    }
	
	func newPrayerThread() {
		let thread = PrayerThread()
		modelContext.insert(thread)
		self.navigationPath.append(thread)
	}
}

#Preview {
    ContentView()
}
