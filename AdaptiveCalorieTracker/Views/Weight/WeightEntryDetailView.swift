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
                                    Picker("Tag", selection: Bindable(photo).bodyTag) {
                                        ForEach(tags, id: \.self) { tag in
                                            Text(tag).tag(tag)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                    .labelsHidden()
                                }
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
            // Using a hidden PhotosPicker controlled by a state is cleaner than nested buttons
            Button("Choose from Library") { /* Triggered via PhotosPicker overlay */ }
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
            if let image = image, let data = image.jpegData(compressionQuality: 0.8) {
                let newPhoto = ProgressPhoto(imageData: data)
                newPhoto.weightEntry = entry
                modelContext.insert(newPhoto)
            }
        }
    }
}
