import Foundation

/// The performance script for GC Performance. Edit this array to change what plays
/// and in what order. Replace the placeholder audio files in Resources/Audio with
/// real recordings using these same file names (or update the names here to match).
///
/// Unlike GC Installation, this sequence starts when the performer sends their own
/// first message (see PerformanceRootView) rather than a lock-screen tap — the
/// content of that first message doesn't matter, it's just the trigger.
///
        // ScriptStep(kind: .voice(audioFileName: "message_01"), postDelay: 1.5),
        // ScriptStep(kind: .text("got it, one sec")),
        // ScriptStep(kind: .voice(audioFileName: "message_02"), postDelay: 0),

enum Script {
    static let steps: [ScriptStep] = [
        // ScriptStep(kind: .voice(audioFileName: "260619_1_taking_V2"), preDelay: 3),
        ScriptStep(kind: .voice(audioFileName: "260624_2_voice_SFX_V4"), preDelay: 3),
        ScriptStep(kind: .voice(audioFileName: "260624_3_voice_SFX_V4"), preDelay: 3),
        ScriptStep(kind: .voice(audioFileName: "260621_4_voice_SFX_V3"), preDelay: 0),
        ScriptStep(kind: .voice(audioFileName: "260621_5_voice_SFX_V3"), preDelay: 3),
        ScriptStep(kind: .voice(audioFileName: "260619_6_voice_SFX_V2"), preDelay: 3),
        ScriptStep(kind: .voice(audioFileName: "260624_7_voice_SFX_V4"), preDelay: 1),
    ]
}
