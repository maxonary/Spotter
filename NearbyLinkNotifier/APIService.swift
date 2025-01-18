import Foundation

class APIService {
    static let shared = APIService()
    private let baseURL = "http://192.168.10.119:8000" // Replace with your backend's IP

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
                let links = try JSONDecoder().decode([Link].self, from: data)
                completion(links)
            } catch {
                print("Error decoding response: \(error.localizedDescription)")
                completion(nil)
            }
        }.resume()
    }

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
