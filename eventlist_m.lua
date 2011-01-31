local addonName, addonTable = ...

local ZRO   = addonTable.ZRO
local uOO   = addonTable.uOO
local const = addonTable.const

-- This is a list of calendar events. The model drives a DropDown Menu.
local EventListModel = uOO.object:clone()

local callbacks = LibStub("CallbackHandler-1.0"):New(EventListModel)
local events = uOO.DualList:clone()
local players = uOO.DualList:clone()
local selected = -1
local clearingInfo = false

function EventListModel:Initialize()
    -- Let me see what goes on in its purty head
    self.players = players

    events:Initialize()
    players:Initialize(function(item) return item[1] end)
    uOO.Calendar.RegisterCallback(self, "EventAdded", "OnEventAdded")
    uOO.Calendar.RegisterCallback(self, "EventRemoved", "OnEventRemoved")
    uOO.Calendar.RegisterCallback(self, "InviteInfo", "OnInviteInfo")

    -- Add an empty item
    self:AddEvent("")

    -- Now add events that are already discovered by the calendar
    for _, eventName in uOO.Calendar:GetEventIterator() do
        self:AddEvent(eventName)
    end
end

local function clear_player_signups(self)
    clearingInfo = true
    local numItems = players:GetItemCount()
    for i = 1, numItems do
        local info = players:GetItem(i)
        local player = uOO.PlayerData:Get(info[1])
        if info[2] == const.SIGNED then
            player:RemoveSigned()
        else
            player:DataChanged()
        end
    end
    players:RemoveAllItems()
    clearingInfo = false
end


function EventListModel:SetSelectedItem(index)
    if index <= events:GetItemCount() then
        clear_player_signups(self)
        selected = index
        -- Tell calendar to select an event and feed us some data. The resulting
        -- callback will update our internal player list and add their signup
        -- status to players table
        uOO.Calendar:SelectEvent(events:GetItem(index))
        callbacks:Fire("SelectionChanged", index)
    end
end

function EventListModel:GetSelectedItem()
    return self:GetItem(selected)
end

function EventListModel:GetItem(index)
    local name = events:GetItem(index)
    return {GetName = function(self) return name end}
end

function EventListModel:GetItemCount()
    return events:GetItemCount()
end

function EventListModel:AddEvent(eventName)
    if events:AddItem(eventName) then
        if selected == -1 then
            self:SetSelectedItem(events:GetIndex(eventName))
        end
        callbacks:Fire("ListChanged")
    end
end

function EventListModel:RemoveEvent(eventName)
    -- TODO: Handle selected event being removed
    if events:RemoveItem(eventName) then
        callbacks:Fire("ListChanged")
    end
end

function EventListModel:OnEventAdded(_, eventName)
    self:AddEvent(eventName)
end

function EventListModel:OnEventRemoved(_, eventName)
    self:RemoveEvent(eventName)
end

local inviteStatusMap = {
    [2] = const.SIGNED,
    [4] = const.SIGNED,
    [7] = const.SIGNED,
    [3] = const.UNSIGNED,
    [6] = const.UNSURE,
    [9] = const.UNSURE,
}

function EventListModel:OnInviteInfo(_, playerName, inviteStatus)
    if inviteStatusMap[inviteStatus] then
        inviteStatus = inviteStatusMap[inviteStatus]
        local player = uOO.PlayerData:Get(playerName)
        players:AddItem({playerName, inviteStatus})
        if inviteStatus == const.SIGNED then
            player:AddSigned()
        else
            -- Tell the world something about the player changed
            player:DataChanged()
        end
    end
end

function EventListModel:GetSignupStatus(player)
    -- Events get raised during info cleanup. Just report unknown for them.
    -- A new selection will raise more events to give them the correct status.
    if clearingInfo then
        return const.UNKNOWN
    end
    local info = players:GetItem({player:GetName(), const.UNKNOWN})
    return info and info[2] or const.UNKNOWN
end

EventListModel:lock()

uOO.EventListModel = EventListModel
