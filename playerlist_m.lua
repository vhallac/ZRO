local L = LibStub("AceLocale-3.0"):GetLocale("ZRO", true)

local addonName, addonTable = ...
local uOO = addonTable.uOO

local PlayerListModel = uOO.object:clone()

local players = {}
local indexMap = {}
local callbacks = LibStub("CallbackHandler-1.0"):New(PlayerListModel)
local eventSelector
local playerData
local controller

function PlayerListModel:Initialize()
    -- TODO: Think a bit more about how to do this.
    local scroller = _G["ZRODialogPlayerListScrollList"]
    controller = uOO.ScrollFrame:clone()
    controller:Initialize(scroller, "ZROPlayerTemplate", self)

    if not eventSelector then
        eventSelector = uOO.EventListModel
    end

    if not playerData then
        playerData = uOO.PlayerData

        -- Make it into a class callback
        playerData:RegisterCallback("PlayerDataChanged", self.OnPlayerDataChanged, self.class)
    end

    self:BuildPlayerList()
end

function PlayerListModel:BuildPlayerList()
    -- Clear the player list
    while #players > 0 do
        print(players[#players], players[#players]:GetName())
        indexMap[players[#players]:GetName()] = nil
        table.remove(players)
    end

    -- TODO: Add filter and sort functions
    for i, player in playerData:GetIterator(nil, nil) do
        ZRO:Print(i, player:GetName())
        table.insert(players, player)
        indexMap[player:GetName()] = #players
    end

    controller:SetItemCount(#players)

    callbacks:Fire("ListChanged")
end

function PlayerListModel:OnPlayerDataChanged(player)
    -- Re-fire the event with different parameters.
    local idx = indexMap[player:GetName()]
    if idx then
        callbacks:Fire("PlayerDataChanged", idx)
    end
end

function PlayerListModel:DisplayItem(itemBtn, itemIdx)
    local player = players[itemIdx]
    if player then
        local prefix = itemBtn:GetName()

        _G[prefix.."Name"]:SetText(player:GetName())
        itemBtn:Show()
    else
        itemBtn:Hide()
    end
end

PlayerListModel:lock()

uOO.PlayerListModel = PlayerListModel
--[[
-- Move this to PlayerData. Allow player sources to add their information to
--player data via an API to the class.
function PlayerListModel:GetIterator(filter_func, sort_func)
    local res = {}

    local guild_filter = function(g_iter)
        return filter_func(g_iter.name)
    end

    -- First, go through everyone in guild who are online. Do not sort yet. We
    -- will sort the consolidated list at the end.
    for g_iter in self.guild:GetIterator(filter_func and guild_filter, nil) do
        res[g_iter.name] = self.playerData:Get(g_iter.name)
    end

    -- Pick up players from the calendar
    local event = self.eventSelector:GetSelected()
    local eventPlayers
    if event then
        eventPlayers = event:GetPlayerIterator()
    end
    if eventPlayers then
        for name in eventPlayers do
            -- Checking it for nil to avoid calling the function unnecessarily.
            res[name] = res[name] or ZRO.players:Get(name)
        end
    end

    -- Finally, pick up players from the current raids. This wouldn't be
    -- necessary under normal circumstances, but we need the players who were
    -- assigned and went offline.
    -- TODO: Implement it.
    -- TODO2: Avoid implementing it by getting offline members with a filter
    --        func on "assigned to raid"

    -- Now that we have a consolidated list of players, sort them
    if sort_func then
        table.sort(res, sort_func)
    end

    local i = 0
    local n = #res
    local iterfunc = function ()
        if i < n then
            i = i + 1
            return i, res[i]
        end
    end

    return iterfunc, res, nil
end
--]]
