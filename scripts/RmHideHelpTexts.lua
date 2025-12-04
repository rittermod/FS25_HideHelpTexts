-- RmHideHelpTexts - Core module
-- Author: Ritter

RmHideHelpTexts = {}
RmHideHelpTexts.modDirectory = g_currentModDirectory
RmHideHelpTexts.modName = g_currentModName

-- Known help texts with visibility settings
-- Structure: { identifier = { displayNamePositive = "text", displayNameNegative = "text", hidden = bool } }
RmHideHelpTexts.knownHelpTexts = {}

-- Captured context identifiers (populated before dialog opens)
-- Contains action names that are active in current game context
RmHideHelpTexts.capturedContextIdentifiers = {}

-- Path to settings XML file (set in loadSettings)
RmHideHelpTexts.settingsFile = nil

-- Initialize logging
RmLogging.setLogPrefix("[RmHideHelpTexts]")
RmLogging.setLogLevel(RmLogging.LOG_LEVEL.DEBUG)

--- Called when map is loaded
function RmHideHelpTexts:loadMap(filename)
    RmLogging.logInfo("Mod loaded successfully (v%s)", g_modManager:getModByName(self.modName).version)

    -- Register console commands
    addConsoleCommand("hhtList", "Lists all known help texts with visibility status", "consoleCommandList", self)
    addConsoleCommand("hhtToggle", "Toggles visibility of a help text: hhtToggle <identifier>", "consoleCommandToggle",
        self)

    -- Load settings from XML
    self:loadSettings()

    -- Register GUI
    RmHelpTextSettingsDialog.register()
end

--- Called when map is about to unload
function RmHideHelpTexts:deleteMap()
    RmLogging.logDebug("Mod unloading")

    -- Remove console commands
    removeConsoleCommand("hhtList")
    removeConsoleCommand("hhtToggle")
end

--- Registers player action events for GUI keybind
--- Called via PlayerInputComponent.registerGlobalPlayerActionEvents hook
function RmHideHelpTexts.addPlayerActionEvents()
    RmLogging.logDebug("Registering player action events")
    local triggerUp, triggerDown, triggerAlways = false, true, false
    local startActive, callbackState, disableConflictingBindings = true, nil, true

    local success, actionEventId = g_inputBinding:registerActionEvent(
        InputAction.RM_HIDEHELPTEXT_OPEN_GUI,
        RmHideHelpTexts,
        RmHideHelpTexts.showSettingsDialog,
        triggerUp, triggerDown, triggerAlways,
        startActive, callbackState, disableConflictingBindings
    )

    if not success then
        RmLogging.logError("Failed to register action event for RM_HIDEHELPTEXT_OPEN_GUI")
        return
    end

    -- Hide the action event text from HUD
    g_inputBinding:setActionEventTextVisibility(actionEventId, false)
end

--- Left modifier key names (without KEY_ prefix)
local LEFT_MODIFIERS = {
    lshift = "Shift",
    lctrl = "Ctrl",
    lalt = "Alt"
}

--- Right modifier key names (without KEY_ prefix)
local RIGHT_MODIFIERS = {
    rshift = "Shift-R",
    rctrl = "Ctrl-R",
    ralt = "Alt-R"
}

--- Formats axis names array into a display-friendly binding string
--- Example: {"KEY_lshift", "KEY_h"} -> "Shift + H"
--- Example: {"KEY_rctrl", "KEY_q"} -> "Ctrl-R + Q"
--- Left modifiers (lshift, lctrl) show as base name (Shift, Ctrl)
--- Right modifiers (rshift, rctrl) show as base name + "-R" (Shift-R, Ctrl-R)
---@param axisNames table Array of axis/key names
---@return string Formatted binding string
local function formatBindingString(axisNames)
    if not axisNames or #axisNames == 0 then
        return ""
    end

    local parts = {}
    for _, axisName in ipairs(axisNames) do
        -- Strip "KEY_" prefix
        local keyName = axisName
        if string.sub(axisName, 1, 4) == "KEY_" then
            keyName = string.sub(axisName, 5)
        end

        -- Check for specific modifier keys first
        local displayName = LEFT_MODIFIERS[keyName] or RIGHT_MODIFIERS[keyName]

        if not displayName then
            -- Not a modifier, just capitalize first letter
            if string.len(keyName) == 1 then
                displayName = string.upper(keyName)
            else
                displayName = string.upper(string.sub(keyName, 1, 1)) .. string.sub(keyName, 2)
            end
        end

        table.insert(parts, displayName)
    end

    return table.concat(parts, " + ")
end

--- Gets the identifiers of help texts active in the current game context
--- Called before opening dialog to capture what's relevant right now
--- Uses g_inputBinding:getDisplayActionEvents() which is upstream of our filter
---@return table<string, table> Map of action names to {binding = "..."} data
function RmHideHelpTexts.getCurrentContextIdentifiers()
    local identifiers = {}

    if not g_inputBinding then
        RmLogging.logWarning("g_inputBinding not available")
        return identifiers
    end

    -- Get display action events - this is upstream of InputDisplayManager filtering
    -- Returns ALL context-relevant actions regardless of our makeHelpElement hook
    local displayActionEvents = g_inputBinding:getDisplayActionEvents()

    if displayActionEvents then
        for _, event in ipairs(displayActionEvents) do
            if event.action and event.action.name then
                local bindingStr = ""

                -- Try to get binding string from first active binding
                if event.action.activeBindings and #event.action.activeBindings > 0 then
                    local binding = event.action.activeBindings[1]
                    if binding.axisNames then
                        bindingStr = formatBindingString(binding.axisNames)
                    end
                end

                identifiers[event.action.name] = {
                    binding = bindingStr
                }
            end
        end
    end

    return identifiers
end

--- Opens the settings dialog (called by input action)
function RmHideHelpTexts.showSettingsDialog()
    -- Capture current context BEFORE opening dialog (context may change when dialog opens)
    RmHideHelpTexts.capturedContextIdentifiers = RmHideHelpTexts.getCurrentContextIdentifiers()

    local count = 0
    for _ in pairs(RmHideHelpTexts.capturedContextIdentifiers) do
        count = count + 1
    end
    RmLogging.logDebug("Captured %d context identifiers before opening dialog", count)

    RmHelpTextSettingsDialog.show()
end

--- Console command: List all known help texts with visibility status
function RmHideHelpTexts:consoleCommandList()
    local count = 0
    for identifier, data in pairs(self.knownHelpTexts) do
        count = count + 1
        local status = data.hidden and "[HIDDEN]" or "[VISIBLE]"
        local displayText = data.displayNamePositive or ""
        if data.displayNameNegative and data.displayNameNegative ~= "" then
            displayText = displayText .. " / " .. data.displayNameNegative
        end
        print(string.format("  %s %s - %s", status, identifier, displayText))
    end

    if count == 0 then
        return "No help texts recorded yet. Play for a while to collect them."
    end

    return string.format("Listed %d help text(s). Use 'hhtToggle <identifier>' to toggle visibility.", count)
end

--- Console command: Toggle visibility of a help text by identifier
function RmHideHelpTexts:consoleCommandToggle(identifier)
    if identifier == nil or identifier == "" then
        return "Usage: hhtToggle <identifier> (use 'hhtList' to see identifiers)"
    end

    -- Check if identifier exists
    local entry = self.knownHelpTexts[identifier]
    if not entry then
        return string.format("Unknown identifier '%s'. Use 'hhtList' to see known identifiers.", identifier)
    end

    -- Toggle visibility
    entry.hidden = not entry.hidden
    local status = entry.hidden and "HIDDEN" or "VISIBLE"

    RmLogging.logInfo("Help text '%s' is now %s", identifier, status)
    RmHideHelpTexts.saveToFile()

    return string.format("Help text '%s' is now %s", identifier, status)
end

--- Load help text settings from XML file
function RmHideHelpTexts:loadSettings()
    -- Ensure settings directory exists
    local settingsDir = g_modSettingsDirectory .. "FS25_HideHelpTexts/"
    createFolder(settingsDir)

    self.settingsFile = settingsDir .. "settings.xml"

    if not fileExists(self.settingsFile) then
        RmLogging.logInfo("No settings file found, using defaults")
        return
    end

    local xmlFile = loadXMLFile("hideHelpTexts", self.settingsFile)
    if xmlFile == 0 then
        RmLogging.logWarning("Failed to load settings file: %s", self.settingsFile)
        return
    end

    local i = 0
    while true do
        local baseKey = string.format("hideHelpTexts.helpText(%d)", i)
        if not hasXMLProperty(xmlFile, baseKey) then break end

        local identifier = getXMLString(xmlFile, baseKey .. "#identifier")
        if identifier then
            local hidden = getXMLBool(xmlFile, baseKey .. "#hidden") or false
            -- Read new format attributes
            local displayNamePositive = getXMLString(xmlFile, baseKey .. "#displayNamePositive")
            local displayNameNegative = getXMLString(xmlFile, baseKey .. "#displayNameNegative")

            self.knownHelpTexts[identifier] = {
                displayNamePositive = displayNamePositive or "",
                displayNameNegative = displayNameNegative or "",
                hidden = hidden
            }
            RmLogging.logDebug("Loaded help text: %s (hidden=%s)", identifier, tostring(hidden))
        end
        i = i + 1
    end

    delete(xmlFile)
    RmLogging.logInfo("Loaded %d help text(s) from settings", i)
end

--- Called when map finishes loading
--- This is the entry point for the mod
local function onLoadMapFinished()
    RmLogging.logInfo("Map loading finished, initializing RmHideHelpTexts")

    -- Hook into savegame save
    FSBaseMission.saveSavegame = Utils.appendedFunction(
        FSBaseMission.saveSavegame,
        RmHideHelpTexts.saveToFile
    )
end

--- Save help text settings to XML file
function RmHideHelpTexts.saveToFile()
    local self = RmHideHelpTexts

    if not self.settingsFile then
        RmLogging.logWarning("Settings file path not set, skipping save")
        return
    end

    local xmlFile = createXMLFile("settings", self.settingsFile, "hideHelpTexts")
    if xmlFile == 0 then
        RmLogging.logWarning("Failed to create settings file: %s", self.settingsFile)
        return
    end

    local i = 0
    for identifier, data in pairs(self.knownHelpTexts) do
        local baseKey = string.format("hideHelpTexts.helpText(%d)", i)
        setXMLString(xmlFile, baseKey .. "#identifier", identifier)
        setXMLBool(xmlFile, baseKey .. "#hidden", data.hidden or false)
        setXMLString(xmlFile, baseKey .. "#displayNamePositive", data.displayNamePositive or "")
        setXMLString(xmlFile, baseKey .. "#displayNameNegative", data.displayNameNegative or "")
        i = i + 1
    end

    saveXMLFile(xmlFile)
    delete(xmlFile)
    RmLogging.logInfo("Saved %d help text(s) to settings", i)
end

--- Sanitizes a display name by returning empty string if it equals the identifier
--- (Some actions incorrectly have identifier as display name)
---@param displayName string|nil The display name to sanitize
---@param identifier string The action identifier to check against
---@return string The sanitized display name
local function sanitizeDisplayName(displayName, identifier)
    if displayName == nil or displayName == "" then
        return ""
    end
    -- If display name equals identifier, it's not a real display name
    if displayName == identifier then
        return ""
    end
    return displayName
end

-- Override InputDisplayManager.makeHelpElement to hide specified help texts
InputDisplayManager.makeHelpElement = Utils.overwrittenFunction(
    InputDisplayManager.makeHelpElement,
    function(self, original, action1, action2, ...)
        -- Track/update action1 first (ensure display names are always captured)
        local entry1 = RmHideHelpTexts.knownHelpTexts[action1.name]
        local posName1 = sanitizeDisplayName(action1.displayNamePositive, action1.name)
        local negName1 = sanitizeDisplayName(action1.displayNameNegative, action1.name)

        if not entry1 then
            entry1 = {
                displayNamePositive = posName1,
                displayNameNegative = negName1,
                hidden = false
            }
            RmHideHelpTexts.knownHelpTexts[action1.name] = entry1
        else
            -- Update display names if they were empty (e.g., manually added to XML)
            if entry1.displayNamePositive == "" and posName1 ~= "" then
                entry1.displayNamePositive = posName1
            end
            if entry1.displayNameNegative == "" and negName1 ~= "" then
                entry1.displayNameNegative = negName1
            end
        end

        -- Check if action1 should be hidden
        if entry1.hidden then
            RmLogging.logTrace("Hiding help text for action '%s'", action1.name)
            return InputDisplayManager.NO_HELP_ELEMENT
        end

        -- Track/update action2
        if action2 ~= nil then
            local entry2 = RmHideHelpTexts.knownHelpTexts[action2.name]
            local posName2 = sanitizeDisplayName(action2.displayNamePositive, action2.name)
            local negName2 = sanitizeDisplayName(action2.displayNameNegative, action2.name)

            if not entry2 then
                entry2 = {
                    displayNamePositive = posName2,
                    displayNameNegative = negName2,
                    hidden = false
                }
                RmHideHelpTexts.knownHelpTexts[action2.name] = entry2
            else
                if entry2.displayNamePositive == "" and posName2 ~= "" then
                    entry2.displayNamePositive = posName2
                end
                if entry2.displayNameNegative == "" and negName2 ~= "" then
                    entry2.displayNameNegative = negName2
                end
            end

            -- Check if action2 should be hidden
            if entry2.hidden then
                RmLogging.logTrace("Hiding help text for action '%s'", action2.name)
                return InputDisplayManager.NO_HELP_ELEMENT
            end
        end

        return original(self, action1, action2, ...)
    end
)



-- Hook into map loading completion
BaseMission.loadMapFinished = Utils.appendedFunction(
    BaseMission.loadMapFinished,
    onLoadMapFinished
)

-- Hook into player input component for keybind registration
PlayerInputComponent.registerGlobalPlayerActionEvents = Utils.appendedFunction(
    PlayerInputComponent.registerGlobalPlayerActionEvents,
    RmHideHelpTexts.addPlayerActionEvents
)

-- Register mod event listener (calls loadMap/deleteMap)
addModEventListener(RmHideHelpTexts)
