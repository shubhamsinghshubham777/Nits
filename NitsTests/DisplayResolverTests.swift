import Testing
import CoreGraphics
@testable import Nits

@MainActor
struct DisplayResolverTests {
    @Test func picksDisplayContainingFrontmostWindow() {
        let windows = FakeWindowList()
        let screens = FakeScreenProvider()
        screens.mainDisplayID = 10
        screens.displays = [
            (id: 10, frame: CGRect(x: 0, y: 0, width: 1440, height: 900)),
            (id: 20, frame: CGRect(x: 1440, y: 0, width: 3840, height: 2160)),
        ]
        windows.perPID[42] = [
            CGRect(x: 2000, y: 100, width: 800, height: 600), // on display 20
        ]
        let resolver = DisplayResolver(windows: windows, screens: screens)
        #expect(resolver.displayID(forPID: 42) == 20)
    }

    @Test func fallsBackToMainWhenPIDHasNoOnscreenWindows() {
        let windows = FakeWindowList()
        let screens = FakeScreenProvider()
        screens.mainDisplayID = 7
        screens.displays = [
            (id: 7, frame: CGRect(x: 0, y: 0, width: 1440, height: 900)),
        ]
        let resolver = DisplayResolver(windows: windows, screens: screens)
        #expect(resolver.displayID(forPID: 999) == 7)
    }
}
