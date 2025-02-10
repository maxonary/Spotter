import SwiftUI

@main
struct NearbyLinkNotifierApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    let locationManager = LocationManager() // Initialize LocationManager

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
