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

## Todo

### Bugs (tracked for next release)

- Fix: Expand/Contract by Level gets stuck when a row has extra indentation (over-indented children)
- Fix: Titlebar does not show background color until you scroll
- Fix: Sidebar projects auto-expand when dropping items onto them — should stay collapsed or delay expansion
  https://support.hogbaysoftware.com/t/preventing-projects-from-expanding-in-the-sidebar/6080

### Bugs (open, unresolved)

- `item-wrap-to-column` display corruption when switching stylesheets — layout distorts and persists until document is reopened. Confirmed by multiple users.
  https://support.hogbaysoftware.com/t/item-wrap-to-column-bug/6126
- Search bar occasionally appears at wrong position on the page. Intermittent, hard to reproduce.
  https://support.hogbaysoftware.com/t/taskpaper-3-9-4-preview-486-487/6186
- Emoji/emoticon characters return empty search results.
  https://support.hogbaysoftware.com/t/search-and-emoticons/5606
- Sidebar peek shows a vertical bar artifact during window resize (cosmetic).
  https://support.hogbaysoftware.com/t/bug-with-temporary-sidebar-peek/6035

### Crash report analysis (13 crash points reviewed 2026-02-19)

Fixed crashes:
- `fillBackingStoreAttributesInRange` index out of range — paragraph/item count mismatch during JS→Swift sync. Fixed with guard checks. (3 crash points: DRGI1, CU7t)
- `rectForCancelButton` infinite recursion on macOS 26.x — Apple refactored NSSearchField internals causing mutual recursion with super call. Fixed by removing rect overrides. (4 crash points: CvFd, D5uR, DGIJ, DNyH)
- `OutlineDocument.read` force-unwrap nil — non-UTF8 data caused crash opening documents. Fixed with guard-let in current code. (3 crash points: CtUW, Dufs, k3Ui)

Not actionable (Apple framework bugs, no TaskPaper code in stack):
- QuartzCore Metal lock corruption in MetalContext destructor (BuHH)
- Autorelease pool over-release on macOS 12.0.1 (DcWJ)

Monitor:
- Exception during view drawing on macOS 26.2, current build 487, 1 report, no TaskPaper code in stack — likely AppKit bug (Cc7f)
- Exception in `makeFirstResponder` during search bar hide, old build 477, 1 report (1HFM)

### Feature requests (from forum and web)

- Better visual feedback for active filters/searches — make it clearer which filter or project is currently applied.
  https://support.hogbaysoftware.com/t/new-feature-request/3478
- Search results should optionally show child nodes of matching items.
  https://support.hogbaysoftware.com/t/request-search-feature-should-optionally-show-child-nodes/1413
- Jump to next/previous project keyboard shortcuts.
  https://support.hogbaysoftware.com/t/feature-request-jump-to-next-previous-project/1407
- Horizontal divider lines for visual separation between sections.
  https://support.hogbaysoftware.com/t/feature-request-horizontal-divders/2063
- Paragraph/row border decorations in stylesheets (currently only background-color works for full-row styling).
  https://support.hogbaysoftware.com/t/paragraph-formatting/5602
- Enhanced sidebar styling — allow color-coding sidebar items by tag.
  https://support.hogbaysoftware.com/t/unable-to-style-taskbar-elements-in-taskpaper/5778
- Maintain focus/frame when file is externally edited (relevant for AI tool integrations).
  https://support.hogbaysoftware.com/t/maintain-frame-when-file-externally-edited/5755
- Improved scripting/API documentation.
  https://support.hogbaysoftware.com/t/suggestion-improving-scripting-guide-and-api-documentation/1751
