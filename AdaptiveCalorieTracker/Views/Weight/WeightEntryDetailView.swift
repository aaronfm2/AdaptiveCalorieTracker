import SwiftUI
import PhotosUI
import SwiftData

struct WeightEntryDetailView: View {
    @Bindable var entry: WeightEntry
    var profile: UserProfile
    @Environment(\.modelContext) private var modelContext
    
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var capturedImage: UIImage?
    @State private var showCamera = false
    @State private var showImageOptions = false
    @State private var selectedPhotoData: Data? // For full-screen viewer
    
    let tags = ["Full Body", "Upper Body", "Arms", "Chest", "Back", "Shoulders", "Legs"]
    var weightLabel: String { profile.unitSystem == UnitSystem.imperial.rawValue ? "lbs" : "kg" }

    var body: some View {
        Form {
            Section("Details") {
                DatePicker("Date", selection: $entry.date)
                HStack {
                    Text("Weight")
                    Spacer()
                    TextField("Weight", value: $entry.weight, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                    Text(weightLabel).foregroundColor(.secondary)
                }
                TextField("Note", text: $entry.note, axis: .vertical)
            }
            
            Section("Progress Photos") {
                Button {
                    showImageOptions = true
                } label: {
                    Label("Add Photos", systemImage: "photo.badge.plus")
                }
                
                if let photos = entry.photos, !photos.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(photos) { photo in
                                // Use the subview here to simplify the expression
                                PhotoRowView(
                                    photo: photo,
                                    tags: tags,
                                    selectedPhotoData: $selectedPhotoData
                                )
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
        }
        .navigationTitle("Edit Log")
        .confirmationDialog("Add Photo", isPresented: $showImageOptions) {
            Button("Take Photo") { showCamera = true }
            // Note: If you want library access, you'll need to add the PhotosPicker view hierarchy here or elsewhere
            Button("Choose from Library") { }
            Button("Cancel", role: .cancel) { }
        }
        .sheet(isPresented: $showCamera) {
            CameraPicker(selectedImage: $capturedImage)
        }
        .fullScreenCover(item: Binding(
            get: { selectedPhotoData.map { IdentifiableData(data: $0) } },
            set: { selectedPhotoData = $0?.data }
        )) { viewer in
            FullScreenImageViewer(imageData: viewer.data)
        }
        .onChange(of: capturedImage) { _, image in
            if let image = image {
                // Apply watermark using the extension
                let watermarkedImage = image.addWatermark(text: "RepScale.App")
                
                if let data = watermarkedImage.jpegData(compressionQuality: 0.8) {
                    let newPhoto = ProgressPhoto(imageData: data)
                    newPhoto.weightEntry = entry
                    modelContext.insert(newPhoto)
                }
            }
        }
    }
} // End of WeightEntryDetailView

// --- Moved to File Scope (Outside the main struct) ---

struct PhotoRowView: View {
    @Bindable var photo: ProgressPhoto
    let tags: [String]
    @Binding var selectedPhotoData: Data?

    var body: some View {
        VStack {
            if let uiImage = UIImage(data: photo.imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 120, height: 120)
                    .cornerRadius(8)
                    .onTapGesture {
                        selectedPhotoData = photo.imageData
                    }
            }
            Picker("Tag", selection: $photo.bodyTag) {
                ForEach(tags, id: \.self) { tag in
                    Text(tag).tag(tag)
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()
        }
    }
}

extension UIImage {
    func addWatermark(text: String) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            draw(in: CGRect(origin: .zero, size: size))
            
            let fontSize = size.height * 0.04
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: fontSize, weight: .bold),
                .foregroundColor: UIColor.white.withAlphaComponent(0.9),
                .strokeColor: UIColor.black.withAlphaComponent(0.6),
                .strokeWidth: -3.0
            ]
            
            let textSize = text.size(withAttributes: attributes)
            let padding = size.height * 0.03
            let rect = CGRect(
                x: size.width - textSize.width - padding,
                y: size.height - textSize.height - padding,
                width: textSize.width,
                height: textSize.height
            )
            
            text.draw(in: rect, withAttributes: attributes)
        }
    }
}
