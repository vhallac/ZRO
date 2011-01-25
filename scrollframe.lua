--[[
A generic scrollbar controller to do the gruntwork.
--]]

local L = LibStub("AceLocale-3.0"):GetLocale("ZRO", true)

local addonName, addonTable = ...
local uOO = addonTable.uOO

local ScrollFrame = uOO.object:clone()

-- local functions (to be defined below)
local handle_vertical_scroll

--[[
Parameters:
  scrollframe: The ScrollFrame object that this object will control
  buttonTemplateName: The name of the button template we will use to display
                      the item data
  displayItem: The function we call to display the item. The parameters that
               we will use to call this function are itemButton and
               itemIndex. itemButton is the button frame that will display
               the data, and itemIndex is the index of the item in the
               scroll list to display. itemIndex can be greater than the
               actual number of items handled by the scroller.
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
                              FauxScrollFrame_OnVerticalScroll(frame, offset,
                                                               self.btnHeight,
                                                               function(frame)
                                                                   handle_vertical_scroll(self, frame)
                                                               end)
                          end)
    self.model = model
    model:RegisterCallback("ListChanged",
                           function(self)
                               handle_vertical_scroll(self, scrollframe)
                           end,
                           self)
    model:RegisterCallback("PlayerDataChanged",
                           self.OnItemChanged,
                           self)
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

handle_vertical_scroll = function (self, frame)
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
        itemButton:SetPlayer(self.model:GetPlayer(itemIdx))
        itemButton:Update()
    end
end

uOO.ScrollFrame = ScrollFrame
