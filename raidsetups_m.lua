--[[
This is a busy model. It keeps track of various lists, and implements interfaces
necessary for three mediators:
    - The Raid selection combo box
    - The Selected raid player list
    - Action for adding players to the active list
TODO: Not quite sure this is a model according to the standard definition. Maybe
a rename?
--]]
local L = LibStub("AceLocale-3.0"):GetLocale("ZRO", true)

local addonName, addonTable = ...
local uOO = addonTable.uOO

local RaidSetupsModel = uOO.object:clone()

local callbacks = LibStub("CallbackHandler-1.0"):New(RaidSetupsModel)
local lists = {}
local selected = 1

function RaidSetupsModel:Initialize()
    self:AddItem(uOO.SitoutListModel)
    self:AddItem(uOO.PenaltyListModel)
    self:SetSelectedItem(1)
    self.numRaids = 0
    -- TODO: Go throught the player list and add necessary raid list items

    -- TODO2: Have the raids in the main list, and handle sitout and penalty as
    -- special cases. Easier than trying to insert at the right location. For
    -- now, we'll keep those two lists at start.
end

function RaidSetupsModel:SetSelectedItem(index)
    if index <= self:GetItemCount() then
        selected = index
        callbacks:Fire("SelectionChanged", index)
        self:GetProxyForSelected():Fire("ListChanged")
    end
end

function RaidSetupsModel:GetSelectedItem()
    return self:GetItem(selected)
end

function RaidSetupsModel:GetItem(index)
    return index <= self:GetItemCount() and lists[index]
end

function RaidSetupsModel:GetItemCount()
    return #lists
end

function RaidSetupsModel:AddRaidList()
    local raidIndex = self.numRaids + 1
    local raidListModel = uOO.RaidListModel:clone()
    raidListModel:Initialize(raidIndex)
    self:AddItem(raidListModel)
    self.numRaids = raidIndex
end

function RaidSetupsModel:AddItem(item)
    local function fire_if_selected(item, event, ...)
        if self:GetSelectedItem() == item then
            self.active:Fire(event, ...)
        end
    end

    table.insert(lists, item)
    -- Add proxy event handlers
    item.RegisterCallback(self, "ItemChanged", fire_if_selected, item)
    item.RegisterCallback(self, "ListChanged", fire_if_selected, item)

    callbacks:Fire("ListChanged")
end

function RaidSetupsModel:GetProxyForSelected()
    return self.active
end

-- This is an object that represents the active list. It implements the
-- interface necessary for scroll frame mediators.
RaidSetupsModel.active = uOO.object:clone()
local activeList = RaidSetupsModel.active

activeList.owner = RaidSetupsModel
activeList.callbacks = LibStub("CallbackHandler-1.0"):New(activeList)

function activeList:GetItemCount()
    local active = self.owner:GetSelectedItem()
    return active and active:GetItemCount()
end

function activeList:GetItem(index)
    local active = self.owner:GetSelectedItem()
    return active and active:GetItem(index)
end

-- This is an interface for PlayerButton functionality
function activeList:AddOrRemoveItem(item)
    local active = self.owner:GetSelectedItem()
    if active:HaveItem(item) then
        active:RemoveItem(item)
    else
        active:AddItem(item)
    end
end

function activeList:Fire(event, ...)
    self.callbacks:Fire(event, ...)
end

activeList:lock()
RaidSetupsModel:lock()

uOO.RaidSetupsModel = RaidSetupsModel
