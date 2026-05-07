import AppKit

class HotkeyManager {

    var onToggle: (() -> Void)?
    private var globalMonitor: Any?
    private var localMonitor: Any?

    func register() {
        // Request Accessibility permission if not yet granted.
        // Only prompt once — macOS remembers approval by bundle ID + signature.
        // Repeated prompts usually mean the app is unsigned or the bundle ID changed.
        if !AXIsProcessTrusted() {
            let opts: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue(): true]
            AXIsProcessTrustedWithOptions(opts)
        }

        // Global hotkey — works system-wide when Accessibility is granted
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.modifierFlags.contains([.command, .shift]) &&
               event.keyCode == 46 { // kVK_ANSI_M
                self?.onToggle?()
            }
        }

        // Local monitor — works when app is focused (no Accessibility needed)
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.modifierFlags.contains([.command, .shift]) &&
               event.keyCode == 46 {
                self?.onToggle?()
                return nil
            }
            return event
        }
    }

    func unregister() {
        if let m = globalMonitor { NSEvent.removeMonitor(m); globalMonitor = nil }
        if let m = localMonitor  { NSEvent.removeMonitor(m); localMonitor = nil }
    }

    deinit { unregister() }
}
