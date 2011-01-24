local L = LibStub("AceLocale-3.0"):GetLocale("ZRO", true)

local addonName, addonTable = ...
local uOO = addonTable.uOO

local obj = uOO:NewClass("PlayerListModel",
                         {
                         })


function obj:Construct()
    self.players = {}
    self.indexMap = {}

    if not self.class.callbacks then
        self.class.callbacks = LibStub("CallbackHandler-1.0"):New(self.class)
    end

    -- No need to put this in class. This will have only one instance anyway.
    -- TODO: Move all "singleton" stuff to the clas object, and let as many
    -- objects as people want to be instantiated.

    local scroller = _G["ZRODialogPlayerListScrollList"]
    self.controller = uOO:Construct("ScrollFrame",
                                    scroller,
                                    "ZROPlayerTemplate",
                                    self)

    if not self.class.eventSelector then
        self.class.eventSelector = uOO:Construct("EventListModel")
    end

    if not self.class.playerData then
        self.class.playerData = uOO:Construct("PlayerData")
        -- Make it into a class callback
        self.class.playerData:RegisterCallback("PlayerDataChanged", self.OnPlayerDataChanged, self.class)
    end

    self:BuildPlayerList()
end

function obj:BuildPlayerList()
    -- Clear the player list
    while #self.players > 0 do
        print(self.players[#self.players], self.players[#self.players]:GetName())
        self.indexMap[self.players[#self.players]:GetName()] = nil
        table.remove(self.players)
    end

    -- TODO: Add filter and sort functions
    for i, player in self.playerData:GetIterator(nil, nil) do
        ZRO:Print(i, player:GetName())
        table.insert(self.players, player)
        self.indexMap[player:GetName()] = #self.players
    end

    self.controller:SetItemCount(#self.players)

    self.callbacks:Fire("ListChanged")
end

function obj:OnPlayerDataChanged(player)
    -- Re-fire the event with different parameters.
    local idx = self.indexMap[player:GetName()]
    if idx then
        self.callbacks:Fire("PlayerDataChanged", idx)
    end
end

function obj:DisplayItem(itemBtn, itemIdx)
    local player = self.players[itemIdx]
    if player then
        local prefix = itemBtn:GetName()

        _G[prefix.."Name"]:SetText(player:GetName())
        itemBtn:Show()
    else
        itemBtn:Hide()
    end
end

--[[
-- Move this to PlayerData. Allow player sources to add their information to
--player data via an API to the class.
function obj:GetIterator(filter_func, sort_func)
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
