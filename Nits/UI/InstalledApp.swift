import AppKit

struct InstalledApp: Identifiable, Hashable {
    let bundleID: String
    let name: String
    let iconImage: NSImage?
    var id: String { bundleID }

    static func == (lhs: InstalledApp, rhs: InstalledApp) -> Bool {
        lhs.bundleID == rhs.bundleID
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(bundleID)
    }
}

@MainActor
enum InstalledAppsScanner {
    static func scan() -> [InstalledApp] {
        let fm = FileManager.default
        let roots = ["/Applications", "/System/Applications", "/System/Applications/Utilities"]
        var found: [String: InstalledApp] = [:]
        for root in roots {
            guard let entries = try? fm.contentsOfDirectory(atPath: root) else { continue }
            for entry in entries where entry.hasSuffix(".app") {
                let path = "\(root)/\(entry)"
                guard let bundle = Bundle(path: path),
                      let bundleID = bundle.bundleIdentifier else { continue }
                if found[bundleID] != nil { continue }
                let name = (bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String)
                    ?? (bundle.object(forInfoDictionaryKey: "CFBundleName") as? String)
                    ?? (entry as NSString).deletingPathExtension
                let icon = NSWorkspace.shared.icon(forFile: path)
                found[bundleID] = InstalledApp(bundleID: bundleID, name: name, iconImage: icon)
            }
        }
        return found.values.sorted(by: { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending })
    }

    static func appName(forBundleID bundleID: String) -> String {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID),
              let bundle = Bundle(url: url) else { return bundleID }
        return (bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String)
            ?? (bundle.object(forInfoDictionaryKey: "CFBundleName") as? String)
            ?? bundleID
    }

    static func appIcon(forBundleID bundleID: String) -> NSImage? {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else { return nil }
        return NSWorkspace.shared.icon(forFile: url.path)
    }
}
