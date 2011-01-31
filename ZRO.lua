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
    local libCfg = LibStub("AceConfig-3.0")
    if libCfg then
        libCfg:RegisterOptionsTable("ZRO", options, {"zro"})
    end

    -- Localize the UI
    uOO.UiSetup:LocalizeControls()
end

function ZRO:OnEnable()
    -- Set up the data stores of classes that need persistence
    uOO.PlayerData:SetDataStore(ZRO_PlayerData)
    uOO.FilterSettingsModel:SetDataStore(ZRO_Settings.filters)

    -- Add Guild as a player data source
    uOO.PlayerData:RegisterPlayerSource("guild",
                                        function(filterfunc)
                                            return uOO.Guild:GetIterator(filterfunc)
                                        end,
                                        function(iter)
                                            return uOO.Guild:GetName(iter)
                                        end)

    -- Initialize classes
    uOO.Guild:Initialize()
    uOO.Roster:Initialize()
    uOO.Calendar:Initialize()
    uOO.EventListModel:Initialize()
    uOO.PlayerData:Initialize()

    uOO.GuildListModel:Initialize()
    uOO.SitoutListModel:Initialize()
    uOO.PenaltyListModel:Initialize()
    uOO.RaidSetupsModel:Initialize()

    uOO.UiSetup:Initialize()
end

function ZRO:OnDisable()
    local calendar = uOO.Calendar

    uOO.Guild:Finalize()
    Calendar:Finalize()
end

function ZRO:Start()
    window = _G["ZRODialog"]
    window:Show()
end
