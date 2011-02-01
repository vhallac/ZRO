local L = LibStub("AceLocale-3.0"):GetLocale("ZRO", true)

local addonName, addonTable = ...
local uOO = addonTable.uOO
local const = addonTable.const

ClassInfo = uOO.object:clone()

-- This will keep all relevant data for the class/spec. See the end of file for
-- definition.
local ClassInfoData

local function kpairs(tbl)
    local func = pairs(tbl)
    local last
    local dummy_index = 0
    return function()
        last = func(tbl, last)
        dummy_index = dummy_index + 1
        return last and dummy_index, last
           end
end

function ClassInfo:GetSpecsIterator(class)
    if ClassInfoData[class] then
        return kpairs(ClassInfoData[class])
    else
        return function() return end
    end
end

function ClassInfo:GetRoleFromSpec(class, spec)
    return ( spec=="PvP" and const.PVP or
             ( ClassInfoData[class] and
               ClassInfoData[class][spec] and
               ClassInfoData[class][spec].role or const.UNKNOWN) )
end

ClassInfo:lock()

uOO.ClassInfo = ClassInfo

ClassInfoData = {
    ["Warrior"] = {
        ["Arms"] = {
            role = const.MELEE
        },
        ["Fury"] = {
            role = const.MELEE
        },
        ["Protection"] = {
            role = const.TANK
        }
    },
    ["Rogue"] = {
        ["Assasination"] = {
            role = const.MELEE
        },
        ["Combat"] = {
            role = const.MELEE
        },
        ["Subtlety"] = {
            role = const.MELEE
        },
    },
    ["Hunter"] = {
        ["Beast Mastery"] = {
            role = const.RANGED
        },
        ["Marksmanship"] = {
            role = const.RANGED
        },
        ["Survival"] = {
            role = const.RANGED
        }
    },
    ["Shaman"] = {
        ["Elemental"] = {
            role = const.RANGED
        },
        ["Enhancement"] = {
            role = const.MELEE
        },
        ["Restoration"] = {
            role = const.HEALER
        }
    },
    ["Priest"] = {
        ["Discipline"] = {
            role = const.HEALER
        },
        ["Holy"] = {
            role = const.HEALER
        },
        ["Shadow"] = {
            role = const.RANGED
        }
    },
    ["Warlock"] = {
        ["Affliction"] = {
            role = const.RANGED
        },
        ["Demonology"] = {
            role = const.RANGED
        },
        ["Destruction"] = {
            role = const.RANGED
        }
    },
    ["Mage"] = {
        ["Arcane"] = {
            role = const.RANGED
        },
        ["Fire"] = {
            role = const.RANGED
        },
        ["Frost"] = {
            role = const.RANGED
        }
    },
    ["Death Knight"] = {
        ["Blood"] = {
            role = const.TANK
        },
        ["Frost"] = {
            role = const.MELEE
        },
        ["Unholy"] = {
            role = const.MELEE
        }
    },
    ["Druid"] = {
        ["Balance"] = {
            role = const.RANGED
        },
        ["Feral DPS"] = {
            role = const.MELEE
        },
        ["Feral Tank"] = {
            role = const.TANK
        },
        ["Restoration"] = {
            role = const.HEALER
        }
    },
    ["Paladin"] = {
        ["Holy"] = {
            role = const.HEALER
        },
        ["Protection"] = {
            role = const.TANK
        },
        ["Retribution"] = {
            role = const.MELEE
        }
    }
}
