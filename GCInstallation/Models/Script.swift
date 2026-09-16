import Foundation

/// The performance script for GC Installation. Edit this array to change what plays
/// and in what order. Replace the placeholder audio files in Resources/Audio with
/// real recordings using these same file names (or update the names here to match).
///
/// Example of mixing in text and image steps alongside voice messages:
///     ScriptStep(kind: .voice(audioFileName: "message_01"), postDelay: 1.5),
///     ScriptStep(kind: .text("wait, look at this")),
///     ScriptStep(kind: .image(imageName: "photo_01", caption: "from that night")),
enum Script {
    static let steps: [ScriptStep] = [
        ScriptStep(kind: .voice(audioFileName: "message_01"), postDelay: 1.5),
        ScriptStep(kind: .text("look at this"), postDelay: 2),
        ScriptStep(kind: .image(imageName: "photo_01", caption: "this is where I am!"), postDelay: 5),
        ScriptStep(kind: .voice(audioFileName: "message_02"), postDelay: 1.5),
        ScriptStep(kind: .voice(audioFileName: "message_03"), postDelay: 0),
    ]
}
