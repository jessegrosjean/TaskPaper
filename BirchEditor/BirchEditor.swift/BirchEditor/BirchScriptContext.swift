//
//  JavaScriptContext.swift
//  BirchEditor
//
//  Created by Jesse Grosjean on 6/28/16.
//  Copyright © 2005–2018 Jesse Grosjean. All rights reserved.
//

import BirchOutline
import Foundation
import JavaScriptCore

extension BirchScriptContext {
    var jsBirch: JSValue {
        return jsBirchExports.forProperty("Birch")
    }

    var jsBirchCommands: JSValue {
        return jsBirch.forProperty("commands")
    }

    var jsBirchPreferences: JSValue {
        return jsBirch.forProperty("preferences")
    }

    public var jsOutlineSidebarClass: JSValue {
        return jsBirchExports.forProperty("OutlineSidebar")
    }

    public var jsOutlineEditorClass: JSValue {
        return jsBirchExports.forProperty("OutlineEditor")
    }

    public var jsChoicePaletteClass: JSValue {
        return jsBirchExports.forProperty("ChoicePalette")
    }

    public var jsStyleSheetClass: JSValue {
        return jsBirchExports.forProperty("StyleSheet")
    }

    public var jsSearchesConfigurationOutline: JSValue {
        return jsBirchExports.forProperty("searchesConfigurationOutline")
    }

    public var jsTagsConfigurationOutline: JSValue {
        return jsBirchExports.forProperty("tagsConfigurationOutline")
    }

    public var jsTaskPaperPluginInitFunction: JSValue {
        return jsBirchExports.forProperty("taskPaperPluginInitFunction")
    }

    public var jsWriteRoomPluginInitFunction: JSValue {
        return jsBirchExports.forProperty("writeRoomPluginInitFunction")
    }
}
