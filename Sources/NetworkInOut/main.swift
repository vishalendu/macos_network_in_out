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
    var addresses: UnsafeMutablePointer<ifaddrs>?
    guard getifaddrs(&addresses) == 0, let first = addresses else {
        return NetworkTotals(incoming: 0, outgoing: 0)
    }
    defer { freeifaddrs(addresses) }

    var totals = NetworkTotals(incoming: 0, outgoing: 0)
    var cursor: UnsafeMutablePointer<ifaddrs>? = first

    while let interface = cursor {
        defer { cursor = interface.pointee.ifa_next }

        guard
            (interface.pointee.ifa_flags & UInt32(IFF_UP)) != 0,
            let address = interface.pointee.ifa_addr,
            address.pointee.sa_family == UInt8(AF_LINK),
            let data = interface.pointee.ifa_data
        else {
            continue
        }

        let name = String(cString: interface.pointee.ifa_name)
        guard name != "lo0" else { continue }

        let stats = data.assumingMemoryBound(to: if_data.self).pointee
        totals.incoming += UInt64(stats.ifi_ibytes)
        totals.outgoing += UInt64(stats.ifi_obytes)
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
