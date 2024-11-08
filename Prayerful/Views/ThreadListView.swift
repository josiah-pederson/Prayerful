//
//  ThreadListView.swift
//  Prayerful
//
//  Created by Josiah Pederson on 10/31/24.
//

import SwiftUI
import SwiftData

struct ThreadListView: View {
	@Query private var threads: [PrayerThread]
	
	@Environment(\.modelContext) private var modelContext
	
    var body: some View {
		List(threads.sorted(by: isMoreRecent)) { thread in
			NavigationLink {
				RecordingView(thread)
			} label: {
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
	
	/// Compares the edited date of two ``PrayerThread`` instances
	/// - Parameters:
	///   - lhs: The left hand side prayer thread
	///   - rhs: The right hand side prayer thread
	/// - Returns: Whether the left prayer thread is more recent than the right
	private func isMoreRecent(lhs: PrayerThread, rhs: PrayerThread) -> Bool {
		lhs.editedDate > rhs.editedDate
	}
}

#Preview {
    ThreadListView()
}
