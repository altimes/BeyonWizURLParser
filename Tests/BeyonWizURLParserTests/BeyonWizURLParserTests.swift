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
        ParsedURL(scheme: "https", user: nil, password: nil, host: "nas.local", port: nil, pathComponents: ["TV", "QI","20250828 1240 - ABC - QI - S99E01.TS"], recording: RecordingMetadata(dateTime: testDate, channelName: "ABC", programName: "QI", episodeInfo: EpisodeInfo(series: 99, episode: 1), filenameWithoutSuffix: "20250828 1240 - ABC - QI - S99E01", filetype: RecordingFiletypes.ts), queryItems: [:], fragment: nil)
        )
  }
  func testNoChannelField() throws {
      XCTAssertEqual( try!
          BeyonWizURLParser().parse("https://nas.local/TV/QI/20250828 1240 - QI - S99E01.TS"),
          ParsedURL(scheme: "https", user: nil, password: nil, host: "nas.local", port: nil, pathComponents: ["TV", "QI","20250828 1240 - QI - S99E01.TS"], recording: RecordingMetadata(dateTime: testDate, channelName: nil, programName: "QI", episodeInfo: EpisodeInfo(series: 99, episode: 1), filenameWithoutSuffix: "20250828 1240 - QI - S99E01", filetype: RecordingFiletypes.ts), queryItems: [:], fragment: nil)
                  )

  }
  func testNoFourDigitSeries() throws {
      XCTAssertEqual( try!
          BeyonWizURLParser().parse("https://nas.local/TV/QI/20250828 1240 - QI - S2026E01.TS"),
          ParsedURL(scheme: "https", user: nil, password: nil, host: "nas.local", port: nil, pathComponents: ["TV", "QI","20250828 1240 - QI - S2026E01.TS"], recording: RecordingMetadata(dateTime: testDate, channelName: nil, programName: "QI", episodeInfo: EpisodeInfo(series: 2026, episode: 1), filenameWithoutSuffix: "20250828 1240 - QI - S2026E01", filetype: RecordingFiletypes.ts), queryItems: [:], fragment: nil)
                      )

  }
  func testNoDateField() throws {
    XCTAssertEqual( try!
        BeyonWizURLParser().parse("https://nas.local/TV/QI/QI - S2026E01.TS.CUTS"),
        ParsedURL(scheme: "https", user: nil, password: nil, host: "nas.local", port: nil, pathComponents: ["TV", "QI","QI - S2026E01.TS.CUTS"], recording: RecordingMetadata(dateTime: nil, channelName: nil, programName: "QI", episodeInfo: EpisodeInfo(series: 2026, episode: 1), filenameWithoutSuffix: "QI - S2026E01", filetype: RecordingFiletypes.cuts), queryItems: [:], fragment: nil)
                    )
  }
  func testChannelButNoDateField() throws {
    XCTAssertEqual( try!
        BeyonWizURLParser().parse("https://nas.local/TV/QI/ABC HD - QI - S2026E01.TS"),
        ParsedURL(scheme: "https", user: nil, password: nil, host: "nas.local", port: nil, pathComponents: ["TV", "QI","ABC HD - QI - S2026E01.TS"], recording: RecordingMetadata(dateTime: nil, channelName: "ABC HD", programName: "QI", episodeInfo: EpisodeInfo(series: 2026, episode: 1), filenameWithoutSuffix: "ABC HD - QI - S2026E01", filetype: RecordingFiletypes.ts), queryItems: [:], fragment: nil)
                    )
  }
  func testNoChannelNoDateField() throws {
    XCTAssertEqual( try!
        BeyonWizURLParser().parse("https://nas.local/TV/QI/QI - S2026E01.TS"),
        ParsedURL(scheme: "https", user: nil, password: nil, host: "nas.local", port: nil, pathComponents: ["TV", "QI","QI - S2026E01.TS"], recording: RecordingMetadata(dateTime: nil, channelName: nil, programName: "QI", episodeInfo: EpisodeInfo(series: 2026, episode: 1), filenameWithoutSuffix: "QI - S2026E01", filetype: RecordingFiletypes.ts), queryItems: [:], fragment: nil)
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
  func testSuffixTypes() throws {
    // Mixed cases
    var filename = try! BeyonWizURLParser().parse("https://nas.local/TV/QI/20250828 1240 - QI - S06E05.TS.cuts").recording
    XCTAssertEqual(RecordingFiletypes.cuts, filename!.filetype)
    filename = try! BeyonWizURLParser().parse("https://nas.local/TV/QI/20250828 1240 - QI - S06E05.ts").recording
    XCTAssertEqual(RecordingFiletypes.ts, filename!.filetype)
    filename = try! BeyonWizURLParser().parse("https://nas.local/TV/QI/20250828 1240 - QI - S06E05.freddy").recording
    XCTAssertEqual(nil, filename?.filetype)
    filename = try! BeyonWizURLParser().parse("https://nas.local/TV/QI/20250828 1240 - QI - S06E05.srt").recording
    XCTAssertEqual(RecordingFiletypes.srt, filename?.filetype)
    filename = try! BeyonWizURLParser().parse("https://nas.local/TV/QI/20250828 1240 - QI - S06E05.ts.ap").recording
    XCTAssertEqual(RecordingFiletypes.ap, filename?.filetype)
    filename = try! BeyonWizURLParser().parse("https://nas.local/TV/QI/20250828 1240 - QI - S06E05.ts.meta").recording
    XCTAssertEqual(RecordingFiletypes.meta, filename?.filetype)
    filename = try! BeyonWizURLParser().parse("https://nas.local/TV/QI/20250828 1240 - QI - S06E05.eit").recording
    XCTAssertEqual(RecordingFiletypes.eit, filename?.filetype)
    filename = try! BeyonWizURLParser().parse("https://nas.local/TV/QI/20250828 1240 - QI - S06E05.ts.sc").recording
    XCTAssertEqual(RecordingFiletypes.sc, filename?.filetype)

  }
  func testNameWithoutSuffix() throws {
    XCTAssertEqual(
      "20250828 1240 - QI - S06E05", "\(try! BeyonWizURLParser().parse("https://nas.local/TV/QI/20250828 1240 - QI - S06E05.TS").recording!.filenameWithoutSuffix)"
    )
  }
}
