import SwiftUI

@main
struct Day3HomeworkApp: App {
    
    init() {
        if UserDefaults.standard.object(forKey: "count") == nil {
            UserDefaults.standard.set(0, forKey: "count")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
