import AppKit
import SwiftUI

/// A view that records a keyboard shortcut when clicked.
struct ShortcutRecorderView: View {
    let label: String
    @Binding var shortcut: HotKeyShortcut?
    @State private var isRecording = false

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Button {
                isRecording.toggle()
            } label: {
                if isRecording {
                    Text("Press shortcut...")
                        .foregroundStyle(.red)
                        .frame(minWidth: 120)
                } else if let shortcut {
                    Text(shortcut.description)
                        .frame(minWidth: 120)
                } else {
                    Text("Record Shortcut")
                        .foregroundStyle(.secondary)
                        .frame(minWidth: 120)
                }
            }
            .onKeyPress(phases: .down) { press in
                guard isRecording else { return .ignored }
                // Require at least one modifier key
                let modifiers = press.modifiers
                guard !modifiers.isEmpty else { return .ignored }

                // We need to get the raw key code via NSEvent
                // onKeyPress doesn't give us keyCode directly, so we use NSEvent monitor
                return .ignored
            }

            if shortcut != nil {
                Button {
                    self.shortcut = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.borderless)
            }
        }
        .background(
            ShortcutRecorderHelper(isRecording: $isRecording, shortcut: $shortcut)
        )
    }
}

/// NSView-based helper that uses NSEvent local monitor to capture key events.
struct ShortcutRecorderHelper: NSViewRepresentable {
    @Binding var isRecording: Bool
    @Binding var shortcut: HotKeyShortcut?

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        context.coordinator.isRecording = isRecording
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(isRecording: $isRecording, shortcut: $shortcut)
    }

    class Coordinator {
        var isRecording: Bool = false {
            didSet {
                if isRecording && monitor == nil {
                    startMonitoring()
                } else if !isRecording {
                    stopMonitoring()
                }
            }
        }
        var shortcutBinding: Binding<HotKeyShortcut?>
        var isRecordingBinding: Binding<Bool>
        var monitor: Any?

        init(isRecording: Binding<Bool>, shortcut: Binding<HotKeyShortcut?>) {
            self.isRecordingBinding = isRecording
            self.shortcutBinding = shortcut
        }

        func startMonitoring() {
            monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
                guard let self, self.isRecording else { return event }

                // Require at least one modifier
                let mods = event.modifierFlags.intersection([.command, .option, .control, .shift])
                guard !mods.isEmpty else {
                    if event.keyCode == 53 { // Escape - cancel recording
                        DispatchQueue.main.async {
                            self.isRecordingBinding.wrappedValue = false
                        }
                        return nil
                    }
                    return event
                }

                let shortcut = HotKeyShortcut.from(event: event)
                DispatchQueue.main.async {
                    self.shortcutBinding.wrappedValue = shortcut
                    self.isRecordingBinding.wrappedValue = false
                }
                return nil // consume the event
            }
        }

        func stopMonitoring() {
            if let monitor {
                NSEvent.removeMonitor(monitor)
            }
            monitor = nil
        }

        deinit {
            stopMonitoring()
        }
    }
}
