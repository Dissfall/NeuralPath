//
//  BodyScanOverlay.swift
//  NeuralPath
//

import SwiftUI

struct BodyScanOverlay: View {
    let highlightedRegion: BodyRegion
    let color: Color

    @State private var glowOpacity: Double = 0.3

    private let figureSize: CGFloat = 200

    var body: some View {
        ZStack {
            // Base figure - dimmed
            Image(systemName: "figure.arms.open")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: figureSize)
                .foregroundStyle(color.opacity(0.15))

            // Highlighted figure with mask
            Image(systemName: "figure.arms.open")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: figureSize)
                .foregroundStyle(color)
                .mask(highlightMask)

            // Glow effect
            highlightGlow
                .opacity(glowOpacity)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                glowOpacity = 0.6
            }
        }
    }

    // MARK: - Highlight Mask

    @ViewBuilder
    private var highlightMask: some View {
        GeometryReader { geo in
            let region = regionFrame(in: geo.size)
            Rectangle()
                .frame(width: region.width, height: region.height)
                .position(x: region.midX, y: region.midY)
                .blur(radius: 8)
        }
        .frame(height: figureSize)
    }

    // MARK: - Glow Effect

    @ViewBuilder
    private var highlightGlow: some View {
        GeometryReader { geo in
            let region = regionFrame(in: geo.size)
            Ellipse()
                .fill(color)
                .frame(width: region.width * 1.2, height: region.height * 1.2)
                .blur(radius: 20)
                .position(x: region.midX, y: region.midY)
        }
        .frame(height: figureSize)
    }

    // MARK: - Region Positioning

    private func regionFrame(in size: CGSize) -> CGRect {
        let width = size.width
        let height = size.height

        switch highlightedRegion {
        case .head:
            return CGRect(
                x: width * 0.35,
                y: 0,
                width: width * 0.3,
                height: height * 0.18
            )
        case .arms:
            return CGRect(
                x: 0,
                y: height * 0.18,
                width: width,
                height: height * 0.25
            )
        case .torso:
            return CGRect(
                x: width * 0.3,
                y: height * 0.18,
                width: width * 0.4,
                height: height * 0.3
            )
        case .hips:
            return CGRect(
                x: width * 0.25,
                y: height * 0.45,
                width: width * 0.5,
                height: height * 0.15
            )
        case .legs:
            return CGRect(
                x: width * 0.2,
                y: height * 0.55,
                width: width * 0.6,
                height: height * 0.35
            )
        case .feet:
            return CGRect(
                x: width * 0.15,
                y: height * 0.85,
                width: width * 0.7,
                height: height * 0.15
            )
        }
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 40) {
            ForEach(BodyRegion.allCases, id: \.self) { region in
                VStack {
                    Text(region.displayName)
                        .font(.caption)
                    BodyScanOverlay(highlightedRegion: region, color: .teal)
                }
            }
        }
        .padding()
    }
}
