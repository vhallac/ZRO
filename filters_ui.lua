local L = LibStub("AceLocale-3.0"):GetLocale("ZRO", true)

local addonName, addonTable = ...
local uOO = addonTable.uOO

local FilterSettingsMediator = uOO.object:clone()
local filterButtons = {}
local model

function FilterSettingsMediator:Initialize(new_model)
    model = new_model

    -- Bind toggle values to the model
    -- I could have isolated this away a bit more, but that would be a somewhat
    -- pointless excercise.
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

function FilterSettingsMediator:ModelChanged()
    for _, btn in ipairs(filterButtons) do
        btn:SetChecked(model["Get"..btn.SettingName](model))
    end
end

FilterSettingsMediator:lock()

uOO.FilterSettingsMediator = FilterSettingsMediator
