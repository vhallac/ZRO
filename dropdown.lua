--[[
A generic Dropdown menu mediator to synchronize a selectable model with a
UIDropDownMenuTemplate UI element.

The model must implement the following interface:
    - GetItem(i): Get the item at index i
    - GetSelectedItem(): Get the selected item
    - SetSelectedItem(i): Set the item at index i as the selected item
    - LibCallback-1.0 interface with events:
      - ListChanged: An item was added or removed
      - SelectionChanged: The selected item was changed
The items in the model list must implement the following interface:
    - GetName(): Return the item name as a string
--]]

local L = LibStub("AceLocale-3.0"):GetLocale("ZRO", true)

local addonName, addonTable = ...
local uOO = addonTable.uOO

local DropDown = uOO.object:clone()

-- Local function to add items to the dropdown menu list
local dropdown_config_items

function DropDown:Initialize(dropdownframe, model)
    self.dropdown = dropdownframe
    self.model = model
    self.dropdown.mediator = self

    self.model:RegisterCallback("ListChanged", self.UpdateList, self)
    self.model:RegisterCallback("SelectionChanged", self.SetSelected, self)
    -- Finally, initialize the list
    self:UpdateList()
    self:SetSelected()
end

function DropDown:UpdateList()
    UIDropDownMenu_Initialize(self.dropdown, dropdown_config_items)
end

function DropDown:SetSelected(event, index)
    local item = self.model:GetSelectedItem()
    if item then
        UIDropDownMenu_SetSelectedValue(self.dropdown, index)
        UIDropDownMenu_SetText(self.dropdown, item:GetName())
    end
end

local function item_onclick(frame, model, index)
    model:SetSelectedItem(index)
end

dropdown_config_items = function(frame, level, menulist)
    local self = frame.mediator
    if not self then return end

    for i=1, self.model:GetItemCount() do
        local info = UIDropDownMenu_CreateInfo()
        local item = self.model:GetItem(i)
        info.value = i
        info.text = item:GetName()
        info.arg1 = self.model
        info.arg2 = i
        info.func = item_onclick
        UIDropDownMenu_AddButton(info, level)
    end
end

uOO.DropDown = DropDown
