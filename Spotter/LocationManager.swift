import CoreLocation
import UserNotifications

class LocationManager: NSObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    private let proximityThreshold: Double = 30.0 // Distance in meters
    private var nearbyLocations: [SpotterLink] = [] // Locations fetched from the API
    private var sortedLocations: [(link: SpotterLink, distance: Double)] = [] // Sorted locations with distances
    private let notifiedLinksKey = "NotifiedLinks" // Key for UserDefaults storage
    private var fetchTimer: Timer? // Timer for periodic fetching

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization() // Request location permissions
        locationManager.startUpdatingLocation() // Start monitoring location

        // Start fetching locations every 5 seconds
        startFetchingLocations()
    }

    // Start the timer to fetch locations every 5 seconds
    private func startFetchingLocations() {
        fetchTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.fetchNearbyLinksFromAPI()
        }
    }

    // Stop the timer when needed
    private func stopFetchingLocations() {
        fetchTimer?.invalidate()
        fetchTimer = nil
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
        notifyForNearbyLocations(userLocation: userLocation)
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
    }

    // Notify for nearby locations immediately if within proximityThreshold
    private func notifyForNearbyLocations(userLocation: CLLocation) {
        for (link, distance) in sortedLocations {
            // Check if the location is within proximity threshold
            if distance <= proximityThreshold {
                // Ensure the link hasn't been notified yet
                if !isLinkNotified(link.link) {
                    // Variables for notification content
                    let title: String
                    let body: String

                    // Check if the description exists
                    if let description = link.description, !description.isEmpty {
                        let website = getWebsiteName(from: link.link)
                        title = "Spotter via \(website)"
                        body = "\(description)"
                    } else {
                        let website = getWebsiteName(from: link.link)
                        title = "Spotter via \(website)"
                        body = "Check out this link: \(link.link)"
                    }

                    // Send notification
                    sendNotification(
                        title: title,
                        body: body,
                        link: link.link
                    )

                    // Mark link as notified
                    markLinkAsNotified(link.link)
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

    // Extract website name from a URL
    private func getWebsiteName(from url: String) -> String {
        if let host = URL(string: url)?.host {
            let components = host.split(separator: ".")
            if components.count > 1 {
                return components[1].capitalized // Extract the second component (e.g., "instagram" from "www.instagram.com")
            } else {
                return host.capitalized
            }
        }
        return "Website"
    }

    // MARK: - UserDefaults Helpers

    // Check if a link has already been notified
    private func isLinkNotified(_ link: String) -> Bool {
        let notifiedLinks = UserDefaults.standard.stringArray(forKey: notifiedLinksKey) ?? []
        return notifiedLinks.contains(link)
    }

    // Mark a link as notified
    private func markLinkAsNotified(_ link: String) {
        var notifiedLinks = UserDefaults.standard.stringArray(forKey: notifiedLinksKey) ?? []
        notifiedLinks.append(link)
        UserDefaults.standard.set(notifiedLinks, forKey: notifiedLinksKey)
    }
}
