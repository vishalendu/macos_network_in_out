import AppKit
import Darwin

struct NetworkTotals {
    var incoming: UInt64
    var outgoing: UInt64
}

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let downloadItem = NSMenuItem()
    private let uploadItem = NSMenuItem()
    private var timer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        if let image = NSImage(systemSymbolName: "arrow.up.arrow.down.circle", accessibilityDescription: "Network totals") {
            image.isTemplate = true
            statusItem.button?.image = image
            statusItem.button?.imagePosition = .imageOnly
        } else {
            statusItem.button?.title = "⇅"
        }
        statusItem.button?.toolTip = "Network totals"

        let menu = NSMenu()
        menu.delegate = self
        downloadItem.isEnabled = false
        uploadItem.isEnabled = false
        menu.addItem(downloadItem)
        menu.addItem(uploadItem)
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        statusItem.menu = menu

        refresh()
    }

    func menuWillOpen(_ menu: NSMenu) {
        refresh()
        timer?.invalidate()
        let timer = Timer(timeInterval: 5, repeats: true) { [weak self] _ in
            self?.refresh()
        }
        self.timer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    func menuDidClose(_ menu: NSMenu) {
        timer?.invalidate()
        timer = nil
    }

    private func refresh() {
        let totals = readNetworkTotals()
        downloadItem.title = "↓ \(formatBytes(totals.incoming))"
        uploadItem.title = "↑ \(formatBytes(totals.outgoing))"
    }
}

func readNetworkTotals() -> NetworkTotals {
    let process = Process()
    let output = Pipe()
    process.executableURL = URL(fileURLWithPath: "/usr/sbin/netstat")
    process.arguments = ["-ibn"]
    process.standardOutput = output
    process.standardError = Pipe()

    do {
        try process.run()
        process.waitUntilExit()
    } catch {
        return NetworkTotals(incoming: 0, outgoing: 0)
    }

    guard
        process.terminationStatus == 0,
        let text = String(data: output.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)
    else {
        return NetworkTotals(incoming: 0, outgoing: 0)
    }

    var totals = NetworkTotals(incoming: 0, outgoing: 0)

    // ponytail: netstat matches Activity Monitor's 64-bit totals; replace with public native API if Apple exposes one.
    for line in text.split(whereSeparator: \.isNewline) {
        let parts = line.split(whereSeparator: \.isWhitespace)
        guard
            parts.count >= 10,
            parts[2].hasPrefix("<Link#"),
            parts[0] != "lo0",
            !parts[0].hasSuffix("*"),
            let incoming = UInt64(parts[parts.count - 5]),
            let outgoing = UInt64(parts[parts.count - 2])
        else {
            continue
        }

        totals.incoming += incoming
        totals.outgoing += outgoing
    }

    return totals
}

func formatBytes(_ bytes: UInt64) -> String {
    ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file)
}

if CommandLine.arguments.contains("--self-test") {
    let totals = readNetworkTotals()
    precondition(!formatBytes(totals.incoming).isEmpty)
    precondition(!formatBytes(totals.outgoing).isEmpty)
    print("↓ \(formatBytes(totals.incoming))")
    print("↑ \(formatBytes(totals.outgoing))")
    exit(0)
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
