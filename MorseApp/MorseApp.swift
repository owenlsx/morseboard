import SwiftUI

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
                    Text("Tap the gear on the keyboard to choose two keys or one key, symbols or letters, dot style, and 5–30 WPM. Settings are saved on the keyboard.")
                    Text("One key: tap for a dot, hold for a dash. In letters mode, pause for three dot lengths to finish a letter. Space finishes the current letter and adds a space.")
                    Text("WPM controls timing, not an automatic typing speed. Start at 10 WPM while learning.")
                }
                Section("Private by design") {
                    Text("No Full Access required. MorseBoard makes no network requests and has no analytics or saved typing history. Practice text disappears when the app restarts.")
                    Text("iOS uses its own keyboard for passwords and some phone fields. Some apps disable custom keyboards.")
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
