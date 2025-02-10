import UIKit
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    // Called when the app finishes launching
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Set the delegate for UNUserNotificationCenter
        UNUserNotificationCenter.current().delegate = self

        // Request notification permissions
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notifications authorized.")
            } else {
                print("Notification authorization denied.")
            }
        }

        // NOTE: No need to register for remote notifications if you're only using local notifications.
        return true
    }
    
    // Handle notification when app is in the foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show banner and play sound even when the app is in the foreground
        completionHandler([.banner, .sound])
    }

    // Handle notification tap when the app is in the background or closed
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // Handle any actions upon tapping the notification
        if let link = response.notification.request.content.userInfo["link"] as? String,
           let url = URL(string: link) {
            // Open the link in Safari
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
        completionHandler()
    }
    
    // Function to trigger a test notification
    func triggerTestNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Test Notification"
        content.body = "This is a test notification to ensure everything is working."
        content.sound = .default
        
        // You can add additional data to the notification using `userInfo`
        content.userInfo = ["link": "https://example.com"]

        // Create a request for an immediate notification
        let request = UNNotificationRequest(
            identifier: UUID().uuidString, // Unique identifier
            content: content,
            trigger: nil // No trigger means the notification is sent immediately
        )

        // Add the notification request to UNUserNotificationCenter
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error.localizedDescription)")
            } else {
                print("Test notification triggered successfully.")
            }
        }
    }
}
