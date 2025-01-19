import Foundation

class APIService {
    static let shared = APIService()
    private let baseURL = "https://api-meme-map.onrender.com" // Replace with the backend's IP

    // Fetch all links from the backend
    func fetchAllLinks(completion: @escaping ([Link]?) -> Void) {
        guard let url = URL(string: "\(baseURL)/all-links") else {
            print("Invalid URL")
            completion(nil)
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error fetching links: \(error.localizedDescription)")
                completion(nil)
                return
            }

            guard let data = data else {
                print("No data received")
                completion(nil)
                return
            }

            do {
                // Decode the response to an array of Link objects
                let links = try JSONDecoder().decode([Link].self, from: data)
                completion(links)
            } catch {
                print("Error decoding response: \(error.localizedDescription)")
                completion(nil)
            }
        }.resume()
    }

    // Delete a link from the backend
    func deleteLink(_ link: String, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "\(baseURL)/delete-link?link=\(link)") else {
            print("Invalid URL")
            completion(false)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"

        URLSession.shared.dataTask(with: request) { _, response, error in
            if let error = error {
                print("Error deleting link: \(error.localizedDescription)")
                completion(false)
                return
            }

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("Failed to delete link")
                completion(false)
                return
            }

            completion(true)
        }.resume()
    }
}
