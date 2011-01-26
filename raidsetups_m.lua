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
    local sitoutList = { GetName = function(self) return "Sitout" end }
    self:AddItem(sitoutList)
    local penaltyList = { GetName = function(self) return "Penalty" end }
    self:AddItem(penaltyList)
    self:SetSelectedItem(1)
    -- TODO: Go throught the player list and add necessary raid list items
    -- TODO2: Have the raids in the main list, and handle sitout and penalty as
    -- special cases. Easier than trying to insert at the right location. For
    -- now, we'll keep those two lists at start.
end

function RaidSetupsModel:SetSelectedItem(index)
    if index <= self:GetItemCount() then
        selected = index
        callbacks:Fire("SelectionChanged", index)
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

function RaidSetupsModel:AddItem(item)
    table.insert(lists, item)
    callbacks:Fire("ListChanged")
end

RaidSetupsModel:lock()

uOO.RaidSetupsModel = RaidSetupsModel
