# TaskPaper

This project is "shared source" for TaskPaper license owners:

1. Do modify as you see fit for your own use.
2. Do not change or disable any of the licensing code.
3. Do not redistribute binaries without permission from jesse@hogbayoftware.com
4. Do submit pull requests if you would like your changes potentially included in the official TaskPaper release.

I want TaskPaper to continue on. Contact me if you want to do something with the code that does not fit under the above conditions and we can probably work something out.

## Background

I worked adding features to TaskPaper from around 2007-2018.

Around 2018 I decided that I wanted a [new foundation](https://support.hogbaysoftware.com/t/how-does-bike-relate-to-taskpaper/4689) for outlining that wasn't compatible with TaskPaper's approach. Since then most of my time has been spent developing [Bike Outliner](https://www.hogbaysoftware.com/bike/). I fix TaskPaper bugs and update for macOS releases, but other then that I have not actively worked on TaskPaper.

This has been a bit sad for me as TaskPaper is a nice well polished app. But I only have so much work time, and I'm dedicating that time to Bike Outliner's development. 

I hope by making TaskPaper's source available to license holders TaskPaper can continue to grow for those who enjoy it.

## Design

TaskPaper's code is spread across a few different projects:

- `birch-outline.js` The model layer consisting of outline, attributed string, serialization, query language, and undo.
- `BirchOutline.swift` Swift wrapper around model layer.
- `birch-editor.js` The view model layer consisting of editor state, selection, visible lines, and style calculations.
- `BirchEditor.swift` Swift wrapper around birch editor view model layer + most of Swift application code. NSTextView based editor, document, window, picker views, etc.
- `TaskPaper` TaskPaper specific customization to `BirchEditor.swift`. The intention was that there might be other apps that build off `BirchEditor.swift`.

## Building

These instructions work for me, but there could very well be system dependencies that I've not accounting for. Let me know if they don't work for you and I'll add extra notes.

### Update Dependencies

carthage update

### Javascript

This is a bit of a mess. Goal was to make `birch-outline.js` and `BirchOutline.swift` reusable so that other apps could read TaskPaper's file format. Would simplify things to just have a single JavaScript layer and single Swift layer... but getting code to that point would take some time, so that's why it's the way that it is.

1. nvm use v11.15.0 // IMPORTANT!
2. birch-outline.js // npm run start 
3. birch-editor.js // npm run start
4. Now this Xcode project should pickup any changes

npm link - from within `birch-outline` so that `birch-editor` can easily make changes to both birch-outline and birch-editor and keep in sync.
npm start - from within both `birch-outline` so that `birch-editor` so that an updated webpack build will always be in each packages "min" folder. When Xcode BirchOutline and BirchEditor build they will always check if that file has changed, and if so copy the new version into there dependencies.
