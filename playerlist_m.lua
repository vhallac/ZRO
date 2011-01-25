local L = LibStub("AceLocale-3.0"):GetLocale("ZRO", true)

local addonName, addonTable = ...
local uOO = addonTable.uOO

local PlayerListModel = uOO.object:clone()

local players = {}
local indexMap = {}
local callbacks = LibStub("CallbackHandler-1.0"):New(PlayerListModel)
local eventSelector
playerData = nil

function PlayerListModel:Initialize()
    if not eventSelector then
        eventSelector = uOO.EventListModel
    end

    if not playerData then
        playerData = uOO.PlayerData

        playerData:RegisterCallback("ListUpdate", self.BuildPlayerList, self)
        playerData:RegisterCallback("PlayerDataChanged", self.OnPlayerDataChanged, self.class)
    end

    self:BuildPlayerList()
end

function PlayerListModel:BuildPlayerList()
    -- Clear the player list
    while #players > 0 do
        indexMap[players[#players]:GetName()] = nil
        table.remove(players)
    end

    -- TODO: Add filter and sort functions
    for i, player in playerData:GetIterator(nil, nil) do
        table.insert(players, player)
        indexMap[player:GetName()] = #players
    end

    callbacks:Fire("ListChanged")
end

function PlayerListModel:OnPlayerDataChanged(player)
    -- Re-fire the event with different parameters.
    local idx = indexMap[player:GetName()]
    if idx then
        callbacks:Fire("ItemChanged", idx)
    end
end

function PlayerListModel:GetItemCount()
    return #players
end

function PlayerListModel:GetItem(itemIdx)
    return players[itemIdx]
end

PlayerListModel:lock()

uOO.PlayerListModel = PlayerListModel
