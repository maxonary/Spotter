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
    @State private var links: [(link: SpotterLink, distance: Double)] = [] // Store links with distances
    @State private var errorMessage: ErrorMessage?
    private let notifiedLinksKey = "NotifiedLinks" // Key for UserDefaults storage
    private let locationManager = CLLocationManager() // To get user location

    var body: some View {
        NavigationView {
            List {
                ForEach(links, id: \.link.link) { item in
                    if let url = URL(string: item.link.link) {
                        LinkPreviewView(url: url) // Uses our new Link Preview Component
                    } else {
                        Text("Invalid URL")
                            .font(.headline)
                            .foregroundColor(.red)
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

    @State private var selectedLocation: LocationAnnotation? // Track selected pin

    var body: some View {
        NavigationView {
            ZStack {
                Map(position: $cameraPosition) {
                    ForEach(locations) { location in
                        Annotation(location.title, coordinate: location.coordinate) {
                            VStack {
                                Image(systemName: "mappin.circle.fill")
                                    .foregroundColor(.red)
                                    .font(.title)
                            }
                            .onTapGesture {
                                selectedLocation = location // Show tooltip overlay
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
                .ignoresSafeArea()

                // Show overlay when a pin is tapped
                if let selectedLocation = selectedLocation {
                    VStack {
                        Spacer()
                        LinkPreviewOverlay(location: selectedLocation) {
                            self.selectedLocation = nil // Close overlay when tapped
                        }
                    }
                    .transition(.move(edge: .bottom))
                    .animation(.spring(), value: selectedLocation)
                }
            }
            .navigationTitle("Discover")
            .onAppear(perform: fetchLocations)
        }
    }

    // Fetch locations from API
    private func fetchLocations() {
        APIService.shared.fetchAllLinks { fetchedLinks in
            DispatchQueue.main.async {
                if let fetchedLinks = fetchedLinks {
                    self.locations = fetchedLinks.compactMap { link in
                        if let lat = link.location?["lat"], let lng = link.location?["lng"] {
                            return LocationAnnotation(
                                id: UUID(),
                                title: link.description ?? "Unknown Location",
                                coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lng),
                                link: link.link,
                                imageURL: link.imageURL // Add image URL for preview
                            )
                        }
                        return nil
                    }
                    
                    // Adjust camera to first location
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

// MARK: - Location Data Model (Now Equatable)
struct LocationAnnotation: Identifiable, Equatable {
    let id: UUID
    let title: String
    let coordinate: CLLocationCoordinate2D
    let link: String
    let imageURL: String?

    // Conform to Equatable to fix the animation error
    static func == (lhs: LocationAnnotation, rhs: LocationAnnotation) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Link Preview Overlay
struct LinkPreviewOverlay: View {
    let location: LocationAnnotation
    let onClose: () -> Void

    var body: some View {
        VStack {
            VStack {
                HStack {
                    AsyncImage(url: URL(string: location.imageURL ?? "https://via.placeholder.com/100")) { image in
                        image.resizable().scaledToFit()
                    } placeholder: {
                        Image(systemName: "photo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 50, height: 50)
                            .foregroundColor(.gray)
                    }
                    .frame(width: 80, height: 80)
                    .cornerRadius(10)

                    VStack(alignment: .leading) {
                        Text(location.title)
                            .font(.headline)
                        Text(location.link)
                            .font(.subheadline)
                            .foregroundColor(.blue)
                            .lineLimit(1)
                    }
                    Spacer()
                    
                    Button(action: onClose) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                            .font(.title2)
                    }
                }
                .padding()

                Button(action: {
                    if let url = URL(string: location.link) {
                        UIApplication.shared.open(url)
                    }
                }) {
                    Text("Open Link")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
            }
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 15))
            .shadow(radius: 5)
            .padding()
        }
    }
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
