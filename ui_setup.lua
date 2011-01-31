local L = LibStub("AceLocale-3.0"):GetLocale("ZRO", true)

local addonName, addonTable = ...
local uOO = addonTable.uOO

local UiSetup = uOO.object:clone()

function UiSetup:LocalizeControls()
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

local initialized = false
local playerListMediator
local raidSetupsMediator
local eventSelectorMediator

function UiSetup:Initialize()
    if not initialized then
        -- Bind the Player List scroll frame objects together
        local guildListModel = uOO.GuildListModel
        playerListMediator = uOO.ScrollFrame:clone()
        local buttonFactory1 = uOO.PlayerButtonFactory:clone()
        local scroller = _G["ZRODialogPlayerListScrollList"]
        playerListMediator:Initialize(scroller, buttonFactory1, guildListModel)

        -- Bind the Player List Filter Settings objects together
        local filtersModel = uOO.FilterSettingsModel
        local filtersMediator = uOO.FilterSettingsMediator
        filtersMediator:Initialize(filtersModel)

        local raidSetupsModel = uOO.RaidSetupsModel
        raidSetupsMediator = uOO.DropDown:clone()
        -- Raid selection combo
        local raidSetupsFrame = _G["ZRODialogRaidSetupRaidSelect"]
        self.FixupDropdown(raidSetupsFrame)
        raidSetupsMediator:Initialize(raidSetupsFrame, raidSetupsModel)

        -- Selected group player list
        raidListMediator = uOO.ScrollFrame:clone()
        local buttonFactory2 = uOO.PlayerButtonFactory:clone()
        local scroller = _G["ZRODialogRaidSetupScrollList"]
        local raidSetupsProxyModel = raidSetupsModel:GetProxyForSelected()
        raidListMediator:Initialize(scroller, buttonFactory2, raidSetupsProxyModel)

        local function AddToActive(player)
            if not raidSetupsProxyModel:HaveItem(player) then
                -- First, remove player from all possible assignments
                for i=1,raidSetupsModel:GetItemCount() do
                    raidSetupsModel:GetItem(i):RemoveItem(player)
                end

                -- Then add to the active list
                raidSetupsProxyModel:AddItem(player)
            end
        end
        local function RemoveFromActive(player)
            if raidSetupsProxyModel:HaveItem(player) then
                raidSetupsProxyModel:RemoveItem(player)
            end
        end

        buttonFactory1:SetActionButtonText("->")
        buttonFactory2:SetActionButtonText("<-")
        buttonFactory1:SetActionHandler(AddToActive)
        buttonFactory2:SetActionHandler(RemoveFromActive)

        -- Handler for the NewRaid button.
        -- No, I will not breat a mediator/model for buttons... yet
        local newRaidButton = _G["ZRODialogRaidSetupNewRaid"]
        newRaidButton:SetScript("OnClick",
                                function()
                                    raidSetupsModel:AddRaidList()
                                end)

        eventSelectorMediator = uOO.DropDown:clone()
        local eventSelectorFrame = _G["ZRODialogEventSelect"]
        self.FixupDropdown(eventSelectorFrame)

        eventSelectorMediator:Initialize(eventSelectorFrame, uOO.EventListModel)
    end
end

-- Fixup some of the DropdownMenu weirdness
function UiSetup.FixupDropdown(frame)
    UIDropDownMenu_SetWidth(frame, frame:GetWidth()-20, 1)

    local label = _G[frame:GetName().."Text"]
    label:SetJustifyH("LEFT")
    label:SetPoint("LEFT", 30, 2)
end

UiSetup:lock()

uOO.UiSetup = UiSetup
