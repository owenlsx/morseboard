import SwiftUI
import AVKit

@main
struct MorseApp: App {
    var body: some Scene { WindowGroup { ContentView() } }
}

struct ContentView: View {
    @State private var practice = ""
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("• -").foregroundStyle(.orange).font(.system(size: 56, weight: .bold, design: .rounded))
                    Text("Text in Morse!").font(.title2.bold())
                    Text("Your Morse Code keyboard.")
                }
                Section("Enable your keyboard") {
                    Text("1. Open iPhone Settings.")
                    Text("2. Go to General → Keyboard → Keyboards → Add New Keyboard.")
                    Text("3. Choose MorseBoard.")
                    Text("4. In any text field, hold the globe key and choose MorseBoard.")
                }
                Section("Try it here") {
                    TextField("Tap here, then switch keyboards", text: $practice, axis: .vertical)
                        .lineLimit(3...6)
                    Button("Clear practice", role: .destructive) { practice = "" }
                }
                Section("Make it yours") {
                    Text("Tap the gear on the keyboard to choose two keys, one key, or an alphabet layout. You can also choose symbols or letters, dot style, and 5–30 WPM. Settings are saved on the keyboard.")
                    Text("One key: tap for a dot, hold for a dash. In letters mode, pause for three dot lengths to finish a letter. Space finishes the current letter and adds a space.")
                    Text("Alphabet layout: tap a letter to insert its Morse code. Letters are separated by one space and words by three spaces. Delete removes the complete previous Morse group.")
                    Text("WPM controls timing, not an automatic typing speed. Start at 10 WPM while learning.")
                }
                Section("Private by design") {
                    Text("No Full Access required. MorseBoard makes no network requests and has no analytics or saved typing history. Practice text disappears when the app restarts.")
                    Text("iOS uses its own keyboard for passwords and some phone fields. Some apps disable custom keyboards.")
                }
                Section("Watch the guides") {
                    ForEach(MorseTutorial.all) { tutorial in
                        NavigationLink {
                            TutorialView(tutorial: tutorial)
                        } label: {
                            Label(tutorial.title, systemImage: "play.rectangle")
                        }
                    }
                    Text("Short, silent demos. Available offline.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                Section("Help & legal") {
                    Link("Support", destination: URL(string: "https://owenlsx.github.io/morseboard/")!)
                    Link("Privacy Policy", destination: URL(string: "https://owenlsx.github.io/morseboard/privacy/")!)
                    Link("Source Code", destination: URL(string: "https://github.com/owenlsx/morseboard")!)
                }
                Section("Morse reference") {
                    ForEach(Morse.letters.sorted(by: { $0.value < $1.value }), id: \.value) { code, letter in
                        HStack {
                            Text(letter).bold()
                            Spacer()
                            Text(code.replacingOccurrences(of: ".", with: "•")).monospaced()
                        }
                    }
                }
            }
            .navigationTitle("MorseBoard")
        }
    }
}

private struct MorseTutorial: Identifiable {
    let id: String
    let title: String
    let steps: [String]

    static let all: [MorseTutorial] = [
        .init(id: "enable-keyboard", title: "Enable MorseBoard", steps: [
            "Open iPhone Settings → General → Keyboard → Keyboards.",
            "Tap Add New Keyboard and choose MorseBoard.",
            "Return to a text field. Hold the globe key and choose MorseBoard. Full Access is not needed."
        ]),
        .init(id: "type-symbols", title: "Type dots and dashes", steps: [
            "Tap the gear. Choose Two keys and turn off Translate into letters.",
            "Tap the dot and dash keys to insert Morse symbols. Use Space to separate groups.",
            "For a timed key, choose Single key: tap for a dot and hold for a dash. Lower WPM gives you more time."
        ]),
        .init(id: "alphabet", title: "Turn letters into Morse", steps: [
            "Tap the gear → Layout → Alphabet, then Done.",
            "Tap a letter to insert its Morse code and a single space.",
            "Space adds two more spaces between words. Delete removes the previous Morse group."
        ]),
        .init(id: "decode-letters", title: "Turn Morse into letters", steps: [
            "Choose Two keys or Single key. Turn on Translate into letters.",
            "Enter a Morse sequence, then pause for three dot lengths. Three dots produce S; three dashes produce O.",
            "Use Space between words. An unrecognised sequence produces no letter."
        ])
    ]
}

private struct TutorialView: View {
    let tutorial: MorseTutorial
    @State private var player: AVPlayer?
    @State private var fullScreen = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let player {
                    TutorialPlayer(player: player)
                        .frame(maxWidth: .infinity)
                        .frame(height: 420)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .accessibilityLabel("\(tutorial.title) video. Use playback controls to play or pause.")
                    Button {
                        fullScreen = true
                    } label: {
                        Label("Watch full screen", systemImage: "arrow.up.left.and.arrow.down.right")
                    }
                }
                Text("Tap Play to watch. Use full screen for a closer look, or pause and replay any step.")
                    .font(.footnote).foregroundStyle(.secondary)
                ForEach(Array(tutorial.steps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: 12) {
                        Text("\(index + 1)").font(.headline).foregroundStyle(.orange)
                        Text(step).frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                Text("Recorded on iOS 26. Settings may look slightly different on your iPhone.")
                    .font(.footnote).foregroundStyle(.secondary)
            }.padding()
        }
        .navigationTitle(tutorial.title)
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $fullScreen) {
            ZStack(alignment: .topTrailing) {
                Color.black.ignoresSafeArea()
                if let player {
                    TutorialPlayer(player: player)
                        .padding(.top, 48)
                }
                Button("Done") {
                    player?.pause()
                    fullScreen = false
                }.font(.headline).tint(.orange).padding()
            }
        }
        .onAppear {
            guard player == nil,
                  let url = Bundle.main.url(forResource: tutorial.id, withExtension: "mp4", subdirectory: "Tutorials") else { return }
            player = AVPlayer(url: url)
            player?.isMuted = true
        }
        .onDisappear { player?.pause() }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { player?.pause() }
        }
    }
}

private struct TutorialPlayer: UIViewControllerRepresentable {
    let player: AVPlayer

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.allowsPictureInPicturePlayback = false
        return controller
    }

    func updateUIViewController(_ controller: AVPlayerViewController, context: Context) {
        if controller.player !== player { controller.player = player }
    }
}
