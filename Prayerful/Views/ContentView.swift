//
//  ContentView.swift
//  Prayerful
//
//  Created by Josiah Pederson on 10/28/24.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
		RecordingView(prayerThread: .init())
    }
}

#Preview {
    ContentView()
}
