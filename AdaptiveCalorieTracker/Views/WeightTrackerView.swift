import SwiftUI
import SwiftData

struct WeightTrackerView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WeightEntry.date, order: .reverse) private var weights: [WeightEntry]
    
    @State private var showingAddWeight = false
    @State private var newWeight: String = ""

    var body: some View {
        NavigationView {
            List {
                ForEach(weights) { entry in
                    HStack {
                        Text(entry.date, style: .date)
                        Spacer()
                        Text("\(entry.weight, specifier: "%.1f") kg")
                            .fontWeight(.semibold)
                    }
                }
                .onDelete(perform: deleteWeight)
            }
            .navigationTitle("Weight History")
            .toolbar {
                Button(action: { showingAddWeight = true }) {
                    Image(systemName: "plus")
                }
            }
            .sheet(isPresented: $showingAddWeight) {
                VStack(spacing: 20) {
                    Text("Add Weight").font(.headline)
                    TextField("Enter weight (kg)", text: $newWeight)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.decimalPad)
                        .padding()
                    
                    Button("Save") {
                        if let weightDouble = Double(newWeight) {
                            let entry = WeightEntry(weight: weightDouble)
                            modelContext.insert(entry)
                            newWeight = ""
                            showingAddWeight = false
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .presentationDetents([.medium])
            }
        }
    }

    private func deleteWeight(offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(weights[index])
        }
    }
}
