local L = LibStub("AceLocale-3.0"):GetLocale("ZRO", true)

local addonName, addonTable = ...
local uOO = addonTable.uOO
local const = addonTable.const

local PlayerListModel = uOO.object:clone()

function PlayerListModel:Initialize()
    self.players = uOO.MarkableDualList:clone()
    local getKey = function(player)
        return player:GetName()
    end
    local sort = self.SortFunc and
        function (p1, p2)
            return self:SortFunc(p1, p2)
        end
    self.players:Initialize(getKey, sort)
    self.callbacks = LibStub("CallbackHandler-1.0"):New(self)

    uOO.PlayerData.RegisterCallback(self, "ListUpdate", "BuildPlayerList")
    uOO.PlayerData.RegisterCallback(self, "PlayerUpdate", "OnPlayerUpdate")

    -- Inject 'self' to filter function
    self.filter_func = function(item)
        return not self.FilterFunc or self:FilterFunc(item)
    end

    self:BuildPlayerList()
end

function PlayerListModel:BuildPlayerList()
    local modified = false

    -- Get the new list of players, and add them to our existing list.
    -- We mark all players we updated, so that we can delete unmarked players
    -- after the loop.
    for i, player in uOO.PlayerData:GetIterator(self.filter_func) do
        if not self.players:HaveItem(player) then
            -- New entry. Add it, and set index as the negative value to be sure
            -- it is not removed at later steps
            self.players:AddItem(player, true)
            modified = true
        end
        -- mark existing entries
        self.players:MarkItem(player)
    end

    -- Now, detect entries that were removed
    for i=1,self.players:GetItemCount() do
        local player = self.players:GetItem(i)
        if not self.players:IsItemMarked(player) then
            -- Item was removed. Get rid of it
            self.players:Remove(i)
            modified = true
        else
            self.players:UnmarkItem(player)
        end
    end

    -- Sort the list
    self.players:Sort()

    if modified then
        self.callbacks:Fire("ListChanged")
    end
end

function PlayerListModel:OnPlayerUpdate(event, player)
    -- Re-fire the event with different parameters.
    local havePlayer = self.players:HaveItem(player)
    local filterResult = self:FilterFunc(player)
    if havePlayer then
        if not filterResult then
            -- We had the player in our list, but the change made it go away.
            -- Delete the entries, and signal a list changed event
            self.players:RemoveItem(player)
            self.callbacks:Fire("ListChanged")
        else
            self.callbacks:Fire("ItemChanged", self.players:GetIndex(player))
        end
    else
        if filterResult then
            -- We didn't have the player in list, but the change added it.
            self.players:AddItem(player)
            self.callbacks:Fire("ListChanged")
        end
    end
end

function PlayerListModel:GetItemCount()
    return self.players:GetItemCount()
end

function PlayerListModel:GetItem(itemIdx)
    return self.players:GetItem(itemIdx)
end

function PlayerListModel:HaveItem(player)
    return self.players:HaveItem(player)
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
    local isOnline = player:IsOnline()
    local status = player:GetSignupStatus()
    local isSigned = status == const.SIGNED or status == const.UNSURE
    return isOnline or isSigned
end

function GuildListModel:SortFunc(p1, p2)
    return p1:GetName() < p2:GetName()
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
