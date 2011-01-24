local addonName, addonTable = ...
ZRO = LibStub("AceAddon-3.0"):NewAddon("ZRO", "AceConsole-3.0", "AceEvent-3.0", "AceComm-3.0", "AceTimer-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("ZRO", true)
-- FIXME: local
uOO = addonTable.uOO

-- Allow objects access to addon functions
addonTable.ZRO = ZRO

-- Saved Variables
ZRO_PlayerData = {}
ZRO_Settings = {
    filters = {
    }
}
local options = {
    name = "ZRO",
    handler = ZRO,
    type = 'group',
    args = {
        start = {
            type = 'execute',
            name = L["Start planning the raid"],
            desc = L["Start planning the raid"],
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
    uOO:GetClass("FilterSettings"):SetDataStore(ZRO_Settings.filters)

    uOO:GetClass("Guild"):Initialize()

    -- Attempt to obtain calendar information
    local calendar = uOO:Construct("Calendar")
    calendar:RegisterCallback("CalendarLoaded", self.OnCalendarLoaded, self)
    calendar:LoadEvents()

    self.playerList = uOO:Construct("PlayerListModel")
end

function ZRO:OnDisable()
    local calendarClass = uOO:GetClass("Calendar")
    calendarClass:UnregisterCallback("CalendarLoaded")

    uOO:GetClass("Guild"):Finalize()
end


--- TEMP
function ZRO:OnUpdateScroll(frame)
end

function ZRO:OnCalendarLoaded()
    self:Print("Calendar loaded. No idea how.")
end
