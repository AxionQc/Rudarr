import SwiftUI

@Observable
class MediaCalendar {
    var instances: [Instance] = []
    var series: [Series.ID: Series] = [:]
    var dates: [TimeInterval] = []

    var movies: [TimeInterval: [Movie]] = [:]
    var episodes: [TimeInterval: [Episode]] = [:]

    var isLoading: Bool = false
    var isLoadingFuture: Bool = false

    var error: API.Error?
    var errorBinding: Binding<Bool> { .init(get: { self.error != nil }, set: { _ in }) }

    let gmt: Calendar = {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        return calendar
    }()

    let futureCutoff: TimeInterval = {
        Date().timeIntervalSince1970 + (365 * 86_400)
    }()

    let loadingOffset: Int = {
        UIDevice.current.userInterfaceIdiom == .phone ? 7 : 14
    }()

    func initialize() async {
        isLoading = true

        await fetch(
            start: addDays(-60, Date.now),
            end: addDays(30, Date.now),
            initial: true
        )

        isLoading = false
    }

    func loadFutureDates(_ timestamp: TimeInterval) async {
        isLoadingFuture = true

        let date = Date(timeIntervalSince1970: timestamp)
        await fetch(start: date, end: addDays(30, date))

        isLoadingFuture = false
    }

    func fetch(start: Date, end: Date, initial: Bool = false) async {
        error = nil

        let startMidnight = gmt.startOfDay(for: start)
        let endMidnight = gmt.startOfDay(for: end)

        do {
            for instance in instances where instance.type == .radarr {
                insertMovies(
                    try await dependencies.api.movieCalendar(startMidnight, endMidnight, instance)
                )
            }

            for instance in instances where instance.type == .sonarr {
                insertSeries(
                    try await dependencies.api.fetchSeries(instance)
                )

                insertEpisodes(
                    try await dependencies.api.episodeCalendar(startMidnight, endMidnight, instance)
                )
            }

            insertDates(startMidnight, endMidnight)
        } catch is CancellationError {
            // do nothing
        } catch let apiError as API.Error {
            error = apiError

            leaveBreadcrumb(.error, category: "calendar", message: "Request failed", data: ["error": apiError])
        } catch {
            self.error = API.Error(from: error)
        }
    }

    func addDays(_ days: Int, _ date: Date) -> Date {
        gmt.date(byAdding: .day, value: days, to: date)!
    }

    func insertDates(_ startMidnight: Date, _ endMidnight: Date) {
        guard startMidnight <= endMidnight else {
            fatalError("endMidnight < startMidnight")
        }

        var currentDay = startMidnight

        while currentDay <= endMidnight {
            if !dates.contains(currentDay.timeIntervalSince1970) {
                dates.append(currentDay.timeIntervalSince1970)
            }

            currentDay = addDays(1, currentDay)
        }
    }

    func insertMovies(_ movies: [Movie]) {
        for movie in movies {
            if let digitalRelease = movie.digitalRelease {
                maybeInsertMovie(movie, digitalRelease)
            }

            if let physicalRelease = movie.physicalRelease {
                maybeInsertMovie(movie, physicalRelease)
            }

            if let inCinemas = movie.inCinemas {
                maybeInsertMovie(movie, inCinemas)
            }
        }
    }

    func maybeInsertMovie(_ movie: Movie, _ date: Date) {
        let day = gmt.startOfDay(for: date).timeIntervalSince1970

        if movies[day] == nil {
            movies[day] = []
        }

        if movies[day]!.contains(where: { $0.id == movie.id }) {
            return
        }

        movies[day]!.append(movie)
    }

    func insertSeries(_ series: [Series]) {
        for item in series {
            self.series[item.id] = item
        }
    }

    func insertEpisodes(_ episodes: [Episode]) {
        for episode in episodes {
            if let airDate = episode.airDateUtc {
                maybeInsertEpisode(episode, airDate)
            }
        }
    }

    func maybeInsertEpisode(_ episode: Episode, _ date: Date) {
        let day = gmt.startOfDay(for: date).timeIntervalSince1970

        if episodes[day] == nil {
            episodes[day] = []
        }

        if episodes[day]!.contains(where: { $0.id == episode.id }) {
            return
        }

        episodes[day]!.append(episode)
    }

    func today() -> TimeInterval {
        gmt.startOfDay(for: Date.now).timeIntervalSince1970
    }

    func maybeLoadMoreDates(_ scrollPosition: TimeInterval?) {
        if isLoadingFuture || dates.isEmpty {
            return
        }

        guard let timestamp = scrollPosition, timestamp < futureCutoff else {
            return
        }

        if timestamp > dates[dates.count - loadingOffset] {
            Task {
                await loadFutureDates(dates.last!)
            }
        }
    }
}