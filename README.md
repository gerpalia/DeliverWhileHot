# Deliver While Hot

**Deliver While Hot** is a portrait arcade-game prototype about riding a scooter through a rough neighborhood to deliver food before it cools. It is a learning project and an in-progress playable demo—not a store-ready release.

## Project status

This repository is intended to be a presentable vertical-slice prototype. The main menu, playable road, hazards, food/heat systems, roadside environment, and two-step ending challenge are in place. Visual polish and balance are still being iterated, so simulator playthroughs remain part of the development process.

## Run it

1. Install Xcode with an iOS Simulator runtime (iOS 17 or newer).
2. Open `DeliverWhileHot.xcodeproj` in Xcode.
3. Select the `DeliverWhileHot` scheme and an iPhone simulator, then press **Run**.

The project uses SwiftUI and SpriteKit and has no third-party package dependencies. On the command line, build and run the tests with:

```sh
xcodebuild test \
  -project DeliverWhileHot.xcodeproj \
  -scheme DeliverWhileHot \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  CODE_SIGNING_ALLOWED=NO
```

If that simulator model is not installed, choose an available iPhone under Xcode’s **Window → Devices and Simulators** and substitute its name in the command.

For a beginner-friendly architecture and debugging overview, see [DeliverWhileHot-Coding-Guide.pdf](output/pdf/DeliverWhileHot-Coding-Guide.pdf).

For a build-only check that does not need a signing team:

```sh
xcodebuild build \
  -project DeliverWhileHot.xcodeproj \
  -scheme DeliverWhileHot \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO
```

## How to play

- Drag the left joystick to steer. Move sideways to avoid danger; the roadside is traversable.
- Hold **Block** to guard. Blocking a hit costs one quarter of the food meter (one of four slices). A hit very soon after block begins can be a perfect parry and reflect a damaging projectile.
- Tap **Eat** to spend one slice and restore one heart. It has a cooldown.
- Tap **Molotov** to throw in the last movement direction. It has a cooldown and a limited supply.
- Keep your health, food quality, and food temperature in good shape. The roadside delivery bonus restores two slices; pigeon mess removes one slice.
- At the destination, tap during both **Prepare** and **Jump** timing prompts to make it through the door.

The in-game **How to Play** page is the quick reference; this README also explains how to build and test the project.

## How the code is organized

| Area | What it does |
| --- | --- |
| `DeliverWhileHot/StartView.swift` | Main menu, How to Play, and About sheets |
| `DeliverWhileHot/ContentView.swift` | Places the SpriteKit scene, HUD, controls, and ending UI together |
| `DeliverWhileHot/Game/GameScene.swift` | Advances the world, reads player actions, handles collisions, and coordinates game flow |
| `DeliverWhileHot/Game/GameState.swift` and `GameRules.swift` | Store the small set of game values and perform testable rule calculations |
| `DeliverWhileHot/Game/HazardNode.swift`, `EncounterNode.swift`, `ProjectileNode.swift`, `BonusNode.swift` | Draw and update hazards, human encounters, projectiles, and pickups |
| `DeliverWhileHot/UI/` | SwiftUI HUD, buttons, menu/ending styles, and timing prompts |
| `DeliverWhileHot/Assets.xcassets/` | Character, environment, interface, and effect art |
| `DeliverWhileHotTests/` | Fast tests of rule calculations without launching the game |
| `DeliverWhileHotUITests/` | A basic menu-to-game screen check |

SwiftUI draws menus and interface elements. SpriteKit draws and animates the scrolling game world. `ContentView` is the bridge between them; `GameScene` sends updated state back to the visible interface.

## Tests and continuous integration

`GameRulesTests` checks important numeric rules and boundary conditions. `MenuAndGameplayUITests` checks that the information pages open and that starting a game exposes its controls. A GitHub Actions workflow runs the Xcode test scheme on a hosted macOS runner for pushes and pull requests.

These are a starting safety net, not complete gameplay coverage. Timing, collision geometry, sprite animation, difficulty, and the final sequence still need hands-on simulator testing.

## Optional diagnostics

`DiagnosticsReporter` is a small, dependency-free monitoring hook for prototype builds. It always writes structured events to the local OS log. Remote reporting is disabled by default and no service credentials are stored in the repository.

To point a local run at a test collector, add this environment variable to the Xcode scheme’s Run action:

```text
DELIVER_WHILE_HOT_MONITORING_ENDPOINT=https://your-test-collector.example/events
```

The reporter sends only the event name, app version, OS version, and explicitly supplied string metadata. For a real public build, use a provider such as Sentry or Firebase Crashlytics after choosing an account, privacy policy, retention period, and data-processing terms. Do not enable a production endpoint until those decisions are documented.

## Known prototype limitations

- This is a playable prototype, not a finished or balanced game. Steering feel, hazard spacing, difficulty, and run length still need hands-on testing.
- The thief uses temporary atlas artwork. Its frames now share a normalized size and alignment, but the new sizing still needs an in-game check; several other character and environment visuals are also placeholder or work-in-progress art.
- The ending door and two-step timing challenge are implemented, but the approach, timing windows, and success/failure presentation still need playtesting on a simulator or device.
- The backpack/item action is a disabled placeholder. There is no save system, analytics, crash-reporting service, or remote monitoring configured.
- Automated tests cover selected game rules and basic menu/game navigation, not the full SpriteKit experience. Hazard animation, collisions, steering feel, and the ending sequence require manual playtesting.
- This repository contains development artwork and audio. Review `AUDIO_LICENSES.md` and verify redistribution rights and attribution for **all** art and sound before sharing the repository publicly. Some source URLs and license details are unresolved, so do not assume every asset is cleared for redistribution.

## Before sharing a public snapshot

- Run the build and test commands above on a clean checkout.
- Include a short simulator recording or screenshots so the current prototype state is clear.
- Confirm that every bundled image, sound, and font is permitted for redistribution; unresolved entries in `AUDIO_LICENSES.md` still need manual verification.
- Keep `DerivedData`, `.build`, `xcuserdata`, and `*.xcuserstate` out of commits. They are machine-generated or user-specific and are ignored by this repository.
- Replace the prototype bundle identifier with the eventual product identifier only when the project has a release owner and signing setup.

## Contributing

Build with the `DeliverWhileHot` scheme, run its tests, and include a short simulator recording or screenshots for changes to gameplay visuals. Keep unrelated Xcode workspace state out of commits; the project’s local `xcuserdata` should not be treated as shared source.

## License

The source code is available under the MIT License in [`LICENSE`](LICENSE). That license does **not** cover artwork, images, animations, audio, fonts, videos, or other media included in the repository. Their rights and reuse permissions are separate; see [`AUDIO_LICENSES.md`](AUDIO_LICENSES.md) for the audio inventory. Public availability alone should not be treated as permission to redistribute media.
