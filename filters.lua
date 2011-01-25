local L = LibStub("AceLocale-3.0"):GetLocale("ZRO", true)

local addonName, addonTable = ...
local uOO = addonTable.uOO

-- The model for filter settings on the Player List panel.
local FilterSettingsModel = uOO.object:clone()
local db = {}
local callbacks = LibStub("CallbackHandler-1.0"):New(FilterSettingsModel)

function FilterSettingsModel:SetDataStore(new_db)
    if new_db then db = new_db end
end

-- Setup Accessors
do
    local function set_value(name, value, noCall)
        db[name] = value and true or false
        if not noCall then
            callbacks:Fire("ValueChanged")
        end
    end

    local accessors = {
        ShowTank = "tank",
        ShowHealer = "healer",
        ShowMelee = "melee",
        ShowRanged = "ranged",
        ShowNotSigned = "notsigned",
        ShowOtherRaid = "otherraid",
        ShowPenalty = "penalty"
    }

    for postfix, name in pairs(accessors) do
        FilterSettingsModel["Set"..postfix] = function(self, value, dontCall)
            set_value(name, value, dontCall)
        end
        FilterSettingsModel["Get"..postfix] = function(self) return db[name] end
    end
end

FilterSettingsModel:lock()

-- The mediator for filter settings on the Player List panel. The mediator
-- synchronizes the UI elements with the model.
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

-- Register the objects
uOO.FilterSettingsMediator = FilterSettingsMediator
uOO.FilterSettingsModel = FilterSettingsModel
