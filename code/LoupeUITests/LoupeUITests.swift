//
//  LoupeUITests.swift
//  LoupeUITests
//
//  Drives fastlane snapshot. Every test launches the app with `-LoupeMockData`
//  so each screen shows the fixed persona from MockData rather than live
//  device readings. Navigation uses accessibility identifiers (not localized
//  labels) so the same flow works across every App Store locale, including RTL.
//
//  iPhone is captured in portrait; iPad in landscape. On iPad the home is a
//  NavigationSplitView, so the home shots also select a category to fill the
//  detail pane. Each test uses a fresh launch to keep state deterministic.
//

import UIKit
import XCTest

final class LoupeUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private var isPad: Bool { UIDevice.current.userInterfaceIdiom == .pad }

    @MainActor
    private func launchApp(extraArguments: [String] = []) -> XCUIApplication {
        // App Store screenshots: iPhone in portrait, iPad in landscape.
        XCUIDevice.shared.orientation = isPad ? .landscapeLeft : .portrait

        let app = XCUIApplication()
        setupSnapshot(app)
        app.launchArguments += ["-LoupeMockData"] + extraArguments
        app.launch()
        return app
    }

    /// On iPad the home is a `NavigationSplitView` whose sidebar (intro card and
    /// category list) is collapsed in portrait, leaving only the detail column.
    /// Reveal it so the same identifiers are reachable as on iPhone.
    @MainActor
    private func revealHome(_ app: XCUIApplication) {
        if app.buttons["highlightsButton"].waitForExistence(timeout: 4) { return }
        let toggle = app.buttons["ToggleSidebar"]
        if toggle.exists {
            toggle.tap()
            _ = app.buttons["highlightsButton"].waitForExistence(timeout: 6)
        }
    }

    /// The home/sidebar list (leftmost collection view).
    @MainActor
    private func homeScroller(_ app: XCUIApplication) -> XCUIElement {
        let collection = app.collectionViews.firstMatch
        return collection.exists ? collection : app.tables.firstMatch
    }

    /// The detail list. On iPhone this is the only collection view after a push;
    /// on iPad it is the rightmost of the sidebar/detail pair.
    @MainActor
    private func detailScroller(_ app: XCUIApplication) -> XCUIElement {
        let collections = app.collectionViews.allElementsBoundByIndex
        if collections.count <= 1 { return app.collectionViews.firstMatch }
        return collections.max(by: { $0.frame.maxX < $1.frame.maxX }) ?? app.collectionViews.firstMatch
    }

    /// The iPad sidebar list (leftmost collection once the detail pane is filled).
    @MainActor
    private func sidebarScroller(_ app: XCUIApplication) -> XCUIElement {
        let collections = app.collectionViews.allElementsBoundByIndex
        if collections.count <= 1 { return app.collectionViews.firstMatch }
        return collections.min(by: { $0.frame.minX < $1.frame.minX }) ?? app.collectionViews.firstMatch
    }

    /// Taps an element, falling back to a coordinate tap when SwiftUI reports
    /// the element as present but not hittable (common for List-row buttons
    /// behind a material background).
    @MainActor
    private func tap(_ element: XCUIElement) {
        if element.isHittable {
            element.tap()
        } else {
            element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        }
    }

    @MainActor
    private func categoryRow(_ id: String, in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: "category.\(id)").firstMatch
    }

    /// Scrolls the home list until `element` is present in the hierarchy.
    @MainActor
    private func scrollIntoView(_ element: XCUIElement, in app: XCUIApplication, maxSwipes: Int = 15) {
        let scroller = homeScroller(app)
        var swipes = 0
        while !element.exists && swipes < maxSwipes {
            scroller.swipeUp(velocity: .fast)
            swipes += 1
        }
    }

    /// Reveals the home, scrolls the given category into view, and opens it.
    /// On iPhone this pushes the detail screen; on iPad it fills the detail pane.
    @MainActor
    private func openCategory(_ id: String, in app: XCUIApplication) {
        revealHome(app)
        let row = categoryRow(id, in: app)
        scrollIntoView(row, in: app)
        XCTAssertTrue(row.exists, "category.\(id) not found")
        tap(row)
    }

    // MARK: - Screens

    /// 01 Home. On iPad the first category is selected so the detail pane is filled.
    @MainActor
    func testHome() throws {
        let app = launchApp()
        if isPad {
            openCategory("deviceIdentity", in: app)
        } else {
            revealHome(app)
            XCTAssertTrue(app.buttons["highlightsButton"].waitForExistence(timeout: 10))
        }
        snapshot("01Home")
    }

    /// 02 Onboarding — "What your apps can see" (highlights page, index 2).
    @MainActor
    func testOnboardingAppsCanSee() throws {
        let app = launchApp(extraArguments: ["-LoupeShowOnboarding"])
        let advance = app.buttons["onboardingAdvanceButton"]
        XCTAssertTrue(advance.waitForExistence(timeout: 10))
        for _ in 0..<2 { tap(advance) }
        snapshot("02AppsCanSee")
    }

    /// 03 Needs Permission section. On iPad "Motion & Sensors" is selected and the
    /// sidebar is scrolled to the permissioned tier; on iPhone the home list is
    /// scrolled so the section is visible.
    @MainActor
    func testNeedsPermission() throws {
        let app = launchApp()
        if isPad {
            openCategory("motion", in: app)
        } else {
            revealHome(app)
            let motion = categoryRow("motion", in: app)
            scrollIntoView(motion, in: app)
            XCTAssertTrue(motion.exists)
        }
        snapshot("03NeedsPermission")
    }

    /// 04 Onboarding — "What your installed apps say about you" (apps page, index 3).
    @MainActor
    func testOnboardingInstalledApps() throws {
        let app = launchApp(extraArguments: ["-LoupeShowOnboarding"])
        let advance = app.buttons["onboardingAdvanceButton"]
        XCTAssertTrue(advance.waitForExistence(timeout: 10))
        for _ in 0..<3 { tap(advance) }
        snapshot("04InstalledApps")
    }

    /// 05 Photos, scrolled to the geolocation (recent / frequent locations).
    @MainActor
    func testPhotosGeotags() throws {
        let app = launchApp()
        openCategory("photos", in: app)

        // On iPad the selected Photos row sits at the bottom of the sidebar,
        // clipped. Nudge the sidebar up a little so the whole cell is visible.
        if isPad {
            let sidebar = sidebarScroller(app)
            let start = sidebar.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.8))
            let end = sidebar.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.55))
            start.press(forDuration: 0.1, thenDragTo: end)
        }

        let scroller = detailScroller(app)
        for _ in 0..<4 { scroller.swipeUp(velocity: .fast) }
        snapshot("05PhotosGeotags")
    }

    /// 06 Bluetooth.
    @MainActor
    func testBluetooth() throws {
        let app = launchApp()
        openCategory("bluetooth", in: app)
        snapshot("06Bluetooth")
    }

    /// 07 Local Network.
    @MainActor
    func testLocalNetwork() throws {
        let app = launchApp()
        openCategory("localNetwork", in: app)
        snapshot("07LocalNetwork")
    }

    /// 08 Motion & Sensors.
    @MainActor
    func testMotionSensors() throws {
        let app = launchApp()
        openCategory("motion", in: app)
        snapshot("08MotionSensors")
    }
}
