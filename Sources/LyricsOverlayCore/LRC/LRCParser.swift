import Foundation

public enum LRCParser {
    private static let lineRegex: NSRegularExpression = {
        // [mm:ss.xx] or [mm:ss.xxx] or [mm:ss]
        let pattern = #"^\[(\d{1,2}):(\d{2})(?:\.(\d{1,3}))?\]\s*(.*)$"#
        return try! NSRegularExpression(pattern: pattern, options: [])
    }()

    public static func parse(_ raw: String) -> [LyricLine] {
        var lines: [LyricLine] = []
        lines.reserveCapacity(64)

        for paragraph in raw.split(whereSeparator: \.isNewline) {
            let line = String(paragraph).trimmingCharacters(in: .whitespaces)
            guard !line.isEmpty else { continue }
            if line.hasPrefix("[ti:") || line.hasPrefix("[ar:") || line.hasPrefix("[al:")
                || line.hasPrefix("[by:") || line.hasPrefix("[offset:") || line.hasPrefix("[length:") {
                continue
            }
            let range = NSRange(line.startIndex..<line.endIndex, in: line)
            guard let match = lineRegex.firstMatch(in: line, options: [], range: range),
                  match.numberOfRanges >= 5,
                  let minR = Range(match.range(at: 1), in: line),
                  let secR = Range(match.range(at: 2), in: line),
                  let textR = Range(match.range(at: 4), in: line)
            else {
                continue
            }

            let minutes = Double(line[minR]) ?? 0
            let seconds = Double(line[secR]) ?? 0
            var fraction = 0.0
            if match.range(at: 3).location != NSNotFound,
               let fracR = Range(match.range(at: 3), in: line) {
                let digits = String(line[fracR])
                let padded = digits.count >= 3 ? digits : digits.padding(toLength: 3, withPad: "0", startingAt: 0)
                fraction = (Double(padded) ?? 0) / 1000.0
            }
            let time = minutes * 60 + seconds + fraction
            let text = String(line[textR]).trimmingCharacters(in: .whitespaces)
            guard !text.isEmpty else { continue }
            lines.append(LyricLine(time: time, text: text))
        }

        return lines.sorted { $0.time < $1.time }
    }

    public static func parseMetadata(_ raw: String) -> (title: String?, artist: String?, album: String?) {
        var title: String?
        var artist: String?
        var album: String?
        for paragraph in raw.split(whereSeparator: \.isNewline) {
            let line = String(paragraph)
            if let v = metaValue(line, key: "ti") { title = v }
            if let v = metaValue(line, key: "ar") { artist = v }
            if let v = metaValue(line, key: "al") { album = v }
        }
        return (title, artist, album)
    }

    private static func metaValue(_ line: String, key: String) -> String? {
        let prefix = "[\(key):"
        guard line.lowercased().hasPrefix(prefix),
              line.hasSuffix("]") else { return nil }
        let start = line.index(line.startIndex, offsetBy: prefix.count)
        let end = line.index(before: line.endIndex)
        return String(line[start..<end]).trimmingCharacters(in: .whitespaces)
    }
}
