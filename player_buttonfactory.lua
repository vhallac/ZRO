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

function ButtonFactory:SetActionHandler(handler)
    self.OnActionClick = handler
end

function ButtonFactory:SetActionButtonText(text)
    self.ActionButtonText = text
    -- Now change all the action button labels for existing buttons
    local index = 1
    repeat
        local button = _G[self.namePrefix..index]
        if button then
            local actionBtn = _G[button:GetName().."Action"]
            actionBtn:SetText(self.ActionButtonText)
        end
        index = index + 1
    until not button
end

function ButtonFactory:Get(index)
    local button = _G[self.namePrefix..index]
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

    button:SetScript("OnEnter",
                     function()
                         button.mediator:ShowTooltip()
                     end)
    button:SetScript("OnLeave",
                     function()
                         button.mediator:HideTooltip()
                     end)

    local actionBtn = _G[button:GetName().."Action"]
    actionBtn:SetText(self.ActionButtonText)
    actionBtn:SetScript("OnClick",
                        function()
                            self.OnActionClick(button.mediator.player)
                        end)

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

    -- Stop calling this all over the place
    self.namePrefix = self.uiButton:GetName()
end

function Button:SetModel(model)
    self.player = model
end

local function update_labels(self)
    local name = _G[self.namePrefix.."Name"]
    name:SetText(self.player:GetName())
    name:SetTextColor(self.player:GetClassColor())

    local raidIdLabel = _G[self.namePrefix.."RaidId"]
    local raidId = self.player:GetAssignedRaid()
    raidIdLabel:SetText(raidId and tostring(raidId) or "")

    local roleLabel = _G[self.namePrefix.."Role"]
    roleLabel:SetText(self.player:GetActiveRole() or "")
end

local function update_background(self)
    local bg = _G[self.namePrefix.."Color"]
    local player = self.player
    local div

    if self.player:IsOnline() then
        div = 1
    else
        div = 2
    end

    if player:GetAssignedRaid() then
        bg:SetTexture(0.1/div, 0.3/div, 0.1/div)
    elseif player:GetLastSitoutDate() == uOO.Calendar:GetDateString() then
        bg:SetTexture(0.1/div, 0.3/div, 0.6/div)
    elseif player:GetLastPenaltyDate() == uOO.Calendar:GetDateString() then
        bg:SetTexture(0.6/div, 0.1/div, 0.1/div)
    else
        bg:SetTexture(0.1/div, 0.1/div, 0.1/div)
    end
end

function Button:Update()
    if self.player then
        update_labels(self)
        update_background(self)
        self.uiButton:Show()
    else
        self.uiButton:Hide()
    end
end

function Button:ShowTooltip()
    if self.player then
        GameTooltip:SetOwner(self.uiButton, "ANCHOR_RIGHT")

        GameTooltip:AddDoubleLine(self.player:GetName(),
                                  self.player:GetClass(),
                                  NORMAL_FONT_COLOR.r,
                                  NORMAL_FONT_COLOR.g,
                                  NORMAL_FONT_COLOR.b,
                                  HIGHLIGHT_FONT_COLOR.r,
                                  HIGHLIGHT_FONT_COLOR.g,
                                  HIGHLIGHT_FONT_COLOR.b)

        GameTooltip:AddLine(self.player:GetTooltipText(), 1, 1, 1, 1)
        GameTooltip:Show()
    end
end

function Button:HideTooltip()
    GameTooltip:Hide()
end

-- This looks and feels like a kludge, but I couldn't find a good place to
-- obtain this information.
function Button:GetItemHeight()
    return self.uiButton:GetHeight()
end

