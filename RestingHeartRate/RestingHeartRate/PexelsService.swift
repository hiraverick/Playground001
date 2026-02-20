import Foundation

struct PexelsService {

    private let apiKey = "BtVtCdVT27bQX5xAzuGhH5kV9bTUC6Q0UXEXmctbMoNMM6A4NTkuxveD"
    private let baseURL = "https://api.pexels.com/videos/search"

    /// Picks a random search query for the zone and returns a streaming video URL.
    func fetchVideoURL(for zone: HRZone) async throws -> URL {
        let query = zone.searchQueries.randomElement() ?? "nature"

        var components = URLComponents(string: baseURL)!
        components.queryItems = [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "per_page", value: "15"),
            URLQueryItem(name: "orientation", value: "portrait"),
            URLQueryItem(name: "size", value: "medium"),
        ]

        var request = URLRequest(url: components.url!)
        request.setValue(apiKey, forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw PexelsError.badResponse
        }

        let decoded = try JSONDecoder().decode(PexelsResponse.self, from: data)

        guard let video = decoded.videos.randomElement() else {
            throw PexelsError.noVideos
        }

        // Prefer HD quality; fall back to any available file
        let file = video.videoFiles
            .filter { $0.quality == "hd" || $0.quality == "sd" }
            .sorted { ($0.width ?? 0) > ($1.width ?? 0) }
            .first ?? video.videoFiles.first

        guard let link = file?.link, let url = URL(string: link) else {
            throw PexelsError.noVideoFile
        }

        return url
    }
}

// MARK: - Errors

enum PexelsError: LocalizedError {
    case badResponse
    case noVideos
    case noVideoFile

    var errorDescription: String? {
        switch self {
        case .badResponse: return "Pexels returned an unexpected response."
        case .noVideos:    return "No videos found for this zone."
        case .noVideoFile: return "Video file URL unavailable."
        }
    }
}

// MARK: - Response Models

private struct PexelsResponse: Decodable {
    let videos: [PexelsVideo]
}

private struct PexelsVideo: Decodable {
    let videoFiles: [PexelsVideoFile]

    enum CodingKeys: String, CodingKey {
        case videoFiles = "video_files"
    }
}

private struct PexelsVideoFile: Decodable {
    let quality: String?   // Pexels returns null for HLS/adaptive streams
    let link: String
    let width: Int?
    let height: Int?
}
