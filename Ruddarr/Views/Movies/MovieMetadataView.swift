import SwiftUI

struct MovieMetadataView: View {
    @Binding var movie: Movie

    @EnvironmentObject var settings: AppSettings
    @Environment(RadarrInstance.self) private var instance

    @State private var videoExpanded: Bool = false
    @State private var audioExpanded: Bool = false

    @State private var fileSheet: MovieFile?
    @State private var eventSheet: MovieHistoryEvent?

    var body: some View {
        ScrollView {
            Group {
                files
                history
            }
            .padding(.bottom)
            .viewPadding(.horizontal)
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            instance.metadata.setMovie(movie)
        }
        .refreshable {
            await instance.metadata.fetchFiles(for: movie)
            await instance.metadata.fetchHistory(for: movie)
        }
    }

    var files: some View {
        Section {
            if instance.metadata.loadingFiles {
                ProgressView().tint(.secondary)
            } else if instance.metadata.failedFiles {
                noContent("An Error Occurred", icon: "exclamationmark.triangle")
            } else if instance.metadata.files.isEmpty && instance.metadata.extraFiles.isEmpty {
                noContent("Movie Has No Files", icon: "folder")
            } else {
                ForEach(instance.metadata.files) { file in
                    MovieFilesFile(file: file)
                        .padding(.bottom, 8)
                        .onTapGesture { fileSheet = file }
                }

                ForEach(instance.metadata.extraFiles) { file in
                    MovieFilesExtraFile(file: file)
                        .padding(.bottom, 8)
                }
            }
        } header: {
            Text("Files")
                .font(.title.bold())
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .task {
            await instance.metadata.fetchFiles(for: movie)
        }
        .sheet(item: $fileSheet) { file in
            MovieFileSheet(file: file)
                .presentationDetents([.medium])
        }
    }

    var history: some View {
        Section {
            if instance.metadata.loadingHistory {
                ProgressView().tint(.secondary)
            } else if instance.metadata.failedFiles {
                noContent("An Error Occurred", icon: "exclamationmark.triangle")
            } else if instance.metadata.history.isEmpty {
                noContent("Movie Has No History", icon: "clock.arrow.circlepath")
            } else {
                ForEach(instance.metadata.history) { event in
                    MovieHistoryItem(event: event)
                        .padding(.bottom, 8)
                        .onTapGesture { eventSheet = event }
                }
            }
        } header: {
            Text("History")
                .font(.title.bold())
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .task {
            await instance.metadata.fetchHistory(for: movie)
        }
        .sheet(item: $eventSheet) { event in
            MovieHistoryEventSheet(event: event)
                .presentationDetents(
                    event.eventType == .grabbed ? [.medium] : [.fraction(0.25)]
                )
        }
    }

    func noContent(_ label: LocalizedStringKey, icon: String) -> some View {
        GroupBox {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundStyle(settings.theme.tint)
                    .imageScale(.large)

                Text(label)
                    .font(.callout)
                    .fontWeight(.semibold)
            }
            .padding(.vertical)
            .frame(maxWidth: .infinity)
        }
        .padding(.bottom)
    }
}

struct MovieFilesFile: View {
    var file: MovieFile

    var body: some View {
        GroupBox {
            HStack(spacing: 6) {
                Text(file.quality.quality.label)
                Bullet()
                Text(file.languageLabel)
                Bullet()
                Text(file.sizeLabel)
                Spacer()
            }
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        } label: {
            Text(file.relativePath ?? "--")
                .padding(.bottom, 2)
        }
    }
}

struct MovieFilesExtraFile: View {
    var file: MovieExtraFile

    var body: some View {
        GroupBox {
            HStack(spacing: 6) {
                Text(file.type.label)
                Spacer()
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        } label: {
            Text(file.relativePath ?? "--")
                .padding(.bottom, 2)
        }
    }
}

struct MovieHistoryItem: View {
    var event: MovieHistoryEvent

    @EnvironmentObject var settings: AppSettings

    var body: some View {
        GroupBox {
            HStack(spacing: 6) {
                Text(event.quality.quality.label)
                Bullet()
                Text(event.languageLabel)
                Spacer()
                Text(date)
            }
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        } label: {
            Text(event.eventType.label)
                .foregroundStyle(settings.theme.tint)
                .font(.caption)
                .fontWeight(.semibold)
                .textCase(.uppercase)
                .tracking(1.1)
                .foregroundStyle(settings.theme.tint)

            Text(title ?? "--")
        }
    }

    var title: String? {
        guard let title = event.sourceTitle else { return nil }
        guard title.hasPrefix("/") else { return title }
        return title.components(separatedBy: "/").last
    }

    var date: String {
        if event.date < Calendar.current.date(byAdding: .day, value: -30, to: Date())! {
            return event.date.formatted(date: .abbreviated, time: .omitted)
        }

        return event.date.formatted(
            .relative(presentation: .named, unitsStyle: .narrow)
        )
    }
}

#Preview {
    let movies: [Movie] = PreviewData.load(name: "movies")
    let movie = movies.first(where: { $0.id == 295 }) ?? movies[0]

    dependencies.router.selectedTab = .movies

    dependencies.router.moviesPath.append(
        MoviesView.Path.movie(movie.id)
    )

    dependencies.router.moviesPath.append(
        MoviesView.Path.metadata(movie.id)
    )

    return ContentView()
        .withSettings()
        .withRadarrInstance(movies: movies)
}