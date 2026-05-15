// The Swift Programming Language
// https://docs.swift.org/swift-book

// Built using dialog with ChatGPT
// Consequently has some fields that BeyonWiz does not have (query, port, user, password etc..)
// Left on the "you never know when you might encounter it, and it can do no harm" basis


import Foundation
import RegexBuilder


// MARK: - RecordingMetadata

/// Metadata parsed from a BeyonWiz recording file name.
///
/// `RecordingMetadata` describes the optional timestamp, channel, and episode
/// information extracted from the final path component of a BeyonWiz URL, along
/// with the required program name.
public struct RecordingMetadata: Sendable, Equatable, Hashable {
  public let dateTime: Date?
  public let channelName: String?
  public let programName: String
  public let episodeInfo: EpisodeInfo?
  public let filenameWithoutSuffix: String
  public let filetype: RecordingFiletypes
}

// MARK: - EpisodeInfo

/// Episode metadata parsed from a file name component, such as `S01E02`.
public struct EpisodeInfo: Sendable, Equatable, Hashable, CustomStringConvertible {
  public let series: Int
  public let episode: Int
  
  public init(series: Int, episode: Int) {
    self.series = series
    self.episode = episode
  }
  
  /// CustomStringConvertible compliance
  /// Generates SnnEnn or SnnnnEnn from episode and series values
  public var description: String {
    let seriesString = series.formatted(.number.grouping(.never).precision(.integerLength(series > 99 ? 4 : 2)))
    let episodeString = episode.formatted(.number.grouping(.never).precision(.integerLength(2)))
    let result = "S\(seriesString)E\(episodeString)"
    return result
  }
}

// MARK: - ParsedURL

/// The structured components extracted from a BeyonWiz URL string.
///
/// `ParsedURL` contains the standard URL components reported by `URLComponents`,
/// along with BeyonWiz-specific file name information parsed from the final path
/// component when it looks like a file name.
public struct ParsedURL: Sendable, Equatable, Hashable {
  public let scheme: String?
  public let user: String?
  public let password: String?
  public let host: String?
  public let port: Int?
  public let pathComponents: [String]
  public let recording: RecordingMetadata?
  public let queryItems: [String: String]
  public let fragment: String?
}

// MARK: - Error

/// Errors that can occur while parsing a BeyonWiz URL string.
public enum BeyonWizURLParserError: Error, Sendable {
  /// The supplied string could not be interpreted as a valid URL.
  case invalidURL
}


// MARK: - File Types

/// File types recognised in BeyonWiz recording-related file names.
///
/// The raw value for each case is the suffix expected at the end of a file name,
/// excluding the leading period. Compound suffixes, such as `ts.meta`, identify
/// BeyonWiz  files associated with a transport stream recording.
///
/// Use ``match(for:)`` to determine the recording file type from a complete file
/// name. When no known suffix is found, matching returns  .unknown case..
public enum RecordingFiletypes: String, Sendable, CaseIterable {
  case ts   = "ts"
  case eit  = "eit"
  case cuts = "ts.cuts"
  case meta = "ts.meta"
  case ap   = "ts.ap"
  case sc   = "ts.sc"
  case srt  = "srt"
  case unknown = "unknown"
  
  public static func match(for fileName: String) -> RecordingFiletypes {
    let result = RecordingFiletypes.allCases.filter { videoType in
      Self.isFileOfType(fileName: fileName, for: videoType)
    }
    return result.first ?? .unknown
  }
  
  public static func isFileOfType(fileName: String, for fileType: RecordingFiletypes) -> Bool {
    let pattern = Regex {
      "."
      fileType.rawValue.lowercased()
      Anchor.endOfLine
    }
    do {
//      if let match = try pattern.firstMatch(in: fileName.lowercased()) {
//        print(fileType)
//        print(String(fileName[match.range]))
//        return true
        return try pattern.firstMatch(in: fileName.lowercased()) != nil
//      }
//      else { return false }
    }
    catch {
      // should log and better handle error....
      print(error)
      return false
    }
  }
}

// MARK: - Parser

public struct BeyonWizURLParser: Sendable {
  
  public init() {}
  
  public func parse(_ urlString: String) throws -> ParsedURL {
    
    guard let components = URLComponents(string: urlString) else {
      throw BeyonWizURLParserError.invalidURL
    }
    
    guard let url = URL(string: urlString) else {
      throw BeyonWizURLParserError.invalidURL
    }
    let pathComponents = url.pathComponents
      .filter { $0 != "/" }
    
    let recording = Self.parseFile(from: pathComponents.last)
    
    let queryItems = Dictionary(
      uniqueKeysWithValues: components.queryItems?.map {
        ($0.name, $0.value ?? "")
      } ?? []
    )
    
    return ParsedURL(
      scheme: components.scheme,
      user: components.user,
      password: components.password,
      host: components.host,
      port: components.port,
      pathComponents: pathComponents,
      recording: recording,
      queryItems: queryItems,
      fragment: components.fragment
    )
  }
}

// MARK: - File + Episode Parsing

/// Private helpers for extracting file-name parts and episode metadata from parsed path components.
private extension BeyonWizURLParser {
  
  /// Extracts file-name parts and optional episode metadata from the final path component.
  ///
  /// The component must look like a file name by containing an extension separator (`.`).
  /// The extension is removed, and the remaining name is split on hyphens. Each part is
  /// trimmed of surrounding whitespace, and empty parts are discarded. Episode metadata is
  /// parsed from the final remaining part when it matches a supported episode identifier.
  ///
  /// - Parameter lastPathComponent: The final URL path component, or `nil` when the URL has no path component.
  /// - Returns: A tuple containing the parsed file-name parts and episode metadata. Both values are `nil`
  ///   when `lastPathComponent` is `nil` or does not contain an extension separator.
  static func parseFile(from lastPathComponent: String?) -> RecordingMetadata? {
    
    guard let last = lastPathComponent else { return nil }
    
    // must have a suffix of the known types
    let fileType = RecordingFiletypes.match(for: last)
    guard fileType != .unknown else { return nil }
    
    // find and remove suffix
    let range = last.lowercased().range(of: ".\(fileType.rawValue)")
    guard let dotIndex = range?.lowerBound else { return nil }
    let fileNameWithoutExtension = String(last[..<dotIndex])
    
    var parts = fileNameWithoutExtension
      .split(separator: "-")
      .map {
        $0.trimmingCharacters(in: .whitespacesAndNewlines)
      }
      .filter { !$0.isEmpty }
    
    
    guard !parts.isEmpty else { return nil }
    
    // 1️⃣ Detect episode (must be last if present)
    var episodeInfo: EpisodeInfo? = nil
    if let lastPart = parts.last,
       let episode = parseEpisode(from: lastPart) {
      episodeInfo = episode
      parts.removeLast()
    }
    
    // 2️⃣ Detect date/time (must be first if present)
    
    var dateTime: Date? = nil
    if let firstPart = parts.first,
       let parsedDate = parseDateTime(from: firstPart) {
      dateTime = parsedDate
      parts.removeFirst()
    }
    
    // 3️⃣ Detect channel (if 2 parts remain, first is channel)
    var channelName: String? = nil
    
    if parts.count >= 2 {
      channelName = parts.removeFirst()
    }
    
    // 4️⃣ Remaining is program name (mandatory)
    guard let programName = parts.first else {
      return nil
    }
    
    return RecordingMetadata(
      dateTime: dateTime,
      channelName: channelName,
      programName: programName,
      episodeInfo: episodeInfo,
      filenameWithoutSuffix: fileNameWithoutExtension,
      filetype: fileType
    )
  }
  
  /// Parses a BeyonWiz episode identifier from a string.
  ///
  /// The string must consist only of an episode identifier in `SxxxxExx` format, where the
  /// series component contains one to four digits and the episode component contains one or
  /// two digits. Matching is case-insensitive for the `S` and `E` separators.
  ///
  /// For example, `S01E02` returns an episode with series `1` and episode `2`.
  ///
  /// - Parameter string: The string to parse as an episode identifier.
  /// - Returns: An `EpisodeInfo` value when `string` exactly matches the supported episode
  ///   format; otherwise, `nil`.
  static func parseEpisode(from string: String) -> EpisodeInfo? {
    
    // SxxxxExx (case-insensitive)
    let pattern = Regex {
      Anchor.startOfLine
      One(.anyOf("sS"))
      Capture { Repeat(1...4) { .digit } }
      One(.anyOf("eE"))
      Capture { Repeat(1...2) { .digit } }
      Anchor.endOfLine
    }
    
    guard let match = string.firstMatch(of: pattern),
          let series = Int(match.1),
          let episode = Int(match.2)
    else {
      return nil
    }
    
    return EpisodeInfo(series: series, episode: episode)
  }
}

private extension BeyonWizURLParser {
  
  /// Parses a BeyonWiz recording timestamp into a `Date`.
  ///
  /// The expected input format is `yyyyMMdd HHmm`, using the Australian English
  /// locale and the `Australia/Sydney` time zone. Multiple spaces between the
  /// date and time components are normalised before parsing.
  ///
  /// - Parameter string: The timestamp string to parse, such as `20240513 1930`.
  /// - Returns: A `Date` when `string` matches the expected format; otherwise, `nil`.
  static func parseDateTime(from string: String) -> Date? {
    
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_AU")
    formatter.timeZone = TimeZone(identifier: "Australia/Sydney")
    formatter.dateFormat = "yyyyMMdd HHmm"
    
    // Normalise multiple spaces between date and time
    let normalised = string
      .replacingOccurrences(of: #" +"#, with: " ", options: .regularExpression)
    
    let date =  formatter.date(from: normalised)
    return date
  }
}

