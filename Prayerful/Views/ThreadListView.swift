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
		}
		.navigationTitle("Prayer Threads")
    }
}

#Preview {
    ThreadListView()
}
