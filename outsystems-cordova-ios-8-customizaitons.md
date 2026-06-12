# OutSystems Customizations — cordova-ios 8.0.x

This file documents every customization made on the `outsystems/8.0.x` branch relative to the upstream `rel/8.0.1` tag. Each entry maps the original `outsystems/7.1.x-mabs12` commit to its fate on this branch, with notes for plugin authors and future maintainers.

---

## Commit map

### Ported

| 7.1.x commit | Subject | 8.0.x commit | Adaptation notes |
|---|---|---|---|
| ✅ [`c7edb284`](https://github.com/OutSystems/cordova-ios/commit/c7edb284) | fix: disable CLANG_ENABLE_EXPLICIT_MODULES | [`5ec62d72`](https://github.com/OutSystems/cordova-ios/commit/5ec62d72) | Path changed from `__PROJECT_NAME__.xcodeproj` → `App.xcodeproj`; applied to both Debug and Release project-level configs |
| ✅ [`25baff43`](https://github.com/OutSystems/cordova-ios/commit/25baff43) | fix: revert orientation changes | [`c0a227db`](https://github.com/OutSystems/cordova-ios/commit/c0a227db) | `CDVAppDelegate.m` exists in 8.x but `supportedInterfaceOrientationsForWindow:` was absent again; direct port |
| ✅ [`781d3f7a`](https://github.com/OutSystems/cordova-ios/commit/781d3f7a) | feat: add SupportMac preference | [`863f7844`](https://github.com/OutSystems/cordova-ios/commit/863f7844) | `handleBuildSettings` restructured in 8.x (no early-return guard); null-safe preference check; 3 unit tests adapted to 8.x fixture values |
| ✅ [`a4f4f533`](https://github.com/OutSystems/cordova-ios/commit/a4f4f533) | ci: update CI for OutSystems requirements | [`912a0f2a`](https://github.com/OutSystems/cordova-ios/commit/912a0f2a) | Removed Windows runners and Codecov; CodeQL steps (added in 8.x) retained |

### New additions for OutSystems compatibility

These changes have no 7.1.x equivalent — they are new work required because cordova-ios 8 drops or restructures functionality that OutSystems apps depend on.

| File | Subject | Notes |
|---|---|---|
| `CordovaLib/include/Cordova/CDVWebViewEngine.h` + `Cordova.h` | fix: expose `CDVWebViewEngine` as a public umbrella header | `CDVWebViewEngine` moved to `Private` in 8.x; the `cordova-outsystems-core` category header imports `<Cordova/CDVWebViewEngine.h>` and would not compile without this forwarding header |
| *(NativeShell-Template)* | fix: restore precompiled prefix header via `after_platform_add` hook | cordova-ios 8 dropped the PCH; handled in `private-NativeShell-Template` (`hooks/addPrefixHeader.js`) rather than in this fork to keep the diff lean |

### Discarded — already upstream in 8.x

| 7.1.x commit | Subject | Upstream 8.x equivalent |
|---|---|---|
| ✅ [`4a8f456f`](https://github.com/OutSystems/cordova-ios/commit/4a8f456f) | fix: Fix memory leak from user script handler | [`50898928`](https://github.com/apache/cordova-ios/commit/50898928) in 8.0.0 |
| ✅ [`6018a55e`](https://github.com/OutSystems/cordova-ios/commit/6018a55e) | fix: Error when no simulators are available | [`4f8992a4`](https://github.com/apache/cordova-ios/commit/4f8992a4) in 8.0.0 |
| ✅ [`0ffc0457`](https://github.com/OutSystems/cordova-ios/commit/0ffc0457) | fix(Podfile): Avoid creating an empty Podfile | [`495ab61c`](https://github.com/apache/cordova-ios/commit/495ab61c) in 8.0.0 |
| ✅ [`e5a1863d`](https://github.com/OutSystems/cordova-ios/commit/e5a1863d) | chore!: Bump minimum Xcode version to 15 | 8.x already requires Xcode 15+ |
| ✅ [`652d0e8a`](https://github.com/OutSystems/cordova-ios/commit/652d0e8a) | fix(statusbar): inject script block to compute color | Already in `cordova-js-src/plugin/ios/statusbar.js` |
| ✅ [`f9360ba0`](https://github.com/OutSystems/cordova-ios/commit/f9360ba0) | fix: Prevent recursion in scrollView monkeypatch | Already in `CordovaLib/Classes/Public/CDVPlugin.m` |
| ✅ [`1faa11cc`](https://github.com/OutSystems/cordova-ios/commit/1faa11cc) | refactor!: Make CDVViewController more API friendly | `backgroundColor`, `splashBackgroundColor`, `showInitialSplashScreen`, `_cdv_init` all already in 8.x |
| ✅ [`f06aa6e1`](https://github.com/OutSystems/cordova-ios/commit/f06aa6e1) | fix: correctly set webview and launch background color | 8.x storyboard sets colors via IBInspectable user-defined runtime attributes; XIB gone |
| ✅ [`e8ccd309`](https://github.com/OutSystems/cordova-ios/commit/e8ccd309) | refactor: Modernize some ObjC code | `_cdv_init` refactor and modern `dealloc` already in 8.x `CDVViewController.m` |
| ✅ [`3ecbd71b`](https://github.com/OutSystems/cordova-ios/commit/3ecbd71b) | feat(statusbar): port of simple built-in status support | `CDVStatusBarInternal` plugin, `statusBar` UIView, and `statusBarBackgroundColor` all already in 8.x |

### Discarded — obsolete in 8.x

| 7.1.x commit | Subject | Why obsolete |
|---|---|---|
| ✅ [`f6cf96e7`](https://github.com/OutSystems/cordova-ios/commit/f6cf96e7) | fix: Podfile apostrophes in app name | 8.x uses hardcoded `App` target name; apostrophe escaping is moot |
| ✅ [`a779ef39`](https://github.com/OutSystems/cordova-ios/commit/a779ef39) | chore: Clean up plist-to-config.xml cruft | `bin/cordova_plist_to_config_xml` already removed in 8.x |
| ✅ [`384c151b`](https://github.com/OutSystems/cordova-ios/commit/384c151b) | chore!: Bump NodeJS versions in CI | 8.x CI already uses Node 20/22/24 |

---

## Ported change details

### fix: disable CLANG_ENABLE_EXPLICIT_MODULES

- **8.0.x commit**: [`5ec62d72`](https://github.com/OutSystems/cordova-ios/commit/5ec62d72)
- **File**: `templates/project/App.xcodeproj/project.pbxproj`
- **What it does**: Sets `CLANG_ENABLE_EXPLICIT_MODULES = NO` in both the Debug and Release project-level build configurations.
- **Why**: Xcode 16 enables explicit modules by default, which breaks Objective-C plugin compilation in Cordova projects.

### fix: revert orientation changes

- **8.0.x commit**: [`c0a227db`](https://github.com/OutSystems/cordova-ios/commit/c0a227db)
- **File**: `CordovaLib/Classes/Public/CDVAppDelegate.m`
- **What it does**: Re-adds `application:supportedInterfaceOrientationsForWindow:` to `CDVAppDelegate`. The method was removed in upstream cordova-ios 7.0.0 (commit `77b4689`) and was again absent in 8.0.x.
- **Why**: Removing it causes crashes in the barcode plugin and possibly in customer apps. Keeping it lets the root view controller decide the final supported orientations (the masks are intersected by the OS).

### feat: add SupportMac preference to disable macOS Catalyst target

- **8.0.x commit**: [`863f7844`](https://github.com/OutSystems/cordova-ios/commit/863f7844)
- **Files**: `lib/prepare.js`, `tests/spec/prepare.spec.js`, `tests/spec/fixtures/test-config-3.xml`
- **What it does**: Adds a `SupportMac` Cordova preference (default `true`). When set to `false`, sets `SUPPORTED_PLATFORMS = "iphoneos iphonesimulator"`, `SUPPORTS_MACCATALYST = NO`, and `SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD = NO` on all native targets.
- **Why**: Prevents MABS from generating an unwanted macOS Catalyst build artifact. Usage: `<preference name="SupportMac" value="false" />` in `config.xml`.

### ci: update CI for OutSystems requirements

- **8.0.x commit**: [`912a0f2a`](https://github.com/OutSystems/cordova-ios/commit/912a0f2a)
- **File**: `.github/workflows/ci.yml`
- **What it does**: Removes Windows runners from the `non-darwin` matrix and removes Codecov upload steps.
- **Why**: OutSystems internal CI does not use Windows or Codecov.

### fix: expose CDVWebViewEngine as a public umbrella header

- **Files**: `CordovaLib/include/Cordova/CDVWebViewEngine.h` (new), `CordovaLib/include/Cordova/Cordova.h`
- **What it does**: Adds a forwarding header at `CordovaLib/include/Cordova/CDVWebViewEngine.h` that re-declares the `CDVWebViewEngine` interface, and imports it from the `Cordova.h` umbrella header.
- **Why**: `CDVWebViewEngine` was moved to the `Private` directory in cordova-ios 8.x. `cordova-outsystems-core` ships `CDVWebViewEngine+OutSystems.h` which imports `<Cordova/CDVWebViewEngine.h>`. Without this forwarding header, that import cannot be resolved and the plugin fails to compile.

---

## Status bar decision (Step 5)

**Option B chosen**: rely on the 8.x native infrastructure.

`CDVStatusBarInternal` (`setVisible:` / `setBackgroundColor:`), the `statusBar` UIView overlay, the `statusBarBackgroundColor` property, and the JS-side `statusbar.js` injection are all already present in cordova-ios 8.0.x. No additional native porting was required.

---

## Changes made to `private-NativeShell-Template` for cordova-ios 8 compatibility

`OSWKWebViewEngine` was removed from `cordova-outsystems-core` on branch `wip/RDMR-993-996-combined`. The following companion changes in `private-NativeShell-Template` complete the migration.

---

### ✅ `cordova-outsystems-core`: deleted `expose_cdvwebviewengine.js` and removed its `<hook>` from `plugin.xml`

The hook existed solely to promote `CDVWebViewEngine.h` to a public header in the CordovaLib Xcode project so that `OSWKWebViewEngine` could subclass it. It had two defects that would have caused `cordova plugin add` to fail against cordova-ios 8:

- **Wrong CordovaLib path**: the hook hardcoded the cordova-ios 7 location `platforms/ios/CordovaLib/CordovaLib.xcodeproj/project.pbxproj`. In cordova-ios 8, CordovaLib ships as a Swift Package whose xcodeproj is at `platforms/ios/packages/cordova-ios/CordovaLib/CordovaLib.xcodeproj/project.pbxproj`.
- **`xcode` npm module not resolvable at hook runtime**: the hook did `require("xcode")` at load time, but `xcode` is only nested inside `cordova-ios/node_modules/xcode` and is not hoisted to the project root.

With `OSWKWebViewEngine` gone the hook is no longer needed. `CDVWebViewEngine.h` is now exposed as a public umbrella header directly in this cordova-ios fork (see the detail section above), so the import in `CDVWebViewEngine+OutSystems.h` resolves without any hook.

### ✅ `hooks/utils/plistHelper.js`: updated Info.plist path for cordova-ios 8

cordova-ios 8 uses a fixed `App` directory for the generated project rather than naming it after the app. `plistHelper.js` was updated to check the new path first and fall back to the old one for cordova-ios 7 compatibility:

```js
const newPath = `platforms/ios/App/App-Info.plist`;
const oldPath = `platforms/ios/${name}/${name}-Info.plist`;
this.defaultPlistPath = require('fs').existsSync(newPath) ? newPath : oldPath;
```

### ✅ `hooks/addPrefixHeader.js`: new hook to restore the precompiled prefix header

cordova-ios 8 dropped the `<AppName>-Prefix.pch` that was generated by cordova-ios 7 and that implicitly imported Foundation and UIKit for all ObjC compilation units. An `after_platform_add` hook writes `App-Prefix.pch` into the generated source directory and patches the App target's `project.pbxproj` to enable it. The hook handles both the cordova-ios 8 (`platforms/ios/App/`) and cordova-ios 7 (`platforms/ios/<AppName>/`) project layouts.

---

## Notes for plugin authors


- **Breaking: hooks referencing `platforms/ios/<AppName>/` will break.** cordova-ios 8 always names the generated project directory `App`, so any hook that constructs paths using the app name will fail. Use `platforms/ios/App/` directly, or detect the path dynamically if the hook must support both cordova-ios 7 (MABS 12) and cordova-ios 8 (MABS 13+).

- **Minor: `CDVWebViewProcessPoolFactory` is deprecated.** Plugins that reference this class should migrate away from it; it will be removed in a future release.
