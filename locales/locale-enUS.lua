local L = LibStub("AceLocale-3.0"):NewLocale("ZRO", "enUS", true)
if not L then return end

local addonName, addonTable = ...
local const = addonTable.const

L[const.UNKNOWN] = "*UNKNOWN*"
L["Start planning the raid"] = true
