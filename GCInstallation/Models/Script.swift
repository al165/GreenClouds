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
        ScriptStep(kind: .text("Welcome to Green Clouds: Remember to Forget Me\n\nA voice message will arrive. Tap play to listen; more messages will follow.\n\nThe experience lasts about 20 minutes. To leave at anytime, put the phone back."), preDelay: 0),
        ScriptStep(kind: .voice(audioFileName: "260619_1_taking_V2"), preDelay: 6),
        ScriptStep(kind: .voice(audioFileName: "260624_2_voice_SFX_V4"), preDelay: 3),
        ScriptStep(kind: .image(imageName: "office_park", caption: "This is the office park where the cloud got its name"), preDelay: 1),
        ScriptStep(kind: .voice(audioFileName: "260624_3_voice_SFX_V4"), preDelay: 3),
        ScriptStep(kind: .image(imageName: "rachel", caption: "Rachel is my grandmother’s friend. I remember how soft her skin feels"), preDelay: 1),
        ScriptStep(kind: .voice(audioFileName: "260621_4_voice_SFX_V3"), preDelay: 2),
        ScriptStep(kind: .image(imageName: "ryad_elon"), preDelay: 0),
        ScriptStep(kind: .image(imageName: "ryad_sam"), preDelay: 0),
        ScriptStep(kind: .image(imageName: "ryad_total", caption: "Trump, Sam Altman, Elon Musk in Riyadh, looking for empty space"), preDelay: 0),
        ScriptStep(kind: .voice(audioFileName: "260621_5_voice_SFX_V3"), preDelay: 2),
        ScriptStep(kind: .voice(audioFileName: "260619_6_voice_SFX_V2"), preDelay: 1),
        ScriptStep(kind: .image(imageName: "datacenter_middenmeer", caption: "Somewhere in here are the pictures of my grandmother"), preDelay: 0),
        ScriptStep(kind: .voice(audioFileName: "260624_7_voice_SFX_V4"), preDelay: 1),
        ScriptStep(kind: .image(imageName: "banana_beach", caption: "No longer counting the days"), preDelay: 0),
        ScriptStep(kind: .text("bye bye"), preDelay: 1, postDelay: 3),
    ]
}
