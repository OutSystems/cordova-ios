<!--
#
# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
#  KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.
#
-->

# Contributing to Apache Cordova iOS

Anyone can contribute to Cordova. And we need your contributions.

There are multiple ways to contribute: report bugs, improve the docs, and contribute code.

For instructions on this, start with the [contribution overview](http://cordova.apache.org/contribute/).

The details are explained there, but the important items are:
- Check for GitHub issues that correspond to your contribution and link or create them if necessary.
- Run the tests so your patch doesn't break existing functionality.

We look forward to your contributions!

## Development Setup

### Prerequisites

- **Xcode 15.x or greater**: Download from [Apple Developer Downloads](https://developer.apple.com/downloads) or the [Mac App Store](https://apps.apple.com/us/app/xcode/id497799835?mt=12)
- **Node.js 20.5.0 or greater**: Download from [nodejs.org](https://nodejs.org)
- **ios-deploy**: Install globally via `npm i -g ios-deploy` (macOS only, required for full testing)

### Installation

Clone the repository and install dependencies:

```bash
git clone https://github.com/apache/cordova-ios.git
cd cordova-ios
npm install
```

### Development with a Cordova Project

To use a local development version of cordova-ios in a Cordova project:

```bash
cordova platform add --link /path/to/cordova-ios
```

This creates a symbolic link, allowing you to test changes without reinstalling the platform.

## Development Workflow

### Branch Naming

This repository primarily uses version branches for releases (e.g., `3.0.x`, `4.0.x`, `5.0.x`). Feature development happens on topic branches that are merged into `master`.

### Commit Message Format

This project follows a **conventional commit style** with type prefixes:

**Format:** `type(scope): description`

**Common types:**
- `feat`: A new feature
- `fix`: A bug fix
- `chore`: Maintenance tasks (deps, build, CI)
- `refactor`: Code refactoring without functional changes
- `doc`: Documentation changes
- `test`: Adding or updating tests
- `ci`: CI/CD workflow changes

**Optional scope:** Specific area affected (e.g., `spm`, `plugins`, `swift`, `catalyst`, `npm`)

**Breaking changes:** Add `!` after type/scope (e.g., `feat!:` or `chore(npm)!:`)

**Examples from this repository:**
```
feat(spm): Support plugins as Swift packages (#1515)
fix: potential problems overriding OTHER_LDFLAGS (#1547)
chore: Xcode 26 fixes for CI (#1561)
refactor!: Deprecate CDVWebViewProcessPoolFactory (#1558)
```

### Testing Requirements

Before submitting a PR, ensure all tests pass:

```bash
npm test
```

This runs:
1. **Linting** (`npm run lint`)
2. **Coverage tests** (`npm run coverage`)
3. **Objective-C tests** (`npm run objc-tests`) - macOS only

On **non-macOS platforms**, run:
```bash
npm run lint
npm run unit-tests
```

## Building and Testing

### Common Commands

| Command | Description |
|---------|-------------|
| `npm install` | Install dependencies |
| `npm test` | Run all tests (lint + coverage + objc-tests) - macOS only |
| `npm run lint` | Run ESLint on JavaScript code |
| `npm run unit-tests` | Run JavaScript unit tests only |
| `npm run coverage` | Run JavaScript tests with code coverage |
| `npm run objc-tests` | Run Objective-C/Swift tests in Xcode (macOS only) |
| `npm run e2e-tests` | Run end-to-end create/build tests |
| `npm run prepare` | Build cordova.js from cordova-js-src |

### Running Objective-C Tests

The Objective-C tests run via Xcode on macOS:

```bash
npm run objc-tests
```

This uses `xcodebuild` to run tests in the iOS Simulator (defaults to iPhone 16). You can specify a different simulator:

```bash
CDV_IOS_SIM="iPhone 15 Pro" npm run objc-tests
```

### Debugging in Xcode

To debug native code:

1. Import the test workspace in Xcode: **File > Open**
2. Navigate to `tests/cordova-ios.xcworkspace`
3. Run tests from Xcode's Test Navigator

## Code Standards

### JavaScript Standards

This project uses [@cordova/eslint-config](https://www.npmjs.com/package/@cordova/eslint-config) for JavaScript linting:

- **Node.js code**: Standard Node.js ESLint rules (`lib/**/*.js`, root configs)
- **Browser code**: Browser-specific rules (`cordova-js-src/**/*.js`, `templates/project/www/**/*.js`)
- **Test code**: Test-specific rules (`tests/spec/**/*.js`)

Run `npm run lint` to check your code.

### Objective-C/Swift Standards

- Follow existing code style in the `CordovaLib` directory
- Use modern Objective-C syntax and conventions
- Handle Swift plugin compatibility carefully
- Address Xcode warnings when practical

## Pull Request Process

### Before Submitting

1. **Create or link an issue**: Ensure there's a GitHub issue for your change
2. **Run tests**: Verify `npm test` passes (or `npm run lint && npm run unit-tests` on non-macOS)
3. **Follow commit conventions**: Use conventional commit format
4. **Update documentation**: If your change affects public APIs or user-facing features

### PR Template Checklist

When you create a PR, you'll see a template with this checklist:

- [ ] I've run the tests to see all new and existing tests pass
- [ ] I added automated test coverage as appropriate for this change
- [ ] Commit is prefixed with `(platform)` if this change only applies to one platform (e.g. `(android)`)
- [ ] If this Pull Request resolves an issue, I linked to the issue in the text above (and used the correct [keyword to close issues using keywords](https://help.github.com/articles/closing-issues-using-keywords/))
- [ ] I've updated the documentation if necessary

### PR Description

Include in your PR:

- **Platforms affected**: (e.g., iOS)
- **Motivation and Context**: Why is this change needed? What problem does it solve?
- **Description**: Detailed explanation of changes
- **Testing**: How you tested your changes

### Review Process

- PRs require review from Apache Cordova maintainers
- CI must pass on all platforms (macOS, Linux, Windows)
- Address review feedback by pushing additional commits
- Maintainers will merge when approved

## Code Coverage

This project uses [c8](https://www.npmjs.com/package/c8) for JavaScript code coverage:

- Coverage reports are in the `coverage/` directory after running `npm run coverage`
- Coverage includes all files in `lib/**`
- CI uploads coverage to Codecov automatically

## Additional Resources

- [Apache Cordova Contribution Guidelines](http://cordova.apache.org/contribute/contribute_guidelines.html)
- [Apache Cordova Documentation](https://cordova.apache.org/docs/en/latest/)
- [Cordova iOS API Documentation](https://apache.github.io/cordova-ios/)
- [Cordova Slack](https://cordova.slack.com/) - Join for discussions

## Getting Help

- **GitHub Issues**: [apache/cordova-ios/issues](https://github.com/apache/cordova-ios/issues)
- **Slack**: [Cordova Slack](https://cordova.slack.com/)
- **Mailing List**: [Cordova Dev Mailing List](http://cordova.apache.org/contact/)

Thank you for contributing to Apache Cordova iOS!
