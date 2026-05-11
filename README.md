# 🔆 Nits

A menu-bar app for macOS that sets your display brightness automatically based on which app is in focus. Define a brightness preset per app, switch apps, and Nits smoothly transitions the screen to the right level.

## Requirements

- macOS 26.4 or newer
- Apple Silicon (arm64) Mac

## Installation

1. Go to the [Releases page](../../releases) and download the latest `Nits-<version>-arm64.dmg`.
2. Open the DMG and drag **Nits.app** into the **Applications** folder.
3. Eject the DMG.
4. Launch Nits from Applications or Spotlight.

### First-launch: macOS will warn you about Nits

Nits is not signed with a paid Apple Developer ID and is not notarized — this is a free, open-source passion project. macOS will therefore show one of two warnings the first time you open it. Both are expected; the app is safe.

**Scenario A — "Nits cannot be opened because the developer cannot be verified."**

1. Click **Done** on the dialog.
2. Open **System Settings → Privacy & Security**.
3. Scroll down to the Security section. You will see a message about Nits being blocked.
4. Click **Open Anyway** next to it, then confirm.

Alternatively, you can right-click (or Control-click) **Nits.app** in Applications, choose **Open**, and confirm in the dialog that appears.

**Scenario B — "Nits is damaged and can't be opened. You should move it to the Trash."**

This misleading message appears on Apple Silicon when macOS attaches a quarantine flag to the downloaded app. The app is not actually damaged. To fix it, open Terminal and run:

```sh
xattr -dr com.apple.quarantine /Applications/Nits.app
```

Then launch Nits again.

## Building from source

```sh
git clone https://github.com/shubhamsinghshubham777/Nits.git
cd Nits
open Nits.xcodeproj
```

Build and run the **Nits** scheme in Xcode. Requires Xcode 26.4 or newer.

## Releasing

Releases are built automatically by [.github/workflows/release.yml](.github/workflows/release.yml) when a `v*` tag is pushed:

```sh
git tag v1.0.0
git push origin v1.0.0
```

The workflow builds an arm64, ad-hoc-signed `.app`, packages it into a DMG with a drag-to-Applications layout, and attaches the DMG to a draft GitHub release for manual publishing.
