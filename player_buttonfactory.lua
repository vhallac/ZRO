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

function ButtonFactory:SetInviteClickHandler(handler)
    self.OnInviteClick = handler
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

    local inviteBtn = _G[button:GetName().."Invite"]
    inviteBtn:SetScript("OnClick",
                        function()
                            self.OnInviteClick(button.mediator.player)
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

local function update_label(self)
    local name = _G[self.namePrefix.."Name"]
    name:SetText(self.player:GetName())
    name:SetTextColor(self.player:GetClassColor())
end

function Button:Update()
    if self.player then
        update_label(self)
        self.uiButton:Show()
    else
        self.uiButton:Hide()
    end
end

setLabel = function (button)
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

