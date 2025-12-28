import SwiftUI

// MARK: - 1. Identifiers
enum SpotlightTargetID: String, CaseIterable {
    case settings
    case addLog
    case addWorkout
    case library
    case addWeight
}

enum SpotlightArea: Hashable {
    case target(SpotlightTargetID) // Precise button target
    case tab(index: Int)           // Tab bar item
    case center                    // Fallback
}

// MARK: - 2. Preference Key & Extension
struct SpotlightRectsKey: PreferenceKey {
    static var defaultValue: [String: CGRect] = [:]
    static func reduce(value: inout [String: CGRect], nextValue: () -> [String: CGRect]) {
        value.merge(nextValue()) { $1 }
    }
}

extension View {
    func spotlightTarget(_ id: SpotlightTargetID) -> some View {
        self.background(
            GeometryReader { geo in
                Color.clear.preference(
                    // FIX: Use .global to get screen-relative coordinates
                    // This fixes the issue of spotlights appearing too high
                    key: SpotlightRectsKey.self,
                    value: [id.rawValue: geo.frame(in: .global)]
                )
            }
        )
    }
}

// MARK: - 3. Data Model
struct TutorialStep {
    let id: Int
    let title: String
    let description: String
    let tabIndex: Int
    let highlights: [SpotlightArea]
}

// MARK: - 4. Overlay View
struct TutorialOverlayView: View {
    let step: TutorialStep
    let spotlightRects: [String: CGRect]
    let onNext: () -> Void
    let onFinish: () -> Void
    let isLastStep: Bool
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Dimmed Background
                Color.black.opacity(0.7)
                    // Create the "Holes"
                    .mask(
                        ZStack {
                            Rectangle().fill(Color.white) // The solid sheet
                            
                            // The Cutouts
                            ForEach(0..<step.highlights.count, id: \.self) { i in
                                highlightShape(for: step.highlights[i], in: geometry)
                                    .blendMode(.destinationOut) // This punches the hole
                            }
                        }
                    )
                    .ignoresSafeArea() // Ensure overlay covers entire screen
                    .allowsHitTesting(true)
                
                // Instructions Card
                VStack {
                    Spacer()
                    VStack(alignment: .leading, spacing: 16) {
                        Text(step.title).font(.title2).bold().foregroundColor(.white)
                        Text(step.description).font(.body).foregroundColor(.white.opacity(0.9))
                        
                        HStack {
                            Spacer()
                            Button(action: isLastStep ? onFinish : onNext) {
                                Text(isLastStep ? "Finish" : "Next")
                                    .fontWeight(.bold)
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 24)
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .padding(24)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(UIColor.systemGray6).opacity(0.2))
                            .background(.ultraThinMaterial)
                            .cornerRadius(16)
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                }
            }
        }
    }
    
    @ViewBuilder
    func highlightShape(for area: SpotlightArea, in geo: GeometryProxy) -> some View {
        switch area {
        case .target(let id):
            if let rect = spotlightRects[id.rawValue] {
                // Calculate size based on the target's actual frame
                let dimension = max(rect.width, rect.height)
                // Add padding: 10pts if small icon, less if large button
                let padding: CGFloat = dimension < 50 ? 20 : 10
                let radius = (dimension / 2) + padding
                
                Circle()
                    .frame(width: radius * 2, height: radius * 2)
                    .position(x: rect.midX, y: rect.midY)
            } else {
                EmptyView()
            }
            
        case .tab(let index):
            // Dynamic Tab Calculation
            let tabCount = 4
            let tabWidth = geo.size.width / CGFloat(tabCount)
            let xCenter = (CGFloat(index) * tabWidth) + (tabWidth / 2)
            // Position approx over the icon (adjusted for bottom safe area)
            let yCenter = geo.size.height - geo.safeAreaInsets.bottom - 25
            
            Circle()
                .frame(width: 60, height: 60)
                .position(x: xCenter, y: yCenter)
            
        case .center:
            Circle()
                .frame(width: 300, height: 300)
                .position(x: geo.size.width / 2, y: geo.size.height / 2)
        }
    }
}
