local L = LibStub("AceLocale-3.0"):GetLocale("ZRO", true)

local addonName, addonTable = ...
local uOO = addonTable.uOO

local ButtonFactory = uOO.object:clone()
local Button = uOO.object:clone()

function ButtonFactory:Initialize(scrollframe)
    self.scroller = scrollframe
    self.namePrefix = self.scroller:GetName().."Button"
    self.uiParent = self.scroller:GetParent()
    self.templateName = "ZROPlayerTemplate"
end

function ButtonFactory:Get(index)
    local button = getglobal(self.namePrefix..index)
    if not button then
        -- Create a new button. Assume button (i-1) was already created
        button = CreateFrame("Button", self.namePrefix..index, nil, self.templateName)
        button:SetParent(self.uiParent)
        button.index = index
        button:ClearAllPoints()
        -- This will get changed by the mediator if necessary
        button:SetPoint("TOPLEFT", self.scroller, "TOPLEFT")
    end

    if not button.mediator then
        -- This is a fresh button. Create its mediator, too
        local mediator = Button:clone()
        mediator:Initialize(self, button, index)
    end

    return button.mediator
end

uOO.PlayerButtonFactory = ButtonFactory

function Button:Initialize(factory, uiButton, index)
    self.uiButton = uiButton
    uiButton.mediator = self

    uiButton:SetNormalTexture("");
    uiButton:SetText("");
    if uiButton.index > 1 then
        local prevButton = factory:Get(uiButton.index-1).uiButton
        uiButton:SetPoint("TOPLEFT", prevButton, "BOTTOMLEFT")
    end
end

function Button:SetPlayer(player)
    self.player = player
end

function Button:Update()
    if self.player then
        local namePrefix = self.uiButton:GetName()
        local name = _G[namePrefix.."Name"]
        name:SetText(self.player:GetName())
        self.uiButton:Show()
    else
        self.uiButton:Hide()
    end
end

-- This looks and feels like a kludge, but I couldn't find a good place to
-- obtain this information.
function Button:GetItemHeight()
    return self.uiButton:GetHeight()
end
