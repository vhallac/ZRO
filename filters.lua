local L = LibStub("AceLocale-3.0"):GetLocale("ZRO", true)

local addonName, addonTable = ...
local uOO = addonTable.uOO

local obj = uOO:NewClass("FilterSettings",
                         {
                             db = {}
                         })

function obj:Construct()
    if not self.class.callbacks then
        self.class.callbacks = LibStub("CallbackHandler-1.0"):New(self.class)
    end
end

function obj:SetDataStore(db)
    if db then
        self.db = db
    end
end

-- Setup Accessors
do
    local function set_value(self, name, value, noCall)
        self.db[name] = value and true or false
        if not noCall then
            self.callbacks:Fire("ValueChanged")
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
        obj["Set"..postfix] = function(self, value, dontCall)
            set_value(self, name, value, dontCall)
        end
        obj["Get"..postfix] = function(self) return self.db[name] end
    end
end
