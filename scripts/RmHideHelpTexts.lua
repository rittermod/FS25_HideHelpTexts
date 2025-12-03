-- RmHideHelpTexts - Core module
-- Author: Ritter

RmHideHelpTexts = {}
RmHideHelpTexts.modDirectory = g_currentModDirectory
RmHideHelpTexts.modName = g_currentModName

-- Known help texts with visibility settings
-- Structure: { identifier = { description = "Human text", hidden = bool } }
RmHideHelpTexts.knownHelpTexts = {}

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
    addConsoleCommand("hhtToggle", "Toggles visibility of a help text: hhtToggle <identifier>", "consoleCommandToggle", self)

    -- Load settings from XML
    self:loadSettings()
end

--- Called when map is about to unload
function RmHideHelpTexts:deleteMap()
    RmLogging.logDebug("Mod unloading")

    -- Remove console commands
    removeConsoleCommand("hhtList")
    removeConsoleCommand("hhtToggle")
end

--- Console command: List all known help texts with visibility status
function RmHideHelpTexts:consoleCommandList()
    local count = 0
    for identifier, data in pairs(self.knownHelpTexts) do
        count = count + 1
        local status = data.hidden and "[HIDDEN]" or "[VISIBLE]"
        print(string.format("  %s %s - %s", status, identifier, data.description or ""))
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
            local description = getXMLString(xmlFile, baseKey .. "#description") or ""

            self.knownHelpTexts[identifier] = {
                description = description,
                hidden = hidden
            }
            RmLogging.logDebug("Loaded help text: %s (hidden=%s)", identifier, tostring(hidden))
        end
        i = i + 1
    end

    delete(xmlFile)
    RmLogging.logInfo("Loaded %d help text(s) from settings", i)
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
        setXMLString(xmlFile, baseKey .. "#description", data.description or "")
        i = i + 1
    end

    saveXMLFile(xmlFile)
    delete(xmlFile)
    RmLogging.logInfo("Saved %d help text(s) to settings", i)
end

-- Override InputDisplayManager.makeHelpElement to hide specified help texts
InputDisplayManager.makeHelpElement = Utils.overwrittenFunction(
    InputDisplayManager.makeHelpElement,
    function(self, original, action1, action2, ...)
        -- Track/update action1 first (ensure description is always captured)
        local entry1 = RmHideHelpTexts.knownHelpTexts[action1.name]
        if not entry1 then
            entry1 = {
                description = action1.displayNamePositive or action1.displayNameNegative or "",
                hidden = false
            }
            RmHideHelpTexts.knownHelpTexts[action1.name] = entry1
        elseif entry1.description == "" then
            -- Update description if it was empty (e.g., manually added to XML)
            entry1.description = action1.displayNamePositive or action1.displayNameNegative or ""
        end

        -- Check if action1 should be hidden
        if entry1.hidden then
            RmLogging.logTrace("Hiding help text for action '%s'", action1.name)
            return InputDisplayManager.NO_HELP_ELEMENT
        end

        -- Track/update action2
        if action2 ~= nil then
            local entry2 = RmHideHelpTexts.knownHelpTexts[action2.name]
            if not entry2 then
                entry2 = {
                    description = action2.displayNamePositive or action2.displayNameNegative or "",
                    hidden = false
                }
                RmHideHelpTexts.knownHelpTexts[action2.name] = entry2
            elseif entry2.description == "" then
                entry2.description = action2.displayNamePositive or action2.displayNameNegative or ""
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

-- Register mod event listener (calls loadMap/deleteMap)
addModEventListener(RmHideHelpTexts)
