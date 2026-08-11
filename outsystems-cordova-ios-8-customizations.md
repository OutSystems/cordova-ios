# OutSystems Customizations — cordova-ios 8.1.x

This file documents every customization made on the `outsystems/8.1.x` branch relative to the upstream `rel/8.1.1` tag. Each entry maps the originating `outsystems/8.0.x` commit to its fate on this branch, with notes for plugin authors and future maintainers.

The previous adoption (`outsystems/8.0.x`, based on `rel/8.0.1`) is documented in the git history of `outsystems-cordova-ios-8-customizaitons.md`, which this file replaces (the old filename had a typo).

---

## Commit map

Base: `rel/8.1.1`. Five fork commits existed on `outsystems/8.0.x` above `rel/8.0.1`; all five carried forward, and one new fix was required.

### Ported

| 8.0.x commit | Subject | Disposition | Adaptation notes |
|---|---|---|---|
| [`57d678a6`](https://github.com/OutSystems/cordova-ios/commit/57d678a6) | fix: disable CLANG_ENABLE_EXPLICIT_MODULES | clean cherry-pick | Upstream did not touch `templates/project/App.xcodeproj/project.pbxproj` between 8.0.1 and 8.1.1 |
| [`db529dc3`](https://github.com/OutSystems/cordova-ios/commit/db529dc3) | fix: revert orientation changes | clean cherry-pick | `supportedInterfaceOrientationsForWindow:` is still absent from upstream `CDVAppDelegate.m` in 8.1.1 |
| [`6d85f2c0`](https://github.com/OutSystems/cordova-ios/commit/6d85f2c0) | feat: add SupportMac preference | clean cherry-pick | Upstream did not touch `lib/prepare.js` between 8.0.1 and 8.1.1 |
| [`f10059a8`](https://github.com/OutSystems/cordova-ios/commit/f10059a8) | ci: update CI for OutSystems requirements | **re-authored** | Upstream restructured `ci.yml`; see below |
| [`528aed8c`](https://github.com/OutSystems/cordova-ios/commit/528aed8c) | fix: expose `CDVWebViewEngine` as a public umbrella header | cherry-pick (headers only) + follow-up fix | Split from the doc it was bundled with; needed a build fix to work at all |

### New in this adoption

| Subject | Notes |
|---|---|
| fix: register the public `CDVWebViewEngine` header in CordovaLib.xcodeproj | Fixes a **pre-existing** 8.0.x defect in the xcodeproj build. Applications were unaffected. See below. |

---

## Ported change details

### fix: disable CLANG_ENABLE_EXPLICIT_MODULES

- **File**: `templates/project/App.xcodeproj/project.pbxproj`
- **What**: sets `CLANG_ENABLE_EXPLICIT_MODULES = NO` in the Debug and Release project-level build configurations.
- **Why**: Xcode 16+ enables explicit modules by default, which breaks Objective-C plugin compilation in Cordova projects.

### fix: revert orientation changes

- **File**: `CordovaLib/Classes/Public/CDVAppDelegate.m`
- **What**: re-adds `application:supportedInterfaceOrientationsForWindow:` to `CDVAppDelegate`, removed upstream in cordova-ios 7.0.0 and still absent in 8.1.1.
- **Why**: removing it causes crashes in the barcode plugin and possibly in customer apps. Keeping it lets the root view controller decide the final supported orientations (the masks are intersected by the OS).

### feat: add SupportMac preference to disable macOS Catalyst target

- **Files**: `lib/prepare.js`, `tests/spec/prepare.spec.js`, `tests/spec/fixtures/test-config-3.xml`
- **What**: adds a `SupportMac` preference (default `true`). When `false`, sets `SUPPORTED_PLATFORMS = "iphoneos iphonesimulator"`, `SUPPORTS_MACCATALYST = NO` and `SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD = NO` on all native targets.
- **Why**: prevents MABS from generating an unwanted macOS Catalyst build artifact. Usage: `<preference name="SupportMac" value="false" />` in `config.xml`.

### ci: update CI for OutSystems requirements

- **File**: `.github/workflows/ci.yml`
- **Disposition**: **re-authored**, not cherry-picked. Upstream reworked the workflow between 8.0.1 and 8.1.1 (notably apache/cordova-ios#1673 and #1674): the `darwin` / `non-darwin` jobs were replaced by `codeql`, `test-native` and `test-node`, and the two per-job Codecov steps were consolidated into one on `test-node`.
- **What**: both original intents re-applied onto the new shape — `windows-latest` dropped from the `test-node` OS matrix, and the single consolidated Codecov step removed.
- **Retained as upstream ships them**: the `codeql` job and the `test-native` macOS matrix.

### fix: expose CDVWebViewEngine as a public umbrella header

- **Files**: `CordovaLib/include/Cordova/CDVWebViewEngine.h` (new), `CordovaLib/include/Cordova/Cordova.h`
- **What**: adds a public forwarding header declaring the `CDVWebViewEngine` interface, imported from the `Cordova.h` umbrella.
- **Why**: `CDVWebViewEngine` lives in `Classes/Private` in cordova-ios 8.x. `cordova-outsystems-core` ships `CDVWebViewEngine+OutSystems.h`, which imports `<Cordova/CDVWebViewEngine.h>`. Without this header that import cannot be resolved and the plugin fails to compile.
- **Still required in 8.1.1**: verified — the private header is byte-for-byte unchanged between `rel/8.0.1` and `rel/8.1.1`.

### fix: register the public CDVWebViewEngine header in CordovaLib.xcodeproj

This corrects a defect that shipped in `outsystems/8.0.x`.

- **Symptom**: building CordovaLib through `CordovaLib.xcodeproj` fails with
  `Cordova.h:36:9: fatal error: 'Cordova/CDVWebViewEngine.h' file not found`.
- **Cause**: the forwarding header was added to `CordovaLib/include/Cordova/` but never registered in `CordovaLib.xcodeproj`, so it is not copied into `Cordova.framework/Headers`.
- **Scope — applications are NOT affected.** cordova-ios 8 ships CordovaLib as a Swift Package, and `Package.swift`'s default `publicHeadersPath` (`CordovaLib/include`) picks the header up with no project registration, so `<Cordova/Cordova.h>` resolves correctly for real apps. Verified by building an app from `private-NativeShell-Template` against the pinned `OutSystems/cordova-ios#8.0.0+0.0.2`: CordovaLib compiles (26 units) with no header error. Only the xcodeproj-based build — this repo's own test workspace and CI — was affected, which is why this was never seen in internal testing of 8.0.x.
- **Pre-existing, not a rebase regression**: running `npm run test:xcode` on the shipped `outsystems/8.0.x` tip (`528aed8c`) reproduces the identical error.

Two changes:

1. **`CordovaLib/CordovaLib.xcodeproj/project.pbxproj`** — register `include/Cordova/CDVWebViewEngine.h` as a `Public` header in both Headers build phases, mirroring the sibling public headers.
2. **`CordovaLib/Classes/Private/Plugins/CDVWebViewEngine/CDVWebViewEngine.h`** — import the public header instead of re-declaring the interface. Once the public header ships in the framework, a translation unit including both the umbrella and the private header sees two declarations and fails with `duplicate interface definition for class 'CDVWebViewEngine'`. `tests/CordovaLibTests/CDVStatusBarTests.m` is **new in 8.1.1** and does exactly that, so this only became reachable on the new base.

`npm run test:xcode` passes on the fork with these changes.

---

## Discarded — already upstream in 8.1.1

All ten items discarded during the 8.0.x adoption were re-verified against `rel/8.1.1` and remain upstream: the memory-leak fix in the user script handler, the no-simulators-available fix, the empty-Podfile fix, the Xcode 15 minimum, the statusbar colour script injection, the `scrollView` monkeypatch recursion guard in `CDVPlugin.m`, the `CDVViewController` API refactor (`backgroundColor`, `splashBackgroundColor`, `showInitialSplashScreen`, `_cdv_init`), the webview/launch background colour handling, the ObjC modernization, and the built-in status bar support (`CDVStatusBarInternal`, the `statusBar` overlay view and `statusBarBackgroundColor`).

Nothing from this bucket had to be re-added by hand.

---

## Notes for plugin authors

- **Breaking: hooks referencing `platforms/ios/<AppName>/` will break.** cordova-ios 8 always names the generated project directory `App`. Use `platforms/ios/App/`, or detect the path dynamically if the hook must support both cordova-ios 7 (MABS 12) and cordova-ios 8 (MABS 13+).
- **Minor: `CDVWebViewProcessPoolFactory` is deprecated.** Plugins referencing it should migrate away; it will be removed in a future release.
- **`CDVWebViewEngine` is importable as `<Cordova/CDVWebViewEngine.h>`** and, as of this release, actually resolves in framework-based builds as well as SPM ones.

---

## Companion changes in `private-NativeShell-Template`

The template pins the engine in `template/package.json` (`"cordova-ios": "OutSystems/cordova-ios#8.0.0+0.0.2"`) and overrides engine defaults through `template/config.xml`, so this adoption does **not** reach customers until that pin is bumped to the new tag.

Verified against the template at `master` (`b6ff5b45`) for the 8.1.1 bump:

- `expose_cdvwebviewengine.js` is gone and no longer referenced from `plugin.xml` — the public umbrella header in this fork replaces it.
- `cordova-outsystems-core/hooks/addPrefixHeader.js` restores the precompiled prefix header. It targets the fixed `platforms/ios/App` layout, which is unchanged in 8.1.1, so it continues to work.
- `cordova-outsystems-core/src/ios/CDVWebViewEngine+OutSystems.h` imports `<Cordova/CDVWebViewEngine.h>`; this is the consumer the umbrella header exists for, and it compiles against 8.1.1.
- `config.xml` sets `SupportMac=false` and `deployment-target=15.0`, both of which still take effect on this base.

Note: the previous revision of this document referred to a `hooks/plistHelper.js` path update and placed `addPrefixHeader.js` under `template/hooks/`. Neither is accurate against the current template — there is no `plistHelper.js` (Info.plist handling lives in `template/hooks/updateInfoPlist.js` and `cordova-outsystems-core/hooks/plistUtils.js`), and the prefix-header hook lives in the core plugin's hooks directory.
