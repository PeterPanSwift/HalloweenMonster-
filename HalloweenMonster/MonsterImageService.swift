import UIKit

struct FetchedImage {
    let image: UIImage
    let url: URL
    let credit: String
}

enum MonsterImageError: LocalizedError {
    case badResponse
    case notAnImage
    case noResults

    var errorDescription: String? {
        switch self {
        case .badResponse: return "伺服器沒有回應怪物 👻"
        case .notAnImage: return "抓到的不是圖片"
        case .noResults: return "沒有找到怪物圖片"
        }
    }
}

/// Fetches monster pictures from the internet.
struct MonsterImageService {
    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 20
        config.httpAdditionalHeaders = [
            // Wikimedia asks API clients to identify themselves.
            "User-Agent": "HalloweenMonster/1.0 (https://github.com/PeterPanSwift/HalloweenMonster-)"
        ]
        return URLSession(configuration: config)
    }()

    private static let wikimediaQueries = [
        "halloween monster costume", "jack-o'-lantern carved pumpkin", "halloween zombie costume",
        "halloween vampire costume", "werewolf costume", "halloween skeleton decoration",
        "halloween witch costume", "halloween ghost decoration", "frankenstein monster costume",
    ]

    func fetch(from source: ImageSource, seed: String) async throws -> FetchedImage {
        switch source {
        case .robohash:
            return try await fetchRobohash(seed: seed)
        case .wikimedia:
            do {
                return try await fetchWikimedia()
            } catch is CancellationError {
                throw CancellationError()
            } catch {
                // Wikimedia search results vary; never leave the user without a monster.
                return try await fetchRobohash(seed: seed)
            }
        }
    }

    /// Robohash "set2" is a set of generated monster faces.
    private func fetchRobohash(seed: String) async throws -> FetchedImage {
        var components = URLComponents(string: "https://robohash.org/")!
        components.path = "/\(seed).png"
        components.queryItems = [
            URLQueryItem(name: "set", value: "set2"),
            URLQueryItem(name: "size", value: "600x600"),
        ]
        let url = components.url!
        let image = try await download(url)
        return FetchedImage(image: image, url: url, credit: "圖片來源：Robohash.org")
    }

    /// Searches Wikimedia Commons for Halloween monster pictures and picks one at random.
    private func fetchWikimedia() async throws -> FetchedImage {
        let query = Self.wikimediaQueries.randomElement()!
        var pages = try await searchWikimedia(query: query, offset: Int.random(in: 0...40))
        if pages.isEmpty {
            pages = try await searchWikimedia(query: query, offset: 0)
        }
        guard let page = pages.randomElement(),
              let info = page.imageinfo?.first,
              let thumb = URL(string: info.thumburl ?? info.url) else {
            throw MonsterImageError.noResults
        }
        let image = try await download(thumb)
        let title = page.title.replacingOccurrences(of: "File:", with: "")
        return FetchedImage(image: image, url: thumb, credit: "圖片來源：Wikimedia Commons – \(title)")
    }

    private func searchWikimedia(query: String, offset: Int) async throws -> [WikimediaResponse.Page] {
        var components = URLComponents(string: "https://commons.wikimedia.org/w/api.php")!
        components.queryItems = [
            URLQueryItem(name: "action", value: "query"),
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "formatversion", value: "2"),
            URLQueryItem(name: "generator", value: "search"),
            URLQueryItem(name: "gsrsearch", value: "\(query) filetype:bitmap"),
            URLQueryItem(name: "gsrnamespace", value: "6"),
            URLQueryItem(name: "gsrlimit", value: "20"),
            URLQueryItem(name: "gsroffset", value: String(offset)),
            URLQueryItem(name: "prop", value: "imageinfo"),
            URLQueryItem(name: "iiprop", value: "url"),
            URLQueryItem(name: "iiurlwidth", value: "600"),
        ]
        let (data, response) = try await session.data(from: components.url!)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw MonsterImageError.badResponse }
        let decoded = try JSONDecoder().decode(WikimediaResponse.self, from: data)
        return decoded.query?.pages ?? []
    }

    private func download(_ url: URL) async throws -> UIImage {
        let (data, response) = try await session.data(from: url)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw MonsterImageError.badResponse }
        guard let image = UIImage(data: data) else { throw MonsterImageError.notAnImage }
        return image
    }
}

private struct WikimediaResponse: Decodable {
    struct Query: Decodable {
        let pages: [Page]?
    }

    struct Page: Decodable {
        let title: String
        let imageinfo: [ImageInfo]?
    }

    struct ImageInfo: Decodable {
        let url: String
        let thumburl: String?
    }

    let query: Query?
}
