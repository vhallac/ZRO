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
    uOO.UiSetup:LocalizeControls()
end

function ZRO:OnEnable()
    -- Set up the data stores of classes that need persistence
    uOO.PlayerData:SetDataStore(ZRO_PlayerData)
    uOO.FilterSettingsModel:SetDataStore(ZRO_Settings.filters)
    uOO.Guild:Initialize()
    uOO.Roster:Initialize()
    uOO.PlayerData:Initialize()

    -- Attempt to obtain calendar information
    local calendar = uOO.Calendar
    calendar:RegisterCallback("CalendarLoaded", self.OnCalendarLoaded, self)
    calendar:LoadEvents()

    uOO.PlayerListModel:Initialize()
    uOO.RaidSetupsModel:Initialize()

    uOO.UiSetup:Initialize()
end

function ZRO:OnDisable()
    local calendar = uOO.Calendar
    calendar:UnregisterCallback("CalendarLoaded")

    uOO.Guild:Finalize()
end

--- TEMP
function ZRO:OnCalendarLoaded()
    self:Print("Calendar loaded. No idea how.")
end
