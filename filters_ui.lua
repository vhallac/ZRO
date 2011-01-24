local L = LibStub("AceLocale-3.0"):GetLocale("ZRO", true)

local addonName, addonTable = ...
local uOO = addonTable.uOO

local FilterSettingsUi = uOO.object:clone()
local filterButtons = {}
local model

function FilterSettingsUi:Initialize()
    if not model then
        model = uOO.FilterSettings
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

    local OnClick = function(FilterSettingsUi, btn, down)
        if btn == "LeftButton" then
            model["Set"..FilterSettingsUi.SettingName](model, FilterSettingsUi:GetChecked(), true)
        end
    end

    for btnName, settingName in pairs(buttons) do
        local btn = _G[checkButtonsPrefix..btnName]
        btn.SettingName = settingName
        btn:SetScript("OnClick", OnClick)
        table.insert(filterButtons, btn)
    end

    -- And register a listener, so that we can respond to changes
    model:RegisterCallback("ValueChanged", self.ModelChanged, self)
end

function FilterSettingsUi:ModelChanged()
    for _, btn in ipairs(filterButtons) do
        btn:SetChecked(model["Get"..btn.SettingName](model))
    end
end
