import CoreLocation
import UserNotifications

class LocationManager: NSObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    private let proximityThreshold: Double = 30.0 // Distance in meters
    private let notificationInterval: TimeInterval = 60 // Time interval in seconds
    private var lastNotificationDate: Date = Date.distantPast // Last time a notification was sent
    private var nearbyLocations: [Link] = [] // Locations fetched from the API
    private var sortedLocations: [(link: Link, distance: Double)] = [] // Sorted locations with distances

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization() // Request location permissions
        locationManager.startUpdatingLocation() // Start monitoring location
        fetchNearbyLinksFromAPI() // Fetch links from backend
    }

    // Fetch locations from the API
    private func fetchNearbyLinksFromAPI() {
        APIService.shared.fetchAllLinks { [weak self] fetchedLinks in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if let links = fetchedLinks {
                    self.nearbyLocations = links
                    print("Fetched \(links.count) locations from the API.")
                } else {
                    print("Failed to fetch locations from the API.")
                }
            }
        }
    }

    // Called whenever the user's location updates
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let userLocation = locations.last else { return }
        sortLocationsByDistance(userLocation: userLocation)
        checkProximityAndNotify(userLocation: userLocation)
    }

    // Sort locations by distance from the user's current location
    private func sortLocationsByDistance(userLocation: CLLocation) {
        sortedLocations = nearbyLocations.compactMap { location in
            if let lat = location.location?["lat"], let lng = location.location?["lng"] {
                let linkLocation = CLLocation(latitude: lat, longitude: lng)
                let distance = userLocation.distance(from: linkLocation)
                return (link: location, distance: distance)
            }
            return nil
        }
        .sorted(by: { $0.distance < $1.distance }) // Sort by ascending distance

        // print("Sorted locations by distance:")
        // for (link, distance) in sortedLocations {
        //     print("\(link.link) - \(distance) meters")
        // }
    }

    // Check proximity to links and send a notification if within proximityThreshold
    private func checkProximityAndNotify(userLocation: CLLocation) {
        for (link, distance) in sortedLocations {
            // print("Distance to \(link.link): \(distance) meters")

            if distance <= proximityThreshold {
                let timeSinceLastNotification = Date().timeIntervalSince(lastNotificationDate)

                if timeSinceLastNotification >= notificationInterval {
                    // Send notification with the link in userInfo
                    sendNotification(
                        title: "Nearby Link Found!",
                        body: "Check out this link: \(link.link)",
                        link: link.link
                    )
                    lastNotificationDate = Date() // Update last notification time
                }
            }
        }
    }

    // Send a local notification with the link in userInfo
    private func sendNotification(title: String, body: String, link: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.userInfo = ["link": link] // Include the link in userInfo

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil // Immediate notification
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error.localizedDescription)")
            } else {
                print("Notification triggered: \(title)")
            }
        }
    }
}
