local L = LibStub("AceLocale-3.0"):GetLocale("ZRO", true)

local addonName, addonTable = ...
local uOO = addonTable.uOO

local obj = uOO:NewClass("FilterSettingsUi",
                         {
                         })

function obj:Initialize()
    if not self.model then
        self.model = uOO:Construct("FilterSettings")
    end
    -- Bind toggle values to the model
    local checkButtonsPrefix = "ZRODialogPlayerListFilterSettings"
    local buttons = {
        Tank = "ShowTank",
        Healer = "ShowHealer",
        Melee = "ShowMelee",
        Ranged = "ShowRanged",
        NotSigned = "ShowNotSigned",
        OtherRaidNo = "ShowOtherRaid",
        HavePenalty = "ShowPenalty"
    }

    local OnClick = function(obj, btn, down)
        if btn == "LeftButton" then
            self.model["Set"..obj.SettingName](self.model, obj:GetChecked(), true)
        end
    end

    self.filterButtons = {}

    for btnName, settingName in pairs(buttons) do
        local btn = _G[checkButtonsPrefix..btnName]
        btn.SettingName = settingName
        btn:SetScript("OnClick", OnClick)
        table.insert(self.filterButtons, btn)
    end

    -- And register a listener, so that we can respond to changes
    self.model:RegisterCallback("ValueChanged", self.ModelChanged, self)

    initialized = true
end

function obj:Construct()
    if not self.initialized then
        self.class:Initialize()
    end
end

function obj:ModelChanged()
    for _, btn in ipairs(self.filterButtons) do
        btn:SetChecked(self.model["Get"..btn.SettingName](self.model))
    end
end
