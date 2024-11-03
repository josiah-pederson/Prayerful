//
//  ThreadListView.swift
//  Prayerful
//
//  Created by Josiah Pederson on 10/31/24.
//

import SwiftUI
import SwiftData

struct ThreadListView: View {
	@Query var threads: [PrayerThread]
	
	@Environment(\.modelContext) var modelContext
	
    var body: some View {
		List(threads) { thread in
			NavigationLink(value: thread) {
				HStack {
					Image(systemName: "play.circle.fill")
					VStack(alignment: .leading) {
						Text(thread.title)
						Text(thread.durationDescription)
							.font(.caption)
					}
					Spacer()
				}
				
			}
			.swipeActions {
				Button("Delete", systemImage: "trash", role: .destructive) {
					self.delete(thread)
				}
			}
		}
		.navigationTitle("Prayer Threads")
    }
	
	// Delete thread at offsets method
	private func delete(_ thread: PrayerThread) {
		self.modelContext.delete(thread)
	}
	
	
}

#Preview {
    ThreadListView()
}
