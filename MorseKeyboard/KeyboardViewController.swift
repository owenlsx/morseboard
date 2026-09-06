import UIKit

/// UIKit provides direct touch-down/up events for the timed Morse key.
final class KeyboardViewController: UIInputViewController {
    private let defaults = UserDefaults.standard
    private var single: Bool { get { defaults.bool(forKey: "single") } set { defaults.set(newValue, forKey: "single") } }
    private var decode: Bool { get { defaults.bool(forKey: "decode") } set { defaults.set(newValue, forKey: "decode") } }
    private var wpm: Double { get { defaults.object(forKey: "wpm") as? Double ?? 10 } set { defaults.set(newValue, forKey: "wpm") } }
    private var pending = ""
    private var timer: Timer?
    private var downAt: TimeInterval?
    private var settingsVisible = false
    private let stack = UIStackView()
    private let status = UILabel()
    private var height: NSLayoutConstraint?

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
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        resetPending()
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
        b.titleLabel?.font = .systemFont(ofSize: 19, weight: .medium)
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
        status.textAlignment = .center
        status.font = .systemFont(ofSize: 13, weight: .medium)
        stack.addArrangedSubview(status)
        if settingsVisible {
            stack.addArrangedSubview(row([
                button(single ? "Layout: one key" : "Layout: two keys", action: #selector(toggleLayout)),
                button(decode ? "Output: letters" : "Output: • -", action: #selector(toggleOutput))
            ]))
            stack.addArrangedSubview(row([
                button("Slower −", action: #selector(slower)),
                button("Faster +", action: #selector(faster))
            ]))
        } else if single {
            let key = button("• / -", action: #selector(releaseKey))
            key.titleLabel?.font = .systemFont(ofSize: 48, weight: .bold)
            key.accessibilityLabel = "Morse key"
            key.accessibilityHint = "Short press for dot, long press for dash"
            key.addTarget(self, action: #selector(pressKey), for: .touchDown)
            key.addTarget(self, action: #selector(cancelKey), for: [.touchCancel, .touchUpOutside, .touchDragExit])
            stack.addArrangedSubview(key)
        } else {
            let dot = button("•", action: #selector(dot))
            let dash = button("-", action: #selector(dash))
            dot.accessibilityLabel = "Dot"
            dash.accessibilityLabel = "Dash"
            [dot, dash].forEach { $0.titleLabel?.font = .systemFont(ofSize: 64, weight: .bold) }
            stack.addArrangedSubview(row([dot, dash]))
        }
        let globe = iconButton("globe", label: "Next keyboard", action: #selector(nextKeyboard))
        globe.removeTarget(self, action: #selector(nextKeyboard), for: .touchUpInside)
        globe.accessibilityLabel = "Next keyboard"
        globe.addTarget(self, action: #selector(handleInputModeList(from:with:)), for: .allTouchEvents)
        globe.isHidden = !needsInputModeSwitchKey
        let gear = settingsVisible
            ? button("Done", action: #selector(toggleSettings))
            : iconButton("gearshape", label: "Keyboard settings", action: #selector(toggleSettings))
        gear.accessibilityLabel = settingsVisible ? "Done" : "Keyboard settings"
        let delete = iconButton("delete.left", label: "Delete", action: #selector(deleteKey))
        delete.accessibilityLabel = "Delete"
        let bottom = row([globe, gear, button("space", action: #selector(space)), delete])
        bottom.heightAnchor.constraint(equalToConstant: 48).isActive = true
        stack.addArrangedSubview(bottom)
        updateStatus()
    }
    private func updateStatus() {
        status.text = pending.isEmpty
            ? "\(decode ? "Letters" : "Symbols") · \(Int(wpm)) WPM\(single ? " · hold for dash" : "")"
            : pending.replacingOccurrences(of: ".", with: "•") + "  →  " + (Morse.letters[pending] ?? "?")
    }
    private func emit(_ symbol: String) {
        timer?.invalidate()
        if decode {
            pending += symbol
            updateStatus()
            scheduleCommit()
        } else {
            textDocumentProxy.insertText(symbol == "." ? "•" : "-")
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
        let output = Morse.letters[pending]
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
    @objc private func space() { commit(); textDocumentProxy.insertText(" ") }
    @objc private func nextKeyboard() { resetPending(); advanceToNextInputMode() }
    @objc private func toggleSettings() { commit(); settingsVisible.toggle(); rebuild() }
    @objc private func toggleLayout() { single.toggle(); rebuild() }
    @objc private func toggleOutput() { decode.toggle(); rebuild() }
    @objc private func slower() { wpm = max(5, wpm - 1); updateStatus() }
    @objc private func faster() { wpm = min(30, wpm + 1); updateStatus() }
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
        updateAppearance()
    }

    required init?(coder: NSCoder) { fatalError("Use programmatic initialization") }

    override var isHighlighted: Bool {
        didSet { updateAppearance() }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateAppearance()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: 12).cgPath
    }

    private func updateAppearance() {
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
