import CoreLocation
import UserNotifications

class LocationManager: NSObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization() // Request location permissions
        locationManager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        let latitude = location.coordinate.latitude
        let longitude = location.coordinate.longitude
        
        print("Location updated: \(latitude), \(longitude)")
        fetchNearbyLinks(lat: latitude, lng: longitude)
    }
    
    func fetchNearbyLinks(lat: Double, lng: Double) {
        guard let url = URL(string: "https://your-backend-api.com/nearby-links?lat=\(lat)&lng=\(lng)") else { return }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil else { return }
            do {
                let links = try JSONDecoder().decode([Link].self, from: data)
                if let firstLink = links.first {
                    self.sendNotification(link: firstLink)
                }
            } catch {
                print("Error decoding JSON:", error)
            }
        }.resume()
    }
    
    func sendNotification(link: Link) {
        let content = UNMutableNotificationContent()
        content.title = "Nearby Content Available!"
        content.body = "Check out this link: \(link.link)"
        content.userInfo = ["link": link.link]
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}

struct Link: Decodable {
    let link: String
}
