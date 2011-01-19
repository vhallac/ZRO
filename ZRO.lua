local addonName, addonTable = ...
ZRO = LibStub("AceAddon-3.0"):NewAddon("ZRO", "AceConsole-3.0", "AceEvent-3.0", "AceComm-3.0", "AceTimer-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("ZRO", true)

-- Allow objects access to addon functions
addonTable.ZRO = ZRO

-- Saved Variables
ZRO_PlayerData = {}

local options = {
    name = "ZRO",
    handler = ZRO,
    type = 'group',
    args = {
        start = {
            type = 'execute',
            name = 'Start planning the raid',
            desc = L["START_DIALOG"],
            func = function() ZRO:Start() end,
        },
    }
}

function ZRO:OnInitialize()
    -- Localize the UI
    local uiText = uOO:GetClass("UiText")
    uiText:LocalizeControls()
end

function ZRO:OnEnable()
    -- Set up the data stores of classes that need persistence
    uOO:GetClass("PlayerData"):SetDataStore(ZRO_PlayerData)

    -- Attempt to obtain calendar information
    local calendarClass = uOO:GetClass("Calendar")
    calendarClass:RegisterEvent("CalendarLoaded", self.OnCalendarLoaded, self)
    calendarClass:Initialize()
    self.calendar:LoadEvents()
end

function ZRO:OnDisable()
    local calendarClass = uOO:GetClass("Calendar")
    calendarClass:Finalize()
    calendarClass:UnregisterEvent("CalendarLoaded")
end
