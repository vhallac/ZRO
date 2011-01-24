local L = LibStub("AceLocale-3.0"):GetLocale("ZRO", true)

local UiText = uOO.object:clone()

function UiText:LocalizeControls()
    local playerListPrefix = "ZRODialogPlayerList"
    _G[playerListPrefix.."Title"]:SetText(L["Player List"])
    local filterBoxPrefix = playerListPrefix.."FilterSettings"
    _G[filterBoxPrefix.."TankText"]:SetText(L["Tank"])
    _G[filterBoxPrefix.."HealerText"]:SetText(L["Healer"])
    _G[filterBoxPrefix.."MeleeText"]:SetText(L["Melee"])
    _G[filterBoxPrefix.."RangedText"]:SetText(L["Ranged"])
    _G[filterBoxPrefix.."NotSignedText"]:SetText(L["Not Signed"])
    _G[filterBoxPrefix.."OtherRaidNoText"]:SetText(L["Other Raid"])
    _G[filterBoxPrefix.."HavePenaltyText"]:SetText(L["Have Penalty"])

    local raidSetupPrefix = "ZRODialogRaidSetup"
    _G[raidSetupPrefix.."Title"]:SetText(L["Raid Setup"])
    _G[raidSetupPrefix.."LeaveRaid"]:SetText(L["Leave Raid"])
    _G[raidSetupPrefix.."Invite"]:SetText(L["Invite"])
    _G[raidSetupPrefix.."TankStatsLabel"]:SetText(L["Tank"]..":")
    _G[raidSetupPrefix.."HealerStatsLabel"]:SetText(L["Healer"]..":")
    _G[raidSetupPrefix.."MeleeStatsLabel"]:SetText(L["Melee"]..":")
    _G[raidSetupPrefix.."RangedStatsLabel"]:SetText(L["Ranged"]..":")
end

UiText:lock()

uOO.UiText = UiText
