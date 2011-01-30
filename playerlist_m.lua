local L = LibStub("AceLocale-3.0"):GetLocale("ZRO", true)

local addonName, addonTable = ...
local uOO = addonTable.uOO

local PlayerListModel = uOO.object:clone()

function PlayerListModel:Initialize()
    self.players = {}
    self.indexMap = {}
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
    -- At the end of this loop, indexMap is either -1 to indicate that the
    -- player should be in our final list, or a positive value, which indicates
    -- that the player in the position it points to is no longer in the list and
    -- should be removed.
    for i, player in uOO.PlayerData:GetIterator(self.filter_func) do
        if not self.indexMap[player:GetName()] then
            -- New entry. Add it, and set index as the negative value to be sure
            -- it is not removed at later steps
            table.insert(self.players, player)
            modified = true
        end
        -- mark existing entries
        self.indexMap[player:GetName()] = -1
    end

    -- Now, detect entries that were removed
    for i=1,#self.players do
        local name = self.players[i]:GetName()
        if self.indexMap[name] > 0 then
            -- Item was removed. Get rid of it
            self.indexMap[name] = nil
            table.remove(self.players, i)
            modified = true
        end
    end

    -- Sort the list
    if self.SortFunc then
        table.sort(self.players,
                   function(p1, p2)
                       return self:SortFunc(p1, p2)
                   end)
    end

    -- reindex
    self:IndexItems()

    if modified then
        self.callbacks:Fire("ListChanged")
    end
end

function PlayerListModel:IndexItems(startPos)
    for i= startPos or 1, #self.players do
        local name = self.players[i]:GetName()
        self.indexMap[name] = i
    end
end

function PlayerListModel:OnPlayerUpdate(event, player)
    -- Copied from http://lua-users.org/wiki/BinaryInsert
    local function bininsert(t, value, fcomp)
        --  Initialise numbers
        local iStart,iEnd,iMid,iState = 1,#t,1,0
        -- Get insert position
        while iStart <= iEnd do
            -- calculate middle
            iMid = math.floor( (iStart+iEnd)/2 )
            -- compare
            if fcomp( value,t[iMid] ) then
                iEnd,iState = iMid - 1,0
            else
                iStart,iState = iMid + 1,1
            end
        end
        table.insert( t,(iMid+iState),value )
        return (iMid+iState)
    end

    -- Re-fire the event with different parameters.
    local idx = self.indexMap[player:GetName()]
    local filterResult = self:FilterFunc(player)
    if idx and not filterResult then
        -- We had the player in our list, but the change made it go away.
        -- Delete the entries, and signal a list changed event
        table.remove(self.players, idx)
        self.indexMap[player:GetName()] = nil
        self:IndexItems(idx)
        self.callbacks:Fire("ListChanged")
    elseif filterResult and not idx then
        -- We didn't have the player in list, but the change added it.
        if self.SortFunc then
            idx = bininsert(self.players, player,
                            function(p1, p2)
                                return self:SortFunc(p1, p2)
                            end)
        else
            table.insert(self.players, player)
            idx = #self.players
        end

        self:IndexItems(idx)
        self.callbacks:Fire("ListChanged")
    else
        -- No change to the list. Signal an item modification if we had it in list.
        if idx then
            self.callbacks:Fire("ItemChanged", idx)
        end
    end
end

function PlayerListModel:GetItemCount()
    return #self.players
end

function PlayerListModel:GetItem(itemIdx)
    return self.players[itemIdx]
end

function PlayerListModel:HaveItem(player)
    return self.indexMap[player:GetName()] and true or false
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
