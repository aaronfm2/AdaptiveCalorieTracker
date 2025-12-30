import SwiftUI

struct FullScreenImageViewer: View {
    let imageData: Data
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { dismiss() }
                        .foregroundColor(.white)
                }
            }
        }
    }
}

// Helper wrapper to make Data identifiable for sheets
struct IdentifiableData: Identifiable {
    let id = UUID()
    let data: Data
}
