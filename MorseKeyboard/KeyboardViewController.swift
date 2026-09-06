import UIKit
import SwiftUI

/// UIKit provides direct touch-down/up events for the timed Morse key.
final class KeyboardViewController: UIInputViewController {
    private let defaults = UserDefaults.standard
    private var single: Bool { get { defaults.bool(forKey: "single") } set { defaults.set(newValue, forKey: "single") } }
    private var decode: Bool { get { defaults.bool(forKey: "decode") } set { defaults.set(newValue, forKey: "decode") } }
    private var wpm: Double { get { defaults.object(forKey: "wpm") as? Double ?? 10 } set { defaults.set(newValue, forKey: "wpm") } }
    private var caps: Bool { get { defaults.object(forKey: "caps") as? Bool ?? true } set { defaults.set(newValue, forKey: "caps") } }
    private var pending = ""
    private var timer: Timer?
    private var downAt: TimeInterval?
    private var settingsHost: UIHostingController<KeyboardSettingsView>?
    private var settingsVisible: Bool { settingsHost != nil }
    private var smallDot: Bool { defaults.bool(forKey: "smallDot") }
    private var dotGlyph: String { smallDot ? "." : "•" }
    private var keyboardHeight: CGFloat { compactLayout ? 160 : 216 }
    private func updateHeight() { height?.constant = settingsVisible ? (compactLayout ? 240 : 380) : keyboardHeight }
    private let stack = UIStackView()
    private let status = UILabel()
    private var height: NSLayoutConstraint?
    private var compactLayout = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGray5
        stack.axis = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
            stack.topAnchor.constraint(equalTo: view.topAnchor, constant: 8),
            stack.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -8)
        ])
        height = view.heightAnchor.constraint(equalToConstant: 216)
        height?.priority = .defaultHigh
        height?.isActive = true
        status.heightAnchor.constraint(equalToConstant: 22).isActive = true
        rebuild()
    }
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        // Use the host scene's orientation, not the keyboard's own wide bounds.
        let orientation = view.window?.windowScene?.interfaceOrientation
        let compact = orientation == .landscapeLeft || orientation == .landscapeRight
            || (orientation == nil && traitCollection.verticalSizeClass == .compact)
        guard compact != compactLayout else { return }
        compactLayout = compact
        downAt = nil
        timer?.invalidate()
        scheduleCommit()
        updateHeight()
        rebuild()
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        resetPending()
        closeSettings(animated: false)
    }
    override func textWillChange(_ textInput: UITextInput?) { resetPending() }
    override func textDidChange(_ textInput: UITextInput?) {
        super.textDidChange(textInput)
        if isViewLoaded { rebuild() }
    }
    private func resetPending() {
        timer?.invalidate()
        timer = nil
        downAt = nil
        pending = ""
        updateStatus()
    }
    private func button(_ title: String, action: Selector) -> UIButton {
        let b = KeyboardKey(type: .custom)
        b.setTitle(title, for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: compactLayout ? 15 : 19, weight: .medium)
        b.addTarget(self, action: action, for: .touchUpInside)
        b.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
        return b
    }
    private func iconButton(_ symbol: String, label: String, action: Selector) -> UIButton {
        let key = button("", action: action)
        key.setImage(UIImage(systemName: symbol), for: .normal)
        key.setPreferredSymbolConfiguration(.init(pointSize: 21, weight: .medium), forImageIn: .normal)
        key.accessibilityLabel = label
        return key
    }
    private func row(_ views: [UIView]) -> UIStackView {
        let r = UIStackView(arrangedSubviews: views)
        r.distribution = .fillEqually
        r.spacing = 8
        return r
    }
    private func rebuild() {
        stack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        stack.spacing = compactLayout ? 4 : 8
        status.textAlignment = .center
        status.font = .systemFont(ofSize: 13, weight: .medium)
        // Keep the system keyboard switcher out of the fixed editing row.
        let globe = iconButton("globe", label: "Next keyboard", action: #selector(nextKeyboard))
        globe.removeTarget(self, action: #selector(nextKeyboard), for: .touchUpInside)
        globe.addTarget(self, action: #selector(handleInputModeList(from:with:)), for: .allTouchEvents)
        globe.isHidden = !needsInputModeSwitchKey
        globe.widthAnchor.constraint(equalToConstant: 44).isActive = true
        let header = UIStackView(arrangedSubviews: [globe, status])
        header.spacing = 8
        header.heightAnchor.constraint(equalToConstant: 44).isActive = true
        header.alignment = .center
        stack.addArrangedSubview(header)
        if single {
            let key = button("\(dotGlyph) / -", action: #selector(releaseKey))
            key.titleLabel?.font = .systemFont(ofSize: compactLayout ? 36 : 48, weight: .bold)
            key.accessibilityLabel = "Morse key"
            key.accessibilityHint = "Short press for dot, long press for dash"
            key.addTarget(self, action: #selector(pressKey), for: .touchDown)
            key.addTarget(self, action: #selector(cancelKey), for: [.touchCancel, .touchUpOutside, .touchDragExit])
            stack.addArrangedSubview(key)
        } else {
            let dot = button(dotGlyph, action: #selector(dot))
            let dash = button("-", action: #selector(dash))
            dot.accessibilityLabel = "Dot"
            dash.accessibilityLabel = "Dash"
            [dot, dash].forEach { $0.titleLabel?.font = .systemFont(ofSize: compactLayout ? 36 : 64, weight: .bold) }
            stack.addArrangedSubview(row([dot, dash]))
        }
        let gear = iconButton("gearshape.fill", label: "Keyboard settings", action: #selector(toggleSettings))
        let capsKey = iconButton(caps ? "shift.fill" : "shift", label: "Caps lock", action: #selector(toggleCaps))
        capsKey.isHidden = !decode
        capsKey.isSelected = caps
        capsKey.accessibilityValue = caps ? "On" : "Off"
        capsKey.accessibilityHint = "Toggle uppercase and lowercase letters"
        let leading = row([capsKey, gear])
        let spaceKey = button("space", action: #selector(space))
        let delete = iconButton("delete.left", label: "Delete", action: #selector(deleteKey))
        let enter = iconButton("return", label: "Enter", action: #selector(enterKey))
        let bottom = UIStackView(arrangedSubviews: [leading, spaceKey, delete, enter])
        bottom.spacing = 8
        // Fixed 2:3:1:1 columns. Gear expands into Caps' slot in symbols mode.
        NSLayoutConstraint.activate([
            leading.widthAnchor.constraint(equalTo: delete.widthAnchor, multiplier: 2, constant: 8),
            spaceKey.widthAnchor.constraint(equalTo: delete.widthAnchor, multiplier: 3, constant: 16),
            enter.widthAnchor.constraint(equalTo: delete.widthAnchor)
        ])
        bottom.heightAnchor.constraint(equalToConstant: compactLayout ? 44 : 48).isActive = true
        stack.addArrangedSubview(bottom)
        updateStatus()
    }
    private func decodedLetter(_ sequence: String) -> String? {
        guard let letter = Morse.letters[sequence] else { return nil }
        return caps ? letter : letter.lowercased()
    }
    private func updateStatus() {
        status.text = pending.isEmpty
            ? "\(decode ? "Letters" : "Symbols") · \(Int(wpm)) WPM\(single ? " · hold for dash" : "")"
            : pending.replacingOccurrences(of: ".", with: dotGlyph) + "  →  " + (decodedLetter(pending) ?? "?")
    }
    private func emit(_ symbol: String) {
        timer?.invalidate()
        if decode {
            pending += symbol
            updateStatus()
            scheduleCommit()
        } else {
            textDocumentProxy.insertText(symbol == "." ? dotGlyph : "-")
        }
    }
    private func scheduleCommit() {
        guard !pending.isEmpty else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 3 * Morse.unit(wpm: wpm), repeats: false) { [weak self] _ in self?.commit() }
    }
    private func commit() {
        timer?.invalidate()
        timer = nil
        guard !pending.isEmpty else { return }
        let output = decodedLetter(pending)
        pending = ""
        if let output {
            textDocumentProxy.insertText(output)
        }
        updateStatus()
    }
    @objc private func dot() { emit(".") }
    @objc private func dash() { emit("-") }
    @objc private func pressKey() {
        timer?.invalidate()
        downAt = ProcessInfo.processInfo.systemUptime
    }
    @objc private func releaseKey() {
        guard let start = downAt else { return }
        downAt = nil
        emit(Morse.symbol(duration: ProcessInfo.processInfo.systemUptime - start, wpm: wpm))
    }
    @objc private func cancelKey() { downAt = nil; scheduleCommit() }
    @objc private func deleteKey() {
        timer?.invalidate()
        if !pending.isEmpty { pending.removeLast(); updateStatus(); scheduleCommit() }
        else { textDocumentProxy.deleteBackward() }
    }
    @objc private func enterKey() { commit(); textDocumentProxy.insertText("\n") }
    @objc private func toggleCaps() { caps.toggle(); rebuild() }
    @objc private func space() { commit(); textDocumentProxy.insertText(" ") }
    @objc private func nextKeyboard() { resetPending(); advanceToNextInputMode() }
    @objc private func toggleSettings() {
        guard settingsHost == nil else { closeSettings(); return }
        commit()
        downAt = nil
        let host = UIHostingController(rootView: KeyboardSettingsView(done: { [weak self] in
            self?.closeSettings()
        }))
        settingsHost = host
        addChild(host)
        host.view.translatesAutoresizingMaskIntoConstraints = false
        host.view.backgroundColor = .systemGroupedBackground
        host.view.layer.cornerRadius = 18
        host.view.clipsToBounds = true
        host.view.accessibilityViewIsModal = true
        view.addSubview(host.view)
        NSLayoutConstraint.activate([
            host.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            host.view.topAnchor.constraint(equalTo: view.topAnchor),
            host.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        host.didMove(toParent: self)
        stack.isUserInteractionEnabled = false
        stack.accessibilityElementsHidden = true
        updateHeight()
        host.view.transform = CGAffineTransform(translationX: 0, y: keyboardHeight)
        UIView.animate(withDuration: UIAccessibility.isReduceMotionEnabled ? 0 : 0.22) { host.view.transform = .identity }
        UIAccessibility.post(notification: .screenChanged, argument: host.view)
    }
    private func closeSettings(animated: Bool = true) {
        guard let host = settingsHost else { return }
        host.willMove(toParent: nil)
        // Remove synchronously so no obsolete dismissal can remove a newly opened panel.
        host.view.removeFromSuperview()
        host.removeFromParent()
        settingsHost = nil
        stack.isUserInteractionEnabled = true
        stack.accessibilityElementsHidden = false
        updateHeight()
        rebuild()
        if animated { UIAccessibility.post(notification: .screenChanged, argument: stack) }
    }

}

/// A raised keycap with colors resolved again when light/dark appearance changes.
private final class KeyboardKey: UIButton {
    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.cornerRadius = 12
        layer.cornerCurve = .continuous
        layer.borderWidth = 1
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowRadius = 0
        setTitleColor(.label, for: .normal)
        tintColor = .label
        registerForTraitChanges([UITraitUserInterfaceStyle.self, UITraitAccessibilityContrast.self]) {
            (key: KeyboardKey, _: UITraitCollection) in
            key.updateAppearance()
        }
        updateAppearance()
    }

    required init?(coder: NSCoder) { fatalError("Use programmatic initialization") }

    override var isHighlighted: Bool {
        didSet { updateAppearance() }
    }

    override var isSelected: Bool {
        didSet { updateAppearance() }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: 12).cgPath
    }

    private func updateAppearance() {
        tintColor = isSelected ? .systemBlue : .label
        let dark = traitCollection.userInterfaceStyle == .dark
        backgroundColor = isHighlighted
            ? (dark ? UIColor.systemGray2 : UIColor.systemGray4)
            : (dark ? UIColor.systemGray3 : UIColor.white)
        layer.borderColor = UIColor.separator.resolvedColor(with: traitCollection).cgColor
        layer.shadowOpacity = isHighlighted ? 0 : (dark ? 0.5 : 0.25)
        layer.shadowOffset = CGSize(width: 0, height: 2)
        transform = isHighlighted ? CGAffineTransform(translationX: 0, y: 2) : .identity
    }
}

private struct KeyboardSettingsView: View {
    @AppStorage("single") private var single = false
    @AppStorage("decode") private var decode = false
    @AppStorage("smallDot") private var smallDot = false
    @AppStorage("wpm") private var wpm = 10.0
    let done: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Capsule().fill(.tertiary).frame(width: 32, height: 4).padding(.top, 8)
            HStack {
                Text("Keyboard settings").font(.headline)
                Spacer()
                Button("Done", action: done).fontWeight(.semibold).frame(minHeight: 44)
            }.padding(.horizontal, 16)
            Form {
                Section("Typing") {
                    Toggle("Single key", isOn: $single)
                    Toggle("Translate into letters", isOn: $decode)
                    Picker("Dot character", selection: $smallDot) {
                        Text("•  Bullet").tag(false)
                        Text(".  Period").tag(true)
                    }.pickerStyle(.menu)
                }
                Section {
                    HStack { Text("Speed"); Spacer(); Text("\(Int(wpm)) WPM").monospacedDigit().foregroundStyle(.secondary) }
                    Slider(value: $wpm, in: 5...30, step: 1)
                        .accessibilityLabel("Morse speed")
                        .accessibilityValue("\(Int(wpm)) words per minute")
                } footer: {
                    Text("Controls the hold time for a dash and the pause between letters. Lower is easier when learning.")
                }
            }.scrollContentBackground(.hidden)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .tint(.orange)
    }
}
