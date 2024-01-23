import Foundation

extension API {
    static var mock: Self {
        .init(fetchMovies: { _ in
           loadPreviewData(filename: "movies")
        }, lookupMovies: { _, query in
            let allMovieLookups: [MovieLookup] = loadPreviewData(filename: "movie-lookup")

            return allMovieLookups.filter {
                $0.title.localizedCaseInsensitiveContains(query)
            }
        }, systemStatus: { _ in
            loadPreviewData(filename: "system-status")
        })
    }
}

fileprivate extension API {
    static func loadPreviewData<Model: Decodable>(filename: String) -> Model {
        if let path = Bundle.main.path(forResource: filename, ofType: "json") {
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601

                let data = try Data(contentsOf: URL(fileURLWithPath: path))

                return try decoder.decode(Model.self, from: data)
            } catch {
                fatalError("Preview data `\(filename)` could not be decoded")
            }
        }

        fatalError("Preview data `\(filename)` not found")
    }
}