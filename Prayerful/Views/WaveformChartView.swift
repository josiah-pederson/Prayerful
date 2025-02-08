//
//  WaveformChartView.swift
//  Prayerful
//
//  Created by Josiah Pederson on 2/8/25.
//

import SwiftUI
import Charts

struct WaveformChartView: View {
	var data: [Float]
	
	var body: some View {
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
	}
}

#Preview {
	WaveformChartView(data: Array(repeating: 0.5, count: 100))
}
