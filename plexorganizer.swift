#!/usr/bin/env swift

import Foundation

struct Counts {
    var directories = 0
    var movies = 0
    var moviesSkipped = 0
    var tvShows = 0
    var tvShowsSkipped = 0
}

func printUsage() {
    let programName = URL(fileURLWithPath: CommandLine.arguments[0]).lastPathComponent
    print("Usage: \(programName) <source> <destination>")
}

func runFFmpegMetadata(for fileURL: URL) -> [String: String]? {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    process.arguments = ["ffmpeg", "-y", "-loglevel", "error", "-i", fileURL.path, "-f", "ffmetadata", "-"]

    let outputPipe = Pipe()
    process.standardOutput = outputPipe
    process.standardError = outputPipe

    do {
        try process.run()
    } catch {
        print("Failed to run ffmpeg on \(fileURL.path): \(error)")
        return nil
    }

    let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
    process.waitUntilExit()

    guard process.terminationStatus == 0 else {
        return nil
    }

    guard let outputString = String(data: outputData, encoding: .utf8) else {
        return nil
    }

    var metadata = [String: String]()
    for line in outputString.split(separator: "\n") {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty || trimmed.hasPrefix(";") {
            continue
        }

        let parts = trimmed.split(separator: "=", maxSplits: 1)
        guard parts.count == 2 else { continue }

        let key = parts[0].trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let value = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.contains("<") else { continue }

        metadata[key] = value
    }

    return metadata
}

func year(from dateValue: String?) -> String {
    guard let rawDate = dateValue, rawDate.count >= 4 else { return "" }
    return String(rawDate.prefix(4))
}

func replaceCharacters(in string: String, replacements: [Character: String]) -> String {
    var result = ""
    for char in string {
        if let replacement = replacements[char] {
            result.append(replacement)
        } else {
            result.append(char)
        }
    }
    return result
}

func createDirectoryIfNeeded(at url: URL) throws {
    if !FileManager.default.fileExists(atPath: url.path) {
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
    }
}

func fileExists(at url: URL) -> Bool {
    FileManager.default.fileExists(atPath: url.path)
}

func copyOrMoveItem(from src: URL, to dst: URL, moveWhenSameVolume: Bool) throws {
    if moveWhenSameVolume {
        try FileManager.default.moveItem(at: src, to: dst)
    } else {
        try FileManager.default.copyItem(at: src, to: dst)
    }
}

func main() {
    let arguments = CommandLine.arguments
    guard arguments.count == 3 else {
        printUsage()
        return
    }

    let sourcePath = arguments[1]
    let destinationPath = arguments[2]
    let sourceURL = URL(fileURLWithPath: sourcePath).standardizedFileURL
    let destinationURL = URL(fileURLWithPath: destinationPath).standardizedFileURL

    let fileManager = FileManager.default

    guard fileManager.fileExists(atPath: sourceURL.path) else {
        print("Error: Source is not mounted.")
        return
    }

    guard fileManager.fileExists(atPath: destinationURL.path) else {
        print("Error: Destination is not mounted.")
        return
    }

    print("Source is \(sourceURL.path)")
    print("Destination is \(destinationURL.path)")

    let sameLocation = sourceURL.path == destinationURL.path
    if sameLocation {
        print("Source and destination are set to the same folder.")
        print("Renaming files and folders in place.")
    }

    var counts = Counts()

    guard let enumerator = fileManager.enumerator(at: sourceURL,
                                                  includingPropertiesForKeys: [.isDirectoryKey],
                                                  options: [.skipsHiddenFiles],
                                                  errorHandler: { url, error in
                                                      print("Failed to enumerate \(url.path): \(error)")
                                                      return true
                                                  }) else {
        print("Unable to enumerate source directory.")
        return
    }

    for case let itemURL as URL in enumerator {
        let resourceValues = try? itemURL.resourceValues(forKeys: [.isDirectoryKey])
        if resourceValues?.isDirectory == true {
            counts.directories += 1
            continue
        }

        guard let metadata = runFFmpegMetadata(for: itemURL) else {
            continue
        }

        guard let mediaType = metadata["media_type"] else {
            continue
        }

        switch mediaType {
        case "9":
            let title = metadata["title"] ?? ""
            let yearString = year(from: metadata["date"])
            let ext = itemURL.pathExtension
            let cleanTitle = replaceCharacters(in: title, replacements: [":": "_"])
            let fullTitle = "\(cleanTitle) (\(yearString))"
            let movieDir = destinationURL.appendingPathComponent("Movies").appendingPathComponent(fullTitle)
            let destinationFile = movieDir.appendingPathComponent("\(fullTitle).\(ext)")
            let existingCleanTitleDir = destinationURL.appendingPathComponent("Movies").appendingPathComponent(cleanTitle)

            if !fileExists(at: destinationFile) {
                do {
                    if fileManager.fileExists(atPath: existingCleanTitleDir.path) {
                        try createDirectoryIfNeeded(at: existingCleanTitleDir)
                        let movedFileURL = existingCleanTitleDir.appendingPathComponent("\(fullTitle).\(ext)")
                        try copyOrMoveItem(from: itemURL, to: movedFileURL, moveWhenSameVolume: sameLocation)
                        let renamedDir = destinationURL.appendingPathComponent("Movies").appendingPathComponent(fullTitle)
                        if sameLocation {
                            try fileManager.moveItem(at: existingCleanTitleDir, to: renamedDir)
                        } else if !fileExists(at: renamedDir) {
                            try fileManager.moveItem(at: existingCleanTitleDir, to: renamedDir)
                        }
                    } else {
                        try createDirectoryIfNeeded(at: movieDir)
                        try copyOrMoveItem(from: itemURL, to: destinationFile, moveWhenSameVolume: sameLocation)
                    }
                    counts.movies += 1
                } catch {
                    print("Failed to copy/move movie file \(itemURL.path): \(error)")
                }
            } else {
                print("\(destinationFile.path) exists, skipping file")
                counts.moviesSkipped += 1
            }

        case "10":
            let show = metadata["show"] ?? ""
            let season = metadata["season_number"] ?? ""
            let episode = metadata["episode_sort"] ?? ""
            let title = metadata["title"] ?? ""
            let cleanShow = replaceCharacters(in: show, replacements: [":": "_"])
            let cleanTitle = replaceCharacters(in: title, replacements: ["/": "_"])
            let seasonLabel = season == "0" ? "Specials" : "Season \(season)"
            let fullTitle = "\(cleanShow) - s\(season)e\(episode) - \(cleanTitle)"
            let ext = itemURL.pathExtension
            let showSeasonDir = destinationURL.appendingPathComponent("TV Shows").appendingPathComponent(cleanShow).appendingPathComponent(seasonLabel)
            let destinationFile = showSeasonDir.appendingPathComponent("\(fullTitle).\(ext)")

            if !fileExists(at: destinationFile) {
                do {
                    try createDirectoryIfNeeded(at: showSeasonDir)
                    try copyOrMoveItem(from: itemURL, to: destinationFile, moveWhenSameVolume: sameLocation)
                    counts.tvShows += 1
                } catch {
                    print("Failed to copy/move TV show file \(itemURL.path): \(error)")
                }
            } else {
                print("\(destinationFile.path) exists, skipping")
                counts.tvShowsSkipped += 1
            }

        default:
            continue
        }
    }

    print("File copy complete")
    print("\(counts.directories) Subdirectories scanned")
    print("\(counts.movies) Movies copied")
    print("\(counts.moviesSkipped) Movies skipped (files already exist)")
    print("\(counts.tvShows) TV Show Episodes copied")
    print("\(counts.tvShowsSkipped) TV Episodes skipped (files already exist)")
}

main()
