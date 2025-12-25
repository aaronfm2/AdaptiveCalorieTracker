import HealthKit

class HealthManager: ObservableObject {
    let healthStore = HKHealthStore()
    @Published var caloriesBurnedToday: Double = 0

    func requestAuthorization() {
        let typesToRead: Set = [
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
        ]

        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
            if success {
                self.fetchTodayCaloriesBurned()
            }
        }
    }

    func fetchTodayCaloriesBurned() {
        let caloriesType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)

        let query = HKStatisticsQuery(quantityType: caloriesType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
            guard let result = result, let sum = result.sumQuantity() else {
                print("HealthKit Error: \(error?.localizedDescription ?? "No data found")")
                return
            }
            
            let value = sum.doubleValue(for: HKUnit.kilocalorie())
            print("Fetched calories from HealthKit: \(value)") // DEBUG LINE
            
            DispatchQueue.main.async {
                self.caloriesBurnedToday = value
            }
        }
        healthStore.execute(query)
    }
}
