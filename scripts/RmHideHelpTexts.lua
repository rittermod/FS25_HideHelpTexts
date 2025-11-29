-- RmHideHelpTexts - Core module
-- Author: Ritter

RmHideHelpTexts = {}
RmHideHelpTexts.modDirectory = g_currentModDirectory
RmHideHelpTexts.modName = g_currentModName

RmHideHelpTexts.hiddenHelpTexts = {
    -- Set of help text identifiers to hide from F1
    ENTER = true,
    CAMERA_SWITCH = true,
    CYCLE_HANDTOOL = true,
    TOGGLE_HANDTOOL = true,
    TOGGLE_LIGHTS_FPS = true,
    TOGGLE_MAP_SIZE = true,
    CP_DBG_CHANNEL_MENU_VISIBILITY = true,
    CP_DBG_CHANNEL_SELECT_NEXT = true,
    CP_DBG_CHANNEL_SELECT_PREVIOUS = true,
    CP_DBG_CHANNEL_TOGGLE_CURRENT = true,
    SHOW_FIELD_DLG = true,
    VisualAnimalsDialog = true,
    LUMBERJACK_STRENGTH = true,
    PARKVEHICLE_UNPARK_ALL = true,
    PARKVEHICLE_01 = true,
    HONK = true,
}

-- Store shown help texts for debugging
RmHideHelpTexts.shownHelpTexts = {}

-- Initialize logging
RmLogging.setLogPrefix("[RmHideHelpTexts]")
RmLogging.setLogLevel(RmLogging.LOG_LEVEL.DEBUG)

--- Called when map is loaded
function RmHideHelpTexts:loadMap(filename)
    RmLogging.logInfo("Mod loaded successfully (v%s)", g_modManager:getModByName(self.modName).version)
end

--- Called when map is about to unload
function RmHideHelpTexts:deleteMap()
    RmLogging.logDebug("Mod unloading")
end

--Called when map finishes loading
---This is the entry point for the mod
local function onLoadMapFinished()
    RmLogging.logInfo("Map loading finished, initializing RmHideHelpTexts")

    -- Hook into savegame save
    FSBaseMission.saveSavegame = Utils.appendedFunction(
        FSBaseMission.saveSavegame,
        RmHideHelpTexts.saveToFile
    )
end

-- Run on savegame save
function RmHideHelpTexts.saveToFile()
    -- save settings to file

    -- For now, just log the currently shown help texts
    RmLogging.logInfo("Shown help texts in this session:")
    RmLogging.logInfo(RmLogging.tableToString(RmHideHelpTexts.shownHelpTexts, 2))
end

-- Override InputDisplayManager.makeHelpElement to hide specified help texts
InputDisplayManager.makeHelpElement = Utils.overwrittenFunction(
    InputDisplayManager.makeHelpElement,
    function(self, original, action1, action2, ...)
        if RmHideHelpTexts.hiddenHelpTexts[action1.name] then
            RmLogging.logDebug("Hiding help text for action '%s'", action1.name)
            return InputDisplayManager.NO_HELP_ELEMENT
        end
        if action2 ~= nil and RmHideHelpTexts.hiddenHelpTexts[action2.name] then
            RmLogging.logDebug("Hiding help text for action '%s'", action2.name)
            return InputDisplayManager.NO_HELP_ELEMENT
        end

        RmHideHelpTexts.shownHelpTexts[action1.name] = action1
        if action2 ~= nil then
            RmLogging.logDebug("Showing help text for action2 '%s'", action2.name)
            RmHideHelpTexts.shownHelpTexts[action2.name] = action2
        end
        return original(self, action1, action2, ...)
    end
)



-- Hook into map loading completion
BaseMission.loadMapFinished = Utils.appendedFunction(
    BaseMission.loadMapFinished,
    onLoadMapFinished
)
