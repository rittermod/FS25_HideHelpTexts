-- RmHelpTextSettingsDialog.lua
-- GUI dialog for managing help text visibility
-- Author: Ritter

RmHelpTextSettingsDialog = {}
local RmHelpTextSettingsDialog_mt = Class(RmHelpTextSettingsDialog, MessageDialog)

RmHelpTextSettingsDialog.CONTROLS = {
    "helpTextList",
    "listSlider",
    "emptyListText",
    "buttonViewMode"
}

--- Creates a new RmHelpTextSettingsDialog instance
---@param target table|nil the target object
---@param custom_mt table|nil optional custom metatable
---@return RmHelpTextSettingsDialog the new dialog instance
function RmHelpTextSettingsDialog.new(target, custom_mt)
    RmLogging.logTrace("RmHelpTextSettingsDialog:new()")
    local self = MessageDialog.new(target, custom_mt or RmHelpTextSettingsDialog_mt)
    self.helpTextEntries = {}
    self.showCurrentOnly = true  -- Default to showing current context only
    return self
end

function RmHelpTextSettingsDialog:onGuiSetupFinished()
    RmLogging.logTrace("RmHelpTextSettingsDialog:onGuiSetupFinished()")
    RmHelpTextSettingsDialog:superClass().onGuiSetupFinished(self)
    self.helpTextList:setDataSource(self)
    self.helpTextList:setDelegate(self)
end

function RmHelpTextSettingsDialog:onCreate()
    RmLogging.logTrace("RmHelpTextSettingsDialog:onCreate()")
    RmHelpTextSettingsDialog:superClass().onCreate(self)
end

function RmHelpTextSettingsDialog:onOpen()
    RmLogging.logTrace("RmHelpTextSettingsDialog:onOpen()")
    RmHelpTextSettingsDialog:superClass().onOpen(self)

    -- Reset to default view mode (current context)
    self.showCurrentOnly = true

    -- Update view mode button text
    self:updateViewModeButton()

    -- Build sorted list of help text entries
    self:refreshHelpTextList()

    -- Show/hide empty state message
    self:updateEmptyState()

    -- Reload the list data
    self.helpTextList:reloadData()

    -- Set focus to the list
    self:setSoundSuppressed(true)
    FocusManager:setFocus(self.helpTextList)
    self:setSoundSuppressed(false)
end

function RmHelpTextSettingsDialog:onClose()
    RmLogging.logTrace("RmHelpTextSettingsDialog:onClose()")

    -- Save settings when dialog closes
    RmHideHelpTexts.saveToFile()

    self.helpTextEntries = {}
    RmHelpTextSettingsDialog:superClass().onClose(self)
end

--- Refreshes the help text entries list from RmHideHelpTexts.knownHelpTexts
--- Filters based on showCurrentOnly mode
function RmHelpTextSettingsDialog:refreshHelpTextList()
    self.helpTextEntries = {}

    local capturedIds = RmHideHelpTexts.capturedContextIdentifiers or {}

    for identifier, data in pairs(RmHideHelpTexts.knownHelpTexts) do
        local shouldInclude = true
        local bindingStr = ""

        -- Filter if in "current only" mode
        if self.showCurrentOnly then
            local capturedData = capturedIds[identifier]
            if not capturedData then
                shouldInclude = false
            else
                -- Get binding string from captured context data
                bindingStr = capturedData.binding or ""
            end
        end

        if shouldInclude then
            local entry = {
                identifier = identifier,
                displayNamePositive = data.displayNamePositive or "",
                displayNameNegative = data.displayNameNegative or "",
                hidden = data.hidden or false,
                binding = bindingStr
            }
            table.insert(self.helpTextEntries, entry)
        end
    end

    -- Sort alphabetically by primary display name
    table.sort(self.helpTextEntries, function(a, b)
        return (a.displayNamePositive or "") < (b.displayNamePositive or "")
    end)
end

--- Updates the visibility of the empty state message
--- Shows context-aware message based on view mode
function RmHelpTextSettingsDialog:updateEmptyState()
    local isEmpty = #self.helpTextEntries == 0
    self.emptyListText:setVisible(isEmpty)
    self.helpTextList:setVisible(not isEmpty)

    if isEmpty then
        if self.showCurrentOnly then
            self.emptyListText:setText(g_i18n:getText("ui_inputHelpVisibility_emptyContext"))
        else
            self.emptyListText:setText(g_i18n:getText("ui_inputHelpVisibility_empty"))
        end
    end
end

--- Updates the view mode button text to show what clicking will do
function RmHelpTextSettingsDialog:updateViewModeButton()
    if self.buttonViewMode then
        if self.showCurrentOnly then
            -- Currently showing current, clicking will show all
            self.buttonViewMode:setText(g_i18n:getText("ui_inputHelpVisibility_showAll"))
        else
            -- Currently showing all, clicking will show current
            self.buttonViewMode:setText(g_i18n:getText("ui_inputHelpVisibility_showCurrent"))
        end
    end
end

--- Toggles between showing current context and all known help texts
function RmHelpTextSettingsDialog:toggleViewMode()
    self.showCurrentOnly = not self.showCurrentOnly

    local mode = self.showCurrentOnly and "Current" or "All"
    RmLogging.logDebug("View mode toggled to: %s", mode)

    self:updateViewModeButton()
    self:refreshHelpTextList()
    self:updateEmptyState()
    self.helpTextList:reloadData()
end

-- DataSource methods

function RmHelpTextSettingsDialog:getNumberOfItemsInSection(list, section)
    if list == self.helpTextList then
        return #self.helpTextEntries
    end
    return 0
end

function RmHelpTextSettingsDialog:populateCellForItemInSection(list, section, index, cell)
    if list == self.helpTextList then
        local entry = self.helpTextEntries[index]
        if entry then
            -- Sanitize: treat display name as empty if it equals the identifier
            local displayName = entry.displayNamePositive
            if displayName == entry.identifier then
                displayName = ""
            end

            -- Primary display name (fallback to identifier if empty)
            local primaryText = displayName
            if primaryText == nil or primaryText == "" then
                primaryText = entry.identifier or ""
            end
            cell:getAttribute("primaryText"):setText(primaryText)

            -- Secondary: show identifier below (only if we have a real display name)
            -- Also append key binding if available: "IDENTIFIER [Q]"
            local secondaryText = ""
            if displayName and displayName ~= "" then
                secondaryText = entry.identifier or ""
            end

            -- Append binding if available
            if entry.binding and entry.binding ~= "" then
                if secondaryText ~= "" then
                    secondaryText = secondaryText .. " - " .. entry.binding
                else
                    -- No identifier shown, but we have binding - show just binding
                    secondaryText = entry.binding
                end
            end
            cell:getAttribute("secondaryText"):setText(secondaryText)

            -- Toggle state (ON = visible, OFF = hidden)
            local toggleText = entry.hidden and "OFF" or "ON"
            cell:getAttribute("toggleState"):setText(toggleText)
        end
    end
end

-- Delegate methods

--- Called when a list item is clicked (via mouse or Enter key)
function RmHelpTextSettingsDialog:onListItemClicked(list, section, index)
    if list == self.helpTextList and index > 0 and index <= #self.helpTextEntries then
        local entry = self.helpTextEntries[index]
        if entry then
            -- Toggle the hidden state
            self:toggleHelpText(entry.identifier)
        end
    end
end

--- Toggles the visibility of a help text
---@param identifier string the help text identifier
function RmHelpTextSettingsDialog:toggleHelpText(identifier)
    local data = RmHideHelpTexts.knownHelpTexts[identifier]
    if data then
        data.hidden = not data.hidden
        local status = data.hidden and "HIDDEN" or "VISIBLE"
        RmLogging.logDebug("Help text '%s' toggled to %s", identifier, status)

        -- Preserve selection position
        local selectedIndex = self.helpTextList.selectedIndex

        -- Refresh list display
        self:refreshHelpTextList()
        self.helpTextList:reloadData()

        -- Restore selection (clamp to valid range)
        if selectedIndex and selectedIndex > 0 then
            local maxIndex = #self.helpTextEntries
            if selectedIndex > maxIndex then
                selectedIndex = maxIndex
            end
            if selectedIndex > 0 then
                self.helpTextList:setSelectedIndex(selectedIndex)
            end
        end
    end
end

-- Button handlers

function RmHelpTextSettingsDialog:onClickViewMode()
    self:toggleViewMode()
end

function RmHelpTextSettingsDialog:onClickToggle()
    local index = self.helpTextList.selectedIndex
    if index ~= nil and index > 0 and index <= #self.helpTextEntries then
        local entry = self.helpTextEntries[index]
        if entry then
            self:toggleHelpText(entry.identifier)
        end
    end
end

function RmHelpTextSettingsDialog:onClickClose()
    RmLogging.logTrace("RmHelpTextSettingsDialog:onClickClose()")
    self:close()
end

-- Input handling

--- Override inputEvent to handle Enter, left/right keys, and X key (MENU_EXTRA_1)
function RmHelpTextSettingsDialog:inputEvent(action, value, eventUsed)
    -- Handle our custom inputs only if event not already used
    if not eventUsed then
        -- MENU_EXTRA_1 (X key) - toggle view mode
        if action == InputAction.MENU_EXTRA_1 then
            self:toggleViewMode()
            eventUsed = true
        end

        local index = self.helpTextList.selectedIndex
        if not eventUsed and index ~= nil and index > 0 and index <= #self.helpTextEntries then
            local entry = self.helpTextEntries[index]
            if entry then
                -- Enter/Accept key - toggle visibility
                if action == InputAction.MENU_ACCEPT then
                    self:toggleHelpText(entry.identifier)
                    eventUsed = true
                -- Left/right axis for directional toggle
                elseif action == InputAction.MENU_AXIS_LEFT_RIGHT then
                    if value < 0 then
                        -- Left = turn ON (show)
                        if RmHideHelpTexts.knownHelpTexts[entry.identifier].hidden then
                            self:toggleHelpText(entry.identifier)
                        end
                    elseif value > 0 then
                        -- Right = turn OFF (hide)
                        if not RmHideHelpTexts.knownHelpTexts[entry.identifier].hidden then
                            self:toggleHelpText(entry.identifier)
                        end
                    end
                    eventUsed = true
                end
            end
        end
    end

    -- Always call superClass to ensure proper event handling chain
    return RmHelpTextSettingsDialog:superClass().inputEvent(self, action, value, eventUsed)
end

-- Static methods

--- Registers the dialog with the GUI system
function RmHelpTextSettingsDialog.register()
    RmLogging.logTrace("RmHelpTextSettingsDialog.register()")
    -- Load GUI profiles first
    g_gui:loadProfiles(RmHideHelpTexts.modDirectory .. "gui/guiProfiles.xml")
    -- Then register the dialog
    local dialog = RmHelpTextSettingsDialog.new(g_i18n)
    g_gui:loadGui(RmHideHelpTexts.modDirectory .. "gui/RmHelpTextSettingsDialog.xml", "RmHelpTextSettingsDialog", dialog)
end

--- Shows the help text settings dialog
function RmHelpTextSettingsDialog.show()
    RmLogging.logTrace("RmHelpTextSettingsDialog.show()")
    g_gui:showDialog("RmHelpTextSettingsDialog")
end
