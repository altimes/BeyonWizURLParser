// The Swift Programming Language
// https://docs.swift.org/swift-book

// Built using dialog with ChatGPT
// Consequently has some fields that BeyonWiz does not have (query, port, user, password etc..)
// Left on the "you never know when you might encounter it, and it can do no harm" basis


import Foundation
import RegexBuilder

// MARK: - EpisodeInfo

/// Episode metadata parsed from a file name component, such as `S01E02`.
public struct EpisodeInfo: Sendable, Equatable {
    public let series: Int
    public let episode: Int
    
    public init(series: Int, episode: Int) {
        self.series = series
        self.episode = episode
    }
}

// MARK: - ParsedURL

/// The structured components extracted from a BeyonWiz URL string.
///
/// `ParsedURL` contains the standard URL components reported by `URLComponents`,
/// along with BeyonWiz-specific file name information parsed from the final path
/// component when it looks like a file name.
public struct ParsedURL: Sendable, Equatable {
    public let scheme: String?
    public let user: String?
    public let password: String?
    public let host: String?
    public let port: Int?
    public let pathComponents: [String]
    public let fileNameParts: [String]?
    public let episodeInfo: EpisodeInfo?
    public let queryItems: [String: String]
    public let fragment: String?
}

// MARK: - Error

/// Errors that can occur while parsing a BeyonWiz URL string.
public enum BeyonWizURLParserError: Error, Sendable {
    /// The supplied string could not be interpreted as a valid URL.
    case invalidURL
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
                
        let (fileNameParts, episodeInfo) =
            Self.parseFile(from: pathComponents.last)
        
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
            fileNameParts: fileNameParts,
            episodeInfo: episodeInfo,
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
    static func parseFile(from lastPathComponent: String?) -> ([String]?, EpisodeInfo?) {
        
        guard let last = lastPathComponent,
              last.contains("."),
              let dotIndex = last.lastIndex(of: ".")
        else {
            return (nil, nil)
        }
        
        let fileNameWithoutExtension = String(last[..<dotIndex])
        
        let parts = fileNameWithoutExtension
            .split(separator: "-")
            .map {
                $0.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            .filter { !$0.isEmpty }
        
        let episodeInfo = parseEpisodeIfPresent(from: parts)
        
        return (parts, episodeInfo)
    }
    
    /// Parses episode metadata from the final file name part, when present.
    ///
    /// BeyonWiz file names are split into hyphen-separated parts before this method is called.
    /// Only the last part is checked, because episode identifiers such as `S01E02` are expected
    /// to appear at the end of the file name before the extension.
    ///
    /// - Parameter parts: The trimmed, non-empty parts of a file name without its extension.
    /// - Returns: An `EpisodeInfo` value when the last part contains a valid episode identifier;
    ///   otherwise, `nil`.
    static func parseEpisodeIfPresent(from parts: [String]) -> EpisodeInfo? {
        guard let lastPart = parts.last else {
            return nil
        }
        return parseEpisode(from: lastPart)
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
