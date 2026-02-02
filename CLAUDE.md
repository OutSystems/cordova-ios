# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Apache Cordova-iOS is a platform implementation that enables building iOS applications from web-based Cordova projects. This is a Node.js-based CLI tool that orchestrates Xcode builds, manages native iOS dependencies, and bridges web content to native iOS frameworks.

**Key References:**
- See [ARCHITECTURE.md](./ARCHITECTURE.md) for system architecture, external integrations, and architectural tenets
- See [CONTRIBUTING.md](./CONTRIBUTING.md) for development workflow, testing requirements, and PR guidelines
- See [README.md](./README.md) for basic project setup and usage

## Requirements

- **macOS**: Required for building and testing iOS apps
- **Xcode 15.x or greater**: Download from [Apple Developer Downloads](https://developer.apple.com/downloads) or Mac App Store
- **Node.js 20.9.0 or greater**: Required for running the CLI
- **ios-deploy**: For deploying to physical devices (`npm i -g ios-deploy`)
- **CocoaPods 1.16.0+**: For managing native dependencies (optional but recommended)

## Quick Start

```bash
# Install dependencies
npm install

# Run all tests (macOS only)
npm test

# Run linting and unit tests only (cross-platform)
npm run lint
npm run unit-tests
```

## Build and Test Commands

| Command | Description |
|---------|-------------|
| `npm install` | Install all dependencies |
| `npm test` | Run all tests: lint + coverage + objc-tests (macOS only) |
| `npm run lint` | Lint JavaScript code with ESLint |
| `npm run unit-tests` | Run JavaScript unit tests only (Jasmine) |
| `npm run coverage` | Run JavaScript tests with code coverage (c8) |
| `npm run objc-tests` | Run Objective-C/Swift tests in Xcode (macOS only) |
| `npm run e2e-tests` | Run end-to-end platform creation/build tests |
| `npm run prepare` | Build cordova.js from cordova-js-src sources |

### Running Tests on Different Platforms

**On macOS:**
```bash
npm test  # Runs everything including Objective-C tests
```

**On Linux/Windows:**
```bash
npm run lint
npm run unit-tests
```

### Testing with a Custom Simulator

```bash
CDV_IOS_SIM="iPhone 15 Pro" npm run objc-tests
```

## Repository Structure

```
cordova-ios/
├── lib/                   # Node.js CLI implementation (build-time logic)
│   ├── Api.js            # Main platform API entry point (required by Cordova CLI)
│   ├── build.js          # Xcode build orchestration
│   ├── prepare.js        # Project preparation and asset copying
│   ├── run.js            # Launch apps on simulators/devices
│   ├── create.js         # Create new iOS platform projects
│   ├── clean.js          # Clean build artifacts
│   ├── check_reqs.js     # Validate Xcode/tool versions
│   ├── projectFile.js    # Xcode project file parsing/manipulation
│   ├── Podfile.js        # CocoaPods Podfile management
│   ├── PodsJson.js       # Track installed CocoaPods dependencies
│   ├── SwiftPackage.js   # Swift Package Manager integration
│   └── plugman/          # Plugin installation/removal handlers
│
├── CordovaLib/            # Native iOS runtime library
│   ├── Classes/          # Objective-C/Swift runtime classes
│   │   ├── Public/       # Public API (CDVPlugin, CDVViewController, etc.)
│   │   └── Private/      # Private implementations (bridge, webview engine)
│   └── CordovaLib.xcodeproj  # Xcode project for CordovaLib framework
│
├── cordova-js-src/        # JavaScript bridge source (compiled to cordova.js)
│   ├── exec.js           # JavaScript side of native bridge
│   ├── platform.js       # Platform-specific overrides
│   └── plugin/           # Platform-specific plugin APIs
│
├── templates/             # Project templates for new apps
│   ├── project/          # Default app template
│   └── cordova/          # Cordova CLI scripts (build, run, etc.)
│
├── tests/                 # Test suites
│   ├── spec/             # JavaScript unit/e2e tests (Jasmine)
│   ├── CordovaLibTests/  # Objective-C/Swift tests (XCTest)
│   └── cordova-ios.xcworkspace  # Xcode workspace for native tests
│
└── types/                 # TypeScript type definitions
```

## Key Concepts

### Platform API Entry Point

All Cordova CLI interactions go through `/Users/ben.mccarty/Code/cordova-ios/lib/Api.js`, which exports:
- `createPlatform()` - Initialize new iOS platform
- `prepare()` - Update project with latest web assets and config
- `build()` - Build the iOS app
- `run()` - Launch on simulator or device
- `addPlugin()` / `removePlugin()` - Manage native plugins
- `clean()` - Remove build artifacts

### Build-Time vs Runtime Separation

- **Build-time** (`lib/`): Node.js modules that manipulate Xcode projects, generate code, and orchestrate builds
- **Runtime** (`CordovaLib/`): Objective-C/Swift code that runs inside the iOS app and handles plugin execution

### Plugin Installation

Plugins are installed via `lib/plugman/pluginHandlers.js` which:
1. Parses `plugin.xml` for native files, frameworks, and resources
2. Adds them to the Xcode project using the `xcode` npm library
3. Handles CocoaPods dependencies via Podfile generation
4. Supports Swift Package Manager dependencies
5. All operations are idempotent and reversible

### Native Bridge Communication

JavaScript code communicates with native plugins via:
1. `cordova-js-src/exec.js` posts commands to `window.webkit.messageHandlers.cordova.postMessage()`
2. Native WKWebView message handlers receive commands
3. Commands route to appropriate `CDVPlugin` subclasses
4. Responses flow back through callbacks with status codes

## Development Workflow

### Using Development Version in Cordova Project

```bash
# Link your local cordova-ios to a Cordova project
cordova platform add --link /path/to/cordova-ios
```

This creates a symbolic link, allowing you to test changes without reinstalling.

### Commit Message Format

Follow conventional commit style (see [CONTRIBUTING.md](./CONTRIBUTING.md) for full details):

```
type(scope): description

Examples:
feat(spm): Support plugins as Swift packages
fix: potential problems overriding OTHER_LDFLAGS
chore: Xcode 26 fixes for CI
refactor!: Deprecate CDVWebViewProcessPoolFactory
```

**Common types:** `feat`, `fix`, `chore`, `refactor`, `doc`, `test`, `ci`

Add `!` for breaking changes: `feat!:` or `chore(npm)!:`

### Before Submitting PRs

1. Run `npm test` (or `npm run lint && npm run unit-tests` on non-macOS)
2. Follow commit message conventions
3. Link to GitHub issue in PR description
4. Update documentation if changing public APIs

## Debugging

### JavaScript/Node.js Code

Use standard Node.js debugging:
```bash
node --inspect-brk node_modules/.bin/jasmine tests/spec/unit.json
```

### Objective-C/Swift Code

1. Open Xcode: **File > Open**
2. Navigate to `/Users/ben.mccarty/Code/cordova-ios/tests/cordova-ios.xcworkspace`
3. Run tests from Test Navigator (Cmd+U) or set breakpoints and debug

### Xcode Project Files

When debugging project manipulation issues, the Xcode project is located at:
- Test workspace: `/Users/ben.mccarty/Code/cordova-ios/tests/cordova-ios.xcworkspace`
- CordovaLib project: `/Users/ben.mccarty/Code/cordova-ios/CordovaLib/CordovaLib.xcodeproj`

## Code Standards

### JavaScript

- Uses [@cordova/eslint-config](https://www.npmjs.com/package/@cordova/eslint-config)
- Node.js rules for `lib/**/*.js`
- Browser rules for `cordova-js-src/**/*.js`
- Test rules for `tests/spec/**/*.js`
- Run `npm run lint` to check

### Objective-C/Swift

- Follow existing code style in `CordovaLib/`
- Use modern Objective-C syntax
- Handle Swift plugin compatibility carefully
- Address Xcode warnings when practical

## Important Files

### Configuration Files

- `package.json` - Node.js package manifest, defines CLI entry point (`lib/Api.js`)
- `eslint.config.js` - ESLint configuration with different rules per context
- `Cordova.podspec` - CocoaPods podspec for CordovaLib
- `Package.swift` - Swift Package Manager manifest

### Generated Files

- `templates/project/www/cordova.js` - Generated from cordova-js-src/ by `npm run prepare`
- `coverage/` - Code coverage reports from c8

### Build Artifacts

- `.xcworkspace` - Xcode workspace (created when CocoaPods is used)
- `build/` - Compiled binaries and intermediate files
- `DerivedData/` - Xcode build cache

## Common Tasks

### Adding a New Platform API Method

1. Add method to `lib/Api.js` class
2. Update TypeScript definitions in `types/`
3. Add unit tests in `tests/spec/unit/`
4. Update documentation

### Modifying Plugin Installation

1. Edit `lib/plugman/pluginHandlers.js`
2. Ensure install/uninstall operations are symmetric
3. Test with actual plugins that use affected handlers
4. Add unit tests covering new cases

### Updating Xcode Project Manipulation

1. Use the `xcode` npm library (not manual XML parsing)
2. Test changes with `npm run e2e-tests`
3. Verify .pbxproj files remain valid in Xcode
4. Check both new projects and updates to existing projects

### Modifying Native Bridge

1. JavaScript side: Edit `cordova-js-src/exec.js`
2. Native side: Edit `CordovaLib/Classes/Private/Plugins/CDVWebViewEngine/`
3. Run `npm run prepare` to regenerate cordova.js
4. Test with actual plugin execution (e.g., Device plugin)
5. Run both JavaScript and Objective-C test suites

## CI/CD

GitHub Actions workflows in `.github/workflows/`:
- Run on push/PR to master
- Test on macOS (full suite), Linux, and Windows (lint + unit tests)
- Upload coverage to Codecov
- Validate with multiple Xcode versions

## Additional Resources

- [Apache Cordova Documentation](https://cordova.apache.org/docs/en/latest/)
- [Cordova iOS API Documentation](https://apache.github.io/cordova-ios/)
- [Cordova Slack](https://cordova.slack.com/)
- [GitHub Issues](https://github.com/apache/cordova-ios/issues)
