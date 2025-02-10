import SwiftUI

@main
struct SpotterApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    let locationManager = LocationManager() // Initialize LocationManager

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
