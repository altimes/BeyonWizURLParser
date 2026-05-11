import XCTest
@testable import BeyonWizURLParser

final class BeyonWizURLParserTests: XCTestCase {
    func testExample() throws {
        // XCTest Documentation
        // https://developer.apple.com/documentation/xctest

        // Defining Test Cases and Test Methods
        // https://developer.apple.com/documentation/xctest/defining_test_cases_and_test_methods
    }
  func testExpectedResult() throws {
    XCTAssertEqual(
      try!
      BeyonWizURLParser().parse("https://nas.local/TV/QI/20250835 1240 - ABC - QI - S99E01.TS"),
      ParsedURL(scheme: "https", user: nil, password: nil, host: "nas.local", port: nil, pathComponents: ["TV", "QI","20250835 1240 - ABC - QI - S99E01.TS"], fileNameParts: ["20250835 1240", "ABC", "QI", "S99E01"], episodeInfo: EpisodeInfo(series: 99, episode: 1), queryItems: [:], fragment: nil)
      )
  }
  func testNoChannelField() throws {
      XCTAssertEqual( try!
          BeyonWizURLParser().parse("https://nas.local/TV/QI/20250835 1240 - QI - S99E01.TS"),
          ParsedURL(scheme: "https", user: nil, password: nil, host: "nas.local", port: nil, pathComponents: ["TV", "QI","20250835 1240 - QI - S99E01.TS"], fileNameParts: ["20250835 1240", "QI", "S99E01"], episodeInfo: EpisodeInfo(series: 99, episode: 1), queryItems: [:], fragment: nil)
                      )

  }
  func testNoFourDigitSeries() throws {
      XCTAssertEqual( try!
          BeyonWizURLParser().parse("https://nas.local/TV/QI/20250835 1240 - QI - S2026E01.TS"),
          ParsedURL(scheme: "https", user: nil, password: nil, host: "nas.local", port: nil, pathComponents: ["TV", "QI","20250835 1240 - QI - S2026E01.TS"], fileNameParts: ["20250835 1240", "QI", "S2026E01"], episodeInfo: EpisodeInfo(series: 2026, episode: 1), queryItems: [:], fragment: nil)
                      )

  }
}
