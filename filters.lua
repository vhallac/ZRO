local L = LibStub("AceLocale-3.0"):GetLocale("ZRO", true)

local addonName, addonTable = ...
local uOO = addonTable.uOO

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

uOO.FilterSettingsModel = FilterSettingsModel
