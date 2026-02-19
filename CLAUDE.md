# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

TaskPaper is a macOS plain-text to-do list app. It is shared source for license holders — do not remove licensing code or redistribute binaries without permission.

## Architecture

The codebase has a layered design where core logic lives in JavaScript (CoffeeScript) and the native macOS UI is Swift:

```
TaskPaper/           → App-specific customization (6 Swift files)
BirchEditor.swift/   → Swift UI layer (NSTextView editor, document, windows, pickers)
birch-editor.js/     → View model in CoffeeScript (editor state, selection, style calculations)
BirchOutline.swift/  → Swift wrapper around JS model
birch-outline.js/    → Data model in CoffeeScript (outline, items, attributed strings, query language, undo)
```

Swift communicates with JavaScript via JavaScriptCore. The JS layers are compiled by webpack into minified bundles in `min/` directories, which Xcode copies into the app at build time.

`birch-editor.js` depends on `birch-outline.js` via npm link (local file reference in package.json).

## Build Commands

### JavaScript (requires Node v11.15.0 via nvm)

```bash
nvm use v11.15.0
cd BirchOutline/birch-outline.js && npm run start   # gulp watch + webpack
cd BirchEditor/birch-editor.js && npm run start      # gulp watch + webpack
```

Both use gulp to compile CoffeeScript and webpack to produce minified bundles. Xcode detects changes to the `min/` output.

### Xcode

Build targets via Xcode or command line:
```bash
xcodebuild -project TaskPaper.xcodeproj -scheme "TaskPaper" build           # App Store
xcodebuild -project TaskPaper.xcodeproj -scheme "TaskPaper Direct" build    # Direct sales (Paddle)
xcodebuild -project TaskPaper.xcodeproj -scheme "TaskPaper Setapp" build    # Setapp
```

### Dependencies

- **Carthage**: `carthage update --platform macOS` (Sparkle for auto-updates, Paddle for licensing)
- **SPM**: Sparkle 2.x, Setapp framework (resolved automatically by Xcode)
- **npm**: `npm install` in each JS package directory

### Release

1. Edit `TaskPaper/TaskPaper-Direct-Notes.md` with release notes
2. Update bundle version number in `build.sh` (hardcoded)
3. Run `./build.sh` — builds Direct, Direct Preview, App Store, and Setapp variants
4. Direct/Setapp output goes to `build/TaskPaper-Candidate-(###)/`; App Store goes to Xcode Organizer

## Testing

### JavaScript tests (Mocha + Chai, CoffeeScript)
```bash
cd BirchOutline/birch-outline.js && npm test
```
Test specs are in `BirchOutline/birch-outline.js/test/*-spec.coffee`.

### Swift tests (XCTest)
```bash
xcodebuild -project TaskPaper.xcodeproj -scheme "TaskPaper" test
```
Test files:
- `BirchOutline/BirchOutline.swift/Common/Tests/` — Item, Outline, JavaScriptContext tests
- `BirchEditor/BirchEditor.swift/BirchEditorTests/` — Document, Editor, Storage, StyleSheet tests
- `TaskPaperTests/` — App-level tests (currently placeholder)

## Key Conventions

- The JS layers use CoffeeScript (not TypeScript) compiled via gulp + coffee-script
- Date parsing uses a PEG.js grammar (`date-time-parser.pegjs`)
- Styling uses LESS (`TaskPaper/Default.less`, `TaskPaper/base-stylesheet.less`)
- AppleScript support is defined in `TaskPaper/TaskPaper.sdef`
- Three distribution variants share plist files: `TaskPaper-Info.plist`, `TaskPaper-Direct-Info.plist`, `TaskPaper-Setapp-Info.plist`
- Version is set via `MARKETING_VERSION` in the Xcode project; bundle version is hardcoded in `build.sh`
