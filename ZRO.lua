local addonName, addonTable = ...
ZRO = LibStub("AceAddon-3.0"):NewAddon("ZRO", "AceConsole-3.0", "AceEvent-3.0", "AceComm-3.0", "AceTimer-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("ZRO", true)
-- FIXME: local
uOO = addonTable.uOO

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
            name = L["Start planning the raid"],
            desc = L["Start planning the raid"],
            func = function() ZRO:Start() end,
        },
    }
}

function ZRO:OnInitialize()
    -- Localize the UI
--    local uiText = uOO:GetClass("UiText")
--    uiText:LocalizeControls()
end

function ZRO:OnEnable()
    -- Set up the data stores of classes that need persistence
    uOO:GetClass("PlayerData"):SetDataStore(ZRO_PlayerData)

    -- Attempt to obtain calendar information
    local calendarClass = uOO:GetClass("Calendar")
    calendarClass:Initialize()
    calendarClass:RegisterCallback("CalendarLoaded", self.OnCalendarLoaded, self)
    calendarClass:LoadEvents()
end

function ZRO:OnDisable()
    local calendarClass = uOO:GetClass("Calendar")
    calendarClass:UnregisterCallback("CalendarLoaded")
    calendarClass:Finalize()
end


--- TEMP
function ZRO:OnUpdateScroll(frame)
end

function ZRO:OnCalendarLoaded()
    self:Print("Calendar loaded. No idea how.")
end
