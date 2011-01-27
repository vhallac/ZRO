local L = LibStub("AceLocale-3.0"):GetLocale("ZRO", true)

local addonName, addonTable = ...
local uOO = addonTable.uOO

local PlayerListModel = uOO.object:clone()

function PlayerListModel:Initialize()
    self.players = {}
    self.indexMap = {}
    self.callbacks = LibStub("CallbackHandler-1.0"):New(self)

    uOO.PlayerData.RegisterCallback(self, "ListUpdate", "BuildPlayerList")
    uOO.PlayerData.RegisterCallback(self, "PlayerDataChanged", "OnPlayerDataChanged")

    -- Inject 'self' to filter function
    self.filter_func = function(item)
        return self:FilterFunc(item)
    end
    self:BuildPlayerList()
end

function PlayerListModel:BuildPlayerList()
    -- Clear the player list
    while #self.players > 0 do
        self.indexMap[self.players[#self.players]:GetName()] = nil
        table.remove(self.players)
    end

    -- TODO: Add filter and sort functions
    for i, player in uOO.PlayerData:GetIterator(self.filter_func, nil) do
        table.insert(self.players, player)
        self.indexMap[player:GetName()] = #self.players
    end

    self.callbacks:Fire("ListChanged")
end

function PlayerListModel:OnPlayerDataChanged(event, player)
    -- Re-fire the event with different parameters.
    local idx = self.indexMap[player:GetName()]
    if idx then
        self.callbacks:Fire("ItemChanged", idx)
    end
    -- TODO: If we have the player in list, and filter is false for it, or vice
    -- versa, add or remove the player, re-sort, and raise a list changed event.
end

function PlayerListModel:GetItemCount()
    return #self.players
end

function PlayerListModel:GetItem(itemIdx)
    return self.players[itemIdx]
end

-- Now, we'll have specializations of these player lists. The specializations
-- will usually only differ by their filter functions.

-- GuildPlayerList: Source for our player pool. People in this list gets
-- assigned to various lists
local GuildListModel = PlayerListModel:clone()

function GuildListModel:Initialize()
    PlayerListModel.Initialize(self)
    -- The calendar event to source the signup information
    eventSelector = uOO.EventListModel
end

function GuildListModel:FilterFunc(player)
    return true
end

GuildListModel:lock()

uOO.GuildListModel = GuildListModel

-- SitoutList and PenaltyList: People assigned a sitout or penalty.
local SitoutListModel = PlayerListModel:clone()

function SitoutListModel:FilterFunc(player)
    return player:GetLastSitoutDate() == uOO.Calendar:GetDateString()
end

function SitoutListModel:AddItem(player)
    player:AddSitout()
end

function SitoutListModel:RemoveItem(player)
    player:RemoveSitout()
end

function SitoutListModel:GetName()
    return L["Sitouts"]
end

SitoutListModel:lock()
uOO.SitoutListModel = SitoutListModel

local PenaltyListModel = PlayerListModel:clone()

function PenaltyListModel:FilterFunc(player)
    return player:GetLastPenaltyDate() == uOO.Calendar:GetDateString()
end

function PenaltyListModel:AddItem(player)
    player:AddPenalty()
    -- TODO: nail, meet hammer. This is very inefficient for crowded guilds.
    -- Better to add the guy to my lists, and re-sort. Maybe remove sortfunc
    -- from playerData and have a Sort() method in base object.
    self:BuildPlayerList()
end

function PenaltyListModel:RemoveItem(player)
    player:RemovePenalty()
    self:BuildPlayerList()
end

function PenaltyListModel:GetName()
    return L["Penalties"]
end

PenaltyListModel:lock()
uOO.PenaltyListModel = PenaltyListModel

-- And finally a more generic raid list. We will make clones of these, and pass
-- in a raid ID at initialization

local RaidListModel = PlayerListModel:clone()

function RaidListModel:Initialize(raidNumber)
    self.raidNumber = raidNumber
    PlayerListModel.Initialize(self)
end

function RaidListModel:FilterFunc(player)
    return player:GetAssignedRaid() == self.raidNumber
end

function RaidListModel:AddItem(player)
    player:AssignToRaid(self.raidNumber)
    self:BuildPlayerList()
end

function RaidListModel:RemoveItem(player)
    player:RemoveFromRaid()
    self:BuildPlayerList()
end

function RaidListModel:GetName()
    return L["Raid Group: "]..tostring(self.raidNumber)
end

uOO.RaidListModel = RaidListModel
