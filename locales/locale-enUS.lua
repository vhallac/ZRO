local L = LibStub("AceLocale-3.0"):NewLocale("ZRO", "enUS", true)
if not L then return end

local addonName, addonTable = ...
local const = addonTable.const

L[const.UNKNOWN] = "*UNKNOWN*"
L["Start planning the raid"] = true
L["Player List"] = true
L["Tank"] = true
L["Healer"] = true
L["Melee"] = true
L["Ranged"] = true
L["Not Signed"] = true
L["Other Raid"] = true
L["Have Penalty"] = true
L["Raid Setup"] = true
L["Leave Raid"] = true
L["Invite"] = true
L["Sitouts"] = true
L["Penalties"] = true
L["Raid Group: "] = true
L["Offline"] = true
L["Unsigned"] = true
L["#Signups/Sitouts/Penalties"] = true
L["has come online"] = true
L["has gone offline"] = true
L["has joined the guild"] = true
L["has left the guild"] = true
