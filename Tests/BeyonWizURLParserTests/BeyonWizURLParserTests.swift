import XCTest
@testable import BeyonWizURLParser

final class BeyonWizURLParserTests: XCTestCase {
  var testDate: Date {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyyMMdd HHmm"
    formatter.locale = Locale(identifier: "en_AU")
    formatter.timeZone = TimeZone(identifier: "Australia/Sydney")
    if let date = formatter.date(from: "20250828 1240")
    {
      print(date)
      return date
    }
    else {
      XCTFail("Cannot establish test date")
    }
    return(.distantFuture)
  }
    func testExample() throws {
        // XCTest Documentation
        // https://developer.apple.com/documentation/xctest

        // Defining Test Cases and Test Methods
        // https://developer.apple.com/documentation/xctest/defining_test_cases_and_test_methods
    }
  func testExpectedResult() throws {
      XCTAssertEqual(
        // Parse the string
        try BeyonWizURLParser().parse("https://nas.local/TV/QI/20250828 1240 - ABC - QI - S99E01.TS"),
        ParsedURL(scheme: "https", user: nil, password: nil, host: "nas.local", port: nil, pathComponents: ["TV", "QI","20250828 1240 - ABC - QI - S99E01.TS"], recording: RecordingMetadata(dateTime: testDate, channelName: "ABC", programName: "QI", episodeInfo: EpisodeInfo(series: 99, episode: 1)), queryItems: [:], fragment: nil)
        )
  }
  func testNoChannelField() throws {
      XCTAssertEqual( try!
          BeyonWizURLParser().parse("https://nas.local/TV/QI/20250828 1240 - QI - S99E01.TS"),
          ParsedURL(scheme: "https", user: nil, password: nil, host: "nas.local", port: nil, pathComponents: ["TV", "QI","20250828 1240 - QI - S99E01.TS"], recording: RecordingMetadata(dateTime: testDate, channelName: nil, programName: "QI", episodeInfo: EpisodeInfo(series: 99, episode: 1)), queryItems: [:], fragment: nil)
                  )

  }
  func testNoFourDigitSeries() throws {
      XCTAssertEqual( try!
          BeyonWizURLParser().parse("https://nas.local/TV/QI/20250828 1240 - QI - S2026E01.TS"),
          ParsedURL(scheme: "https", user: nil, password: nil, host: "nas.local", port: nil, pathComponents: ["TV", "QI","20250828 1240 - QI - S2026E01.TS"], recording: RecordingMetadata(dateTime: testDate, channelName: nil, programName: "QI", episodeInfo: EpisodeInfo(series: 2026, episode: 1)), queryItems: [:], fragment: nil)
                      )

  }
  func testNoDateField() throws {
    XCTAssertEqual( try!
        BeyonWizURLParser().parse("https://nas.local/TV/QI/QI - S2026E01.TS"),
        ParsedURL(scheme: "https", user: nil, password: nil, host: "nas.local", port: nil, pathComponents: ["TV", "QI","QI - S2026E01.TS"], recording: RecordingMetadata(dateTime: nil, channelName: nil, programName: "QI", episodeInfo: EpisodeInfo(series: 2026, episode: 1)), queryItems: [:], fragment: nil)
                    )
  }
  func testChannelButNoDateField() throws {
    XCTAssertEqual( try!
        BeyonWizURLParser().parse("https://nas.local/TV/QI/ABC HD - QI - S2026E01.TS"),
        ParsedURL(scheme: "https", user: nil, password: nil, host: "nas.local", port: nil, pathComponents: ["TV", "QI","ABC HD - QI - S2026E01.TS"], recording: RecordingMetadata(dateTime: nil, channelName: "ABC HD", programName: "QI", episodeInfo: EpisodeInfo(series: 2026, episode: 1)), queryItems: [:], fragment: nil)
                    )
  }
  func testNoChannelNoDateField() throws {
    XCTAssertEqual( try!
        BeyonWizURLParser().parse("https://nas.local/TV/QI/QI - S2026E01.TS"),
        ParsedURL(scheme: "https", user: nil, password: nil, host: "nas.local", port: nil, pathComponents: ["TV", "QI","QI - S2026E01.TS"], recording: RecordingMetadata(dateTime: nil, channelName: nil, programName: "QI", episodeInfo: EpisodeInfo(series: 2026, episode: 1)), queryItems: [:], fragment: nil)
                    )
  }
  func testSeriesEpisodeDescription() throws {
    XCTAssertEqual(
      "S2026E01", "\(try! BeyonWizURLParser().parse("https://nas.local/TV/QI/ABC Entertains - QI - S2026E01.TS").recording!.episodeInfo!)"
    )
    XCTAssertEqual(
      "S06E05", "\(try! BeyonWizURLParser().parse("https://nas.local/TV/QI/20250828 1240 - QI - S06E05.TS").recording!.episodeInfo!)"
    )
  }
}
