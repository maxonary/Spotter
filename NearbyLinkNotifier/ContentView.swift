import SwiftUI
import CoreLocation

struct ErrorMessage: Identifiable {
    let id = UUID()
    let message: String
}

struct ContentView: View {
    @State private var links: [(link: Link, distance: Double)] = [] // Store links with distances
    @State private var errorMessage: ErrorMessage?
    private let notifiedLinksKey = "NotifiedLinks" // Key for UserDefaults storage
    private let locationManager = CLLocationManager() // To get user location

    var body: some View {
        NavigationView {
            List {
                // Show only notified links, sorted by proximity
                ForEach(links, id: \.link.link) { item in
                    Button(action: {
                        openLink(item.link.link) // Open link in Safari when clicked
                    }) {
                        VStack(alignment: .leading) {
                            // Show description if available; fallback to the link
                            if let description = item.link.description, !description.isEmpty {
                                Text(description)
                                    .font(.headline)
                                    .foregroundColor(.blue) // Indicate it is clickable
                            } else {
                                Text(item.link.link)
                                    .font(.headline)
                                    .foregroundColor(.blue) // Indicate it is clickable
                            }
                            
                            // Show location and distance
                            if let location = item.link.location, let lat = location["lat"], let lng = location["lng"] {
                                Text("Lat: \(lat), Lng: \(lng)")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                Text("Distance: \(String(format: "%.1f", item.distance)) meters")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
                .onDelete(perform: deleteLink) // Enable deletion
            }
            .onAppear(perform: fetchLinks)
            .navigationTitle("Collected Spots")
            .alert(item: $errorMessage) { error in
                Alert(title: Text("Error"), message: Text(error.message), dismissButton: .default(Text("OK")))
            }
        }
    }

    // Open the link in Safari
    func openLink(_ urlString: String) {
        guard let url = URL(string: urlString) else {
            self.errorMessage = ErrorMessage(message: "Invalid URL: \(urlString)")
            return
        }
        UIApplication.shared.open(url)
    }

    // Fetch links from the API and sort them by proximity
    func fetchLinks() {
        // Request user's location
        locationManager.requestWhenInUseAuthorization()
        guard let userLocation = locationManager.location else {
            self.errorMessage = ErrorMessage(message: "Unable to fetch user location.")
            return
        }

        APIService.shared.fetchAllLinks { fetchedLinks in
            DispatchQueue.main.async {
                if let fetchedLinks = fetchedLinks {
                    // Calculate distance for each link and sort
                    self.links = fetchedLinks
                        .compactMap { link in
                            if let lat = link.location?["lat"], let lng = link.location?["lng"] {
                                let linkLocation = CLLocation(latitude: lat, longitude: lng)
                                let distance = userLocation.distance(from: linkLocation)
                                return (link: link, distance: distance)
                            }
                            return nil
                        }
                        .filter { isLinkNotified($0.link.link) } // Show only notified links
                        .sorted(by: { $0.distance < $1.distance }) // Sort by proximity
                } else {
                    self.errorMessage = ErrorMessage(message: "Failed to fetch links.")
                }
            }
        }
    }

    // Delete a link from the list and remove it from notified links
    func deleteLink(at offsets: IndexSet) {
        offsets.forEach { index in
            let link = links[index].link
            removeLinkFromNotified(link.link) // Remove from UserDefaults
            links.remove(at: index) // Remove from UI list
        }
    }

    // MARK: - UserDefaults Helpers

    // Check if a link has already been notified
    private func isLinkNotified(_ link: String) -> Bool {
        let notifiedLinks = UserDefaults.standard.stringArray(forKey: notifiedLinksKey) ?? []
        return notifiedLinks.contains(link)
    }

    // Remove a link from the notified list
    private func removeLinkFromNotified(_ link: String) {
        var notifiedLinks = UserDefaults.standard.stringArray(forKey: notifiedLinksKey) ?? []
        if let index = notifiedLinks.firstIndex(of: link) {
            notifiedLinks.remove(at: index)
            UserDefaults.standard.set(notifiedLinks, forKey: notifiedLinksKey) // Update UserDefaults
        }
    }
}
