import Foundation

/// International Morse, represented internally with ASCII dots and dashes.
enum Morse {
    static let letters: [String: String] = [
        ".-":"A", "-...":"B", "-.-.":"C", "-..":"D", ".":"E", "..-.":"F",
        "--.":"G", "....":"H", "..":"I", ".---":"J", "-.-":"K", ".-..":"L",
        "--":"M", "-.":"N", "---":"O", ".--.":"P", "--.-":"Q", ".-.":"R",
        "...":"S", "-":"T", "..-":"U", "...-":"V", ".--":"W", "-..-":"X",
        "-.--":"Y", "--..":"Z", "-----":"0", ".----":"1", "..---":"2",
        "...--":"3", "....-":"4", ".....":"5", "-....":"6", "--...":"7",
        "---..":"8", "----.":"9"
    ]
    static func unit(wpm: Double) -> TimeInterval { 1.2 / max(5, min(30, wpm)) }
    static func symbol(duration: TimeInterval, wpm: Double) -> String {
        duration >= 2 * unit(wpm: wpm) ? "-" : "."
    }
}
