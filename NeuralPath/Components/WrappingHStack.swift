//
//  WrappingHStack.swift
//  NeuralPath
//
//  Created by Claude Code
//

import SwiftUI

struct WrappingHStack: Layout {
    var horizontalSpacing: CGFloat = 8
    var verticalSpacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 300
        let result = FlexLayoutResult(
            in: width,
            subviews: subviews,
            horizontalSpacing: horizontalSpacing,
            verticalSpacing: verticalSpacing
        )
        return CGSize(width: width, height: result.size.height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlexLayoutResult(
            in: bounds.width,
            subviews: subviews,
            horizontalSpacing: horizontalSpacing,
            verticalSpacing: verticalSpacing
        )
        let childProposal = ProposedViewSize(width: bounds.width, height: nil)

        for (index, subview) in subviews.enumerated() {
            let position = result.positions[index]
            subview.place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: childProposal
            )
        }
    }

    private struct FlexLayoutResult {
        var positions: [CGPoint] = []
        var size: CGSize = .zero

        init(in maxWidth: CGFloat, subviews: Subviews, horizontalSpacing: CGFloat, verticalSpacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0
            let proposal = ProposedViewSize(width: maxWidth, height: nil)

            for subview in subviews {
                let size = subview.sizeThatFits(proposal)

                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += lineHeight + verticalSpacing
                    lineHeight = 0
                }

                positions.append(CGPoint(x: x, y: y))
                lineHeight = max(lineHeight, size.height)
                x += size.width + horizontalSpacing
            }

            self.size = CGSize(width: maxWidth, height: y + lineHeight)
        }
    }
}
