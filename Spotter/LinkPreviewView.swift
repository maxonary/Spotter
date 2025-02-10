import SwiftUI
import LinkPresentation

struct LinkPreviewView: View {
    let url: URL
    @State private var metadata: LPLinkMetadata?
    @State private var isLoading = true // Track loading state

    var body: some View {
        VStack(alignment: .leading) {
            if isLoading {
                ProgressView().onAppear { fetchMetadata(for: url) }
            } else if let metadata = metadata {
                VStack {
                    if let imageProvider = metadata.imageProvider {
                        ImageView(imageProvider: imageProvider)
                            .frame(height: 150)
                            .cornerRadius(10)
                    } else {
                        // If no image is found, show a placeholder
                        Image(systemName: "photo")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 100)
                            .foregroundColor(.gray)
                    }

                    Text(metadata.title ?? "No Title")
                        .font(.headline)
                        .padding(.top, 5)

                    Text(metadata.url?.absoluteString ?? url.absoluteString)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white).shadow(radius: 3))
            } else {
                // If metadata is not found, show basic link
                VStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 50)
                        .foregroundColor(.yellow)
                    Text("No Preview Available")
                        .font(.headline)
                        .foregroundColor(.gray)
                    Text(url.absoluteString)
                        .font(.subheadline)
                        .foregroundColor(.blue)
                        .lineLimit(1)
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white).shadow(radius: 3))
            }
        }
    }

    // Fetch Metadata using LPMetadataProvider
    private func fetchMetadata(for url: URL) {
        let provider = LPMetadataProvider()
        provider.startFetchingMetadata(for: url) { metadata, error in
            DispatchQueue.main.async {
                self.isLoading = false // Stop loading
                if let metadata = metadata {
                    self.metadata = metadata
                } else {
                    print("Error fetching metadata: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
        }
    }
}

// Helper View for Rendering Images from LPMetadataProvider
struct ImageView: View {
    let imageProvider: NSItemProvider
    @State private var image: UIImage?

    var body: some View {
        if let image = image {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
        } else {
            ProgressView()
                .onAppear {
                    fetchImage()
                }
        }
    }

    private func fetchImage() {
        imageProvider.loadObject(ofClass: UIImage.self) { (object, error) in
            DispatchQueue.main.async {
                self.image = object as? UIImage
            }
        }
    }
}
