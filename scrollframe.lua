--[[
A generic scrollbar controller to do the gruntwork.
--]]

local L = LibStub("AceLocale-3.0"):GetLocale("ZRO", true)

local addonName, addonTable = ...
local uOO = addonTable.uOO

local ScrollFrame = uOO.object:clone()

-- local functions (to be defined below)
local handle_vertical_scroll
local get_item_button

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
function ScrollFrame:Initialize(scrollframe, buttonTemplateName, model)
    self.scroller = scrollframe
    scrollframe.controller = self
    self.btnName = scrollframe:GetName().."Button"
    self.btnTemplateName = buttonTemplateName
    self.DisplayItem = itemDisplayHandler
    self.bthHeight = buttonHeight
    -- Create the first button to obtain the height.
    local button = get_item_button(self, 1)
    self.btnHeight = button:GetHeight()
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
end


function ScrollFrame:GetFirstItemIndex()
    return FauxScrollFrame_GetOffset(self.scroller) or 0
end

function ScrollFrame:GetDisplayedItemCount()
    return math.floor(self.scroller:GetHeight() / self.btnHeight)
end

-- TODO: Handle player changed events. Need the model in here instead of
-- callbacks? refactor the button handling into a button model/controller?
function ScrollFrame:OnItemChanged(itemIdx)
    local firstItem = self:GetFirstItemIndex()
    if ( itemIdx >= firstItem and
         itemIdx < self:GetDisplayedItemCount() )
    then
        -- Re-display the item
        local itemButton = get_item_button(self, itemIdx - firstItem + 1)
        self.model:DisplayItem(itemButton, itemIdx)
    end
end

function ScrollFrame:SetItemCount(itemCount)
    self.itemCount = itemCount
end

handle_vertical_scroll = function (self, frame)
    -- Calculate it here to easily allow resizing.
    local buttonCount = self:GetDisplayedItemCount()

    -- If frames were resizable, we'd have to hide buttons not visible here.
    -- Since it is not the case, we don't need that.

    FauxScrollFrame_Update(frame, self.itemCount, buttonCount, self.btnHeight)

    local topIdx = self:GetFirstItemIndex()

    for i=1, buttonCount do
        local itemIdx = topIdx + i
        local itemButton = get_item_button(self, i)
        print("Item button:", i, itemButton:GetName(), itemButton)
        self.model:DisplayItem(itemButton, itemIdx)
    end
end

get_item_button = function (self, i)
    local button = getglobal(self.btnName..i)
    if not button then
        -- Create a new button. Assume button (i-1) was already created
        button = CreateFrame("Button", self.btnName..i,
                             self.scroller:GetParent(),
                             self.btnTemplateName)
        button:SetParent(self.scroller:GetParent())
        button.idx = i
    end

    button:SetNormalTexture("");
    button:SetText("");
    button.scroller = self
    button:ClearAllPoints()
    if i > 1 then
        button:SetPoint("TOPLEFT", self.btnName..(i-1), "BOTTOMLEFT")
    else
        button:SetPoint("TOPLEFT", self.scroller, "TOPLEFT")
    end

    self.numButtons = math.max(i, self.numButtons or 0)

    return button
end

uOO.ScrollFrame = ScrollFrame
