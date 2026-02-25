import Foundation

struct VideoResult {
    let url: URL
    let creator: String
}

struct PexelsService {

    private let baseURL = "https://pexels-proxy.biometrics-api.workers.dev/videos/search"

    /// Picks a random search query for the zone and returns a streaming video URL + creator name.
    func fetchVideo(for zone: HRZone) async throws -> VideoResult {
        let query = zone.searchQueries.randomElement() ?? "nature"

        var components = URLComponents(string: baseURL)!
        components.queryItems = [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "per_page", value: "15"),
            URLQueryItem(name: "size", value: "medium"),
        ]

        var request = URLRequest(url: components.url!)
        request.timeoutInterval = 15

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

        return VideoResult(url: url, creator: video.user.name)
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
    let user: PexelsUser

    enum CodingKeys: String, CodingKey {
        case videoFiles = "video_files"
        case user
    }
}

private struct PexelsUser: Decodable {
    let name: String
}

private struct PexelsVideoFile: Decodable {
    let quality: String?   // Pexels returns null for HLS/adaptive streams
    let link: String
    let width: Int?
    let height: Int?
}
