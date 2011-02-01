local L = LibStub("AceLocale-3.0"):GetLocale("ZRO", true)

local addonName, addonTable = ...
local uOO = addonTable.uOO
local const = addonTable.const
local lconst = {
    PRIMARY_MARKER = "primary",
    SECONDARY_MARKER = "secondary",
    TITLE_MARKER = "title"
}

local PlayerMenu = uOO.object:clone()

local menuFrame

function PlayerMenu:Initialize()
    if not menuFrame then
        menuFrame = CreateFrame("Frame", "PlayerMenuFrame", UIParent, "UIDropDownMenuTemplate")
    end
end

function PlayerMenu:SetPlayer(player)
    self.player = player
end

local menuData = {
    { text = L["Set player options"], mark = lconst.TITLE_MARKER, isTitle = true },
    { text = L["Primary Spec"], hasArrow = true,
      mark = lconst.PRIMARY_MARKER, menuList = {} },
    { text = L["Secondary Spec"], hasArrow = true,
      mark = lconst.SECONDARY_MARKER, menuList = {} },
}

local function get_entry(marker)
    for i, v in ipairs(menuData) do
        if v.mark == marker then
            return v
        end
    end
end

local function get_submenu(marker)
    for i, v in ipairs(menuData) do
        if v.mark == marker then
            table.wipe(v.menuList)
            return v.menuList
        end
    end
end

function add_specs(player, tbl, setterFunc)
    local function add_spec(tbl, spec)
        local entry = { text = L[spec],
                        func = function()
                            setterFunc(player, spec)
                            CloseDropDownMenus(1)
                            menuFrame:Hide()
                        end
        }
        table.insert(tbl, entry)
    end

    for i, spec in ClassInfo:GetSpecsIterator(player:GetClass()) do
        add_spec(tbl, spec)
    end
    add_spec(tbl, "PvP")
end

function PlayerMenu:Show()
    if not self.player then return end

    -- Construct the menu
    local title = get_entry(lconst.TITLE_MARKER)
    title.text = L["Set player options"].." ("..self.player:GetName()..")"

    local primary = get_submenu(lconst.PRIMARY_MARKER)
    add_specs(self.player, primary, self.player.SetPrimarySpec)

    local secondary = get_submenu(lconst.SECONDARY_MARKER)
    add_specs(self.player, secondary, self.player.SetSecondarySpec)

    -- Display the menu
    EasyMenu(menuData, menuFrame, "cursor", 0 , 0, "MENU");
end

PlayerMenu:lock()

uOO.PlayerMenu = PlayerMenu
