// The Swift Programming Language
// https://docs.swift.org/swift-book

// Built using dialog with ChatGPT

import Foundation
import RegexBuilder

// MARK: - EpisodeInfo

public struct EpisodeInfo: Sendable, Equatable {
    public let series: Int
    public let episode: Int
    
    public init(series: Int, episode: Int) {
        self.series = series
        self.episode = episode
    }
}

// MARK: - ParsedURL

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

public enum BeyonWizURLParserError: Error, Sendable {
    case invalidURL
}

// MARK: - Parser

public struct BeyonWizURLParser: Sendable {
    
    public init() {}
    
    public func parse(_ urlString: String) throws -> ParsedURL {
        
        guard let components = URLComponents(string: urlString) else {
            throw BeyonWizURLParserError.invalidURL
        }
        
        let pathComponents = components.path
            .split(separator: "/", omittingEmptySubsequences: true)
            .map(String.init)
        
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

private extension BeyonWizURLParser {
    
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
    
    static func parseEpisodeIfPresent(from parts: [String]) -> EpisodeInfo? {
        guard let lastPart = parts.last else {
            return nil
        }
        return parseEpisode(from: lastPart)
    }
    
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
