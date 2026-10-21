import SwiftUI

/// Night sky with a moon and drifting bats.
struct HauntedBackground: View {
    @State private var bats: [(x: CGFloat, y: CGFloat, speed: Double, size: CGFloat)] = (0..<9).map { index in
        (x: CGFloat(index) / 9, y: CGFloat.random(in: 0.05...0.55), speed: Double.random(in: 0.04...0.09), size: CGFloat.random(in: 18...34))
    }

    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation) { timeline in
                let time = timeline.date.timeIntervalSinceReferenceDate
                ZStack {
                    LinearGradient(
                        colors: [Color(red: 0.16, green: 0.04, blue: 0.27), Color(red: 0.05, green: 0.01, blue: 0.09), .black],
                        startPoint: .top,
                        endPoint: .bottom
                    )

                    Circle()
                        .fill(RadialGradient(colors: [Color(red: 1, green: 0.95, blue: 0.75), Color(red: 1, green: 0.75, blue: 0.3).opacity(0.0)], center: .center, startRadius: 10, endRadius: 90))
                        .frame(width: 180, height: 180)
                        .position(x: geo.size.width * 0.82, y: geo.size.height * 0.1)

                    ForEach(bats.indices, id: \.self) { index in
                        let bat = bats[index]
                        let progress = (bat.x + CGFloat(time * bat.speed)).truncatingRemainder(dividingBy: 1.2) - 0.1
                        Text("🦇")
                            .font(.system(size: bat.size))
                            .position(
                                x: progress * geo.size.width,
                                y: bat.y * geo.size.height + sin(time * 2 + Double(index)) * 12
                            )
                            .opacity(0.75)
                    }
                }
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}
