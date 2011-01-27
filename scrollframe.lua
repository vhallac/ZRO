--[[
A generic scrollbar mediator to synchronize a list model with a ScrollFrame
UI element.
--]]

local L = LibStub("AceLocale-3.0"):GetLocale("ZRO", true)

local addonName, addonTable = ...
local uOO = addonTable.uOO

local ScrollFrame = uOO.object:clone()

--[[
Parameters:
  scrollframe: The ScrollFrame object that this object will control
  buttonFactory: The name of the button factory we will use to create scroll
                 frame buttons that display data
  model: The model that contains the list displayed by the scroll frame. It
         provides two callbacks: ListChanged, ItemChanged; and has the following
         functions implemented: GetItemCount, GetItem.

  It is the responsibility of the caller of this function to ensure that
  buttonFactory matches the model.
--]]
function ScrollFrame:Initialize(scrollframe, buttonFactory, model)
    self.scroller = scrollframe
    scrollframe.controller = self
    self.buttons = buttonFactory
    self.buttons:Initialize(scrollframe)
    self.DisplayItem = itemDisplayHandler
    -- Create the first button to obtain the height.
    local button = self.buttons:Get(1)
    self.btnHeight = button:GetItemHeight()
    scrollframe:SetScript("OnVerticalScroll",
                          function (frame, offset)
                              FauxScrollFrame_OnVerticalScroll(
                                  frame, offset,
                                  self.btnHeight,
                                  function(frame)
                                      self:HandleVerticalScroll()
                                  end)
                          end)
    self.model = model
    model.RegisterCallback(self, "ListChanged", "HandleVerticalScroll")
    model.RegisterCallback(self, "ItemChanged", "OnItemChanged")
end


function ScrollFrame:GetFirstItemIndex()
    return FauxScrollFrame_GetOffset(self.scroller) or 0
end

function ScrollFrame:GetDisplayedItemCount()
    return math.floor(self.scroller:GetHeight() / self.btnHeight)
end

function ScrollFrame:OnItemChanged(event, itemIdx)
    local firstItem = self:GetFirstItemIndex()
    if ( itemIdx >= firstItem and
         itemIdx < self:GetDisplayedItemCount() )
    then
        -- Re-display the item
        local button = self.buttons:Get(itemIdx - firstItem + 1)
        button:Update()
    end
end

function ScrollFrame:HandleVerticalScroll()
    local frame = self.scroller

    -- Calculate it here to easily allow resizing.
    local buttonCount = self:GetDisplayedItemCount()

    -- If frames were resizable, we'd have to hide buttons not visible here.
    -- Since it is not the case, we don't need that.
    local itemCount = self.model:GetItemCount()
    FauxScrollFrame_Update(frame, itemCount, buttonCount, self.btnHeight)

    local topIdx = self:GetFirstItemIndex()

    for i=1, buttonCount do
        local itemIdx = topIdx + i
        local itemButton = self.buttons:Get(i)
        -- This can pass nil to button, which causes it to be hidden
        itemButton:SetModel(self.model:GetItem(itemIdx))
        itemButton:Update()
    end
end

uOO.ScrollFrame = ScrollFrame
