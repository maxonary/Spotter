import SwiftUI
import CoreLocation
import MapKit

struct ErrorMessage: Identifiable {
    let id = UUID()
    let message: String
}

struct ContentView: View {
    var body: some View {
        TabView {
            CollectedSpotsView() // Your existing list logic
                .tabItem {
                    Image(systemName: "questionmark.circle")
                    Text("Now")
                }
            
            DiscoverView()
                .tabItem {
                    Image(systemName: "binoculars")
                    Text("Discover")
                }
            
            FriendsView()
                .tabItem {
                    Image(systemName: "bubble")
                    Text("Friends")
                }
            
            MeView()
                .tabItem {
                    Image(systemName: "person.circle")
                    Text("Me")
                }
        }
        .accentColor(.blue) // Customize tab highlight color
    }
}

// Your existing view logic moved into a separate struct
struct CollectedSpotsView: View {
    @State private var links: [(link: Link, distance: Double)] = [] // Store links with distances
    @State private var errorMessage: ErrorMessage?
    private let notifiedLinksKey = "NotifiedLinks" // Key for UserDefaults storage
    private let locationManager = CLLocationManager() // To get user location

    var body: some View {
        NavigationView {
            List {
                ForEach(links, id: \.link.link) { item in
                    Button(action: {
                        openLink(item.link.link)
                    }) {
                        VStack(alignment: .leading) {
                            if let description = item.link.description, !description.isEmpty {
                                Text(description)
                                    .font(.headline)
                                    .foregroundColor(.blue)
                            } else {
                                Text(item.link.link)
                                    .font(.headline)
                                    .foregroundColor(.blue)
                            }
                            
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
                .onDelete(perform: deleteLink)
            }
            .onAppear(perform: fetchLinks)
            .navigationTitle("Collected Spots")
            .alert(item: $errorMessage) { error in
                Alert(title: Text("Error"), message: Text(error.message), dismissButton: .default(Text("OK")))
            }
        }
    }

    func openLink(_ urlString: String) {
        guard let url = URL(string: urlString) else {
            self.errorMessage = ErrorMessage(message: "Invalid URL: \(urlString)")
            return
        }
        UIApplication.shared.open(url)
    }

    func fetchLinks() {
        locationManager.requestWhenInUseAuthorization()
        guard let userLocation = locationManager.location else {
            self.errorMessage = ErrorMessage(message: "Unable to fetch user location.")
            return
        }

        APIService.shared.fetchAllLinks { fetchedLinks in
            DispatchQueue.main.async {
                if let fetchedLinks = fetchedLinks {
                    self.links = fetchedLinks
                        .compactMap { link in
                            if let lat = link.location?["lat"], let lng = link.location?["lng"] {
                                let linkLocation = CLLocation(latitude: lat, longitude: lng)
                                let distance = userLocation.distance(from: linkLocation)
                                return (link: link, distance: distance)
                            }
                            return nil
                        }
                        .filter { isLinkNotified($0.link.link) }
                        .sorted(by: { $0.distance < $1.distance })
                } else {
                    self.errorMessage = ErrorMessage(message: "Failed to fetch links.")
                }
            }
        }
    }

    func deleteLink(at offsets: IndexSet) {
        offsets.forEach { index in
            let link = links[index].link
            removeLinkFromNotified(link.link)
            links.remove(at: index)
        }
    }

    private func isLinkNotified(_ link: String) -> Bool {
        let notifiedLinks = UserDefaults.standard.stringArray(forKey: notifiedLinksKey) ?? []
        return notifiedLinks.contains(link)
    }

    private func removeLinkFromNotified(_ link: String) {
        var notifiedLinks = UserDefaults.standard.stringArray(forKey: notifiedLinksKey) ?? []
        if let index = notifiedLinks.firstIndex(of: link) {
            notifiedLinks.remove(at: index)
            UserDefaults.standard.set(notifiedLinks, forKey: notifiedLinksKey)
        }
    }
}

struct DiscoverView: View {
    @State private var locations: [LocationAnnotation] = [] // Store locations
    
    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194), // Default: San Francisco
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )
    )

    var body: some View {
        NavigationView {
            Map(position: $cameraPosition) {
                ForEach(locations) { location in
                    Annotation(location.title, coordinate: location.coordinate) {
                        VStack {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundColor(.red)
                                .font(.title)
                            Text(location.title)
                                .font(.caption)
                                .padding(5)
                                .background(Color.white.opacity(0.7))
                                .cornerRadius(5)
                        }
                        .onTapGesture {
                            cameraPosition = .region(
                                MKCoordinateRegion(
                                    center: location.coordinate,
                                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                                )
                            )
                        }
                    }
                }
            }
            .navigationTitle("Discover")
            .onAppear(perform: fetchLocations) // Fetch locations when view appears
        }
    }

    // Fetch all locations from API
    private func fetchLocations() {
        APIService.shared.fetchAllLinks { fetchedLinks in
            DispatchQueue.main.async {
                if let fetchedLinks = fetchedLinks {
                    self.locations = fetchedLinks.compactMap { link in
                        if let lat = link.location?["lat"], let lng = link.location?["lng"] {
                            return LocationAnnotation(
                                title: link.description ?? "Unknown Location",
                                coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lng)
                            )
                        }
                        return nil
                    }
                    
                    // Adjust camera to first location if available
                    if let firstLocation = self.locations.first {
                        cameraPosition = .region(
                            MKCoordinateRegion(
                                center: firstLocation.coordinate,
                                span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
                            )
                        )
                    }
                }
            }
        }
    }
}

// Location Annotation Struct
struct LocationAnnotation: Identifiable {
    let id = UUID()
    let title: String
    let coordinate: CLLocationCoordinate2D
}

struct FriendsView: View {
    var body: some View {
        NavigationView {
            Text("Friends Screen Coming Soon")
                .font(.largeTitle)
                .navigationTitle("Friends")
        }
    }
}

struct MeView: View {
    var body: some View {
        NavigationView {
            Text("Me Screen Coming Soon")
                .font(.largeTitle)
                .navigationTitle("Me")
        }
    }
}

// Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
