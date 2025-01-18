//
//  NearbyLinkNotifierApp.swift
//  NearbyLinkNotifier
//
//  Created by Maximilian Arnold on 18.01.25.
//

import SwiftUI

@main
struct NearbyLinkNotifierApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    let locationManager = LocationManager() // Initialize the LocationManager
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
