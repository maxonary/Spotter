import UIKit
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Request notification permissions
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notifications authorized.")
            } else {
                print("Notification authorization denied.")
            }
        }

        // Register with APNs
        application.registerForRemoteNotifications()

        return true
    }

    // Called when the app successfully registers with APNs
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let tokenParts = deviceToken.map { String(format: "%02.2hhx", $0) }
        let token = tokenParts.joined()
        print("Device Token: \(token)")
        // Send the token to your server
    }

    // Called when the app fails to register with APNs
    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("Failed to register for remote notifications: \(error.localizedDescription)")
    }

    // Handle incoming push notifications
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        if let link = response.notification.request.content.userInfo["link"] as? String,
           let url = URL(string: link) {
            UIApplication.shared.open(url)
        }
        completionHandler()
    }
}
