import SwiftUI

// movie.remoteFanart ???

struct MovieDetails: View {
    var movie: Movie

    @State private var isTruncated = true

    @Environment(RadarrInstance.self) private var instance

    var body: some View {
        VStack(alignment: .leading) {
            // MARK: overview
            HStack(alignment: .top) {
                CachedAsyncImage(url: movie.remotePoster)
                    .scaledToFit()
                    .frame(height: 195)
                    .clipped()
                    .cornerRadius(8)
                    .padding(.trailing, 8)

                Group {
                    VStack(alignment: .leading, spacing: 8) {

                        HStack(alignment: .top) {
                            Image(systemName: movie.monitored ? "bookmark.fill" : "bookmark")
                                .font(.title)

                            Text(movie.title)
                                .font(.title)
                                .fontWeight(.bold)
                                .kerning(-0.5)
                                .lineLimit(2)
                        }

                        HStack(spacing: 12) {
                            Text(movie.certification ?? "test")
                                .padding(.horizontal, 4)
                                .border(.secondary)

                            Text(String(movie.year))

                            Text(movie.humanRuntime)
                        }
                        .foregroundStyle(.secondary)

//                        HStack(spacing: 8) {
//
//                            Text(movie.monitored ? "Monitored" : "Unmonitored")
//                        }

                        if movie.hasFile {
                            Label("Downloaded", systemImage: "checkmark")
                        } else {
                            Label("Missing", systemImage: "questionmark.folder")
                        }

                        // Downloaded
                        // Missing

                        // Announced (Joker)
                        // In Cinemas (Mean Girls)
                        // (Released)

                        // tvdb, imdb, rotten 2x
                    }
                }

                Spacer()
            }
            .padding(.bottom)

            // MARK: description
            HStack(alignment: .top) {
                Text(movie.overview!)
                    .font(.callout)
                    .transition(.slide)
                    .lineLimit(isTruncated ? 4 : nil)
                    .onTapGesture {
                        withAnimation { isTruncated.toggle() }
                    }

                Spacer()
            }
            .padding(.bottom)

            // MARK: details
            Grid(alignment: .leading) {
                detailsRow("Status", value: movie.status.label)

                detailsRow("Studio", value: movie.studio!)

                if !movie.genres.isEmpty {
                    detailsRow("Genre", value: movie.humanGenres)
                }

                if movie.hasFile {
                    detailsRow("Video", value: videoQuality)
                    detailsRow("Audio", value: audioQuality)
                }
            }.padding(.bottom)

            // MARK: actions
            HStack(spacing: 24) {
                Button {
                    //
                } label: {
                    Label("Automatic", systemImage: "magnifyingglass")
                        .font(.callout)
                        .fontWeight(.semibold)
                        .padding(.vertical, 6)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)

                Button {
                    //
                } label: {
                    Label("Interactive", systemImage: "person.fill")
                        .font(.callout)
                        .fontWeight(.semibold)
                        .padding(.vertical, 6)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)
            }
            .fixedSize(horizontal: false, vertical: true)
            .padding(.bottom)

            // MARK: information
            Section(
                header: Text("Information")
                    .font(.title2)
                    .fontWeight(.bold)
            ) {
                VStack(spacing: 12) {
                    informationRow("Quality Profile", value: qualityProfile)
                    Divider()
                    informationRow("Minimum Availability", value: movie.minimumAvailability.label)
                    Divider()
                    informationRow("Root Folder", value: movie.rootFolderPath ?? "")

                    if movie.hasFile {
                        Divider()
                        informationRow("Size", value: movie.sizeOnDisk == nil ? "" : movie.humanSize)
                    }
                }
            }
            .font(.callout)
            .padding(.bottom)

            // MARK: ...
//            Grid(alignment: .leading) {
//                if let inCinemas = movie.inCinemas {
//                    detailsRow("In Cinemas", value: inCinemas.formatted(.dateTime.day().month().year()))
//                }
//
//                detailsRow("Physical Release", value: "")
//                detailsRow("Digital Release", value: "")
//            }
//            .border(.gray)

            // TODO: files section...
        }
    }

    var videoQuality: String {
        var label = ""
        var codec = ""

        if let resolution = movie.movieFile?.quality.quality.resolution {
            label = "\(resolution)p"
        }

        if let videoCodec = movie.movieFile?.mediaInfo.videoCodec {
            codec = videoCodec
        }

        if label.isEmpty {
            label = "Unknown"
        }

        return "\(label) (\(codec))"
    }

    var audioQuality: String {
        var languages: [String] = []
        var codec = ""

        if let langs = movie.movieFile?.languages {
            languages = langs
                .filter { $0.name != nil }
                .map { $0.name ?? "Unknown" }
        }

        if let audioCodec = movie.movieFile?.mediaInfo.audioCodec {
            codec = audioCodec
        }

        if languages.isEmpty {
            languages.append("Unknown")
        }

        let languageList = languages.joined(separator: ", ")

        return "\(languageList) (\(codec))"
    }

    var qualityProfile: String {
        return instance.qualityProfiles.first(
            where: { $0.id == movie.qualityProfileId }
        )?.name ?? "Unknown"
    }

    func detailsRow(_ label: String, value: String) -> some View {
        GridRow {
            Text(label)
                .textCase(.uppercase)
                .foregroundStyle(.secondary)
                .fontWeight(.medium)
                .padding(.trailing)
            Text(value)
            Spacer()
        }
        .font(.callout)
    }

    func informationRow(_ label: String, value: String) -> some View {
        LabeledContent {
            Text(value).foregroundStyle(.primary)
        } label: {
            Text(label).foregroundStyle(.secondary)
        }
    }
}

#Preview {
    let movies: [Movie] = PreviewData.load(name: "movies")

    return MovieSearchSheet(movie: movies[232])
        .withAppState()
}