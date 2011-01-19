local L = LibStub("AceLocale-3.0"):GetLocale("ZRO", true)

local addonName, addonTable = ...
local ZRO = addonTable.ZRO
local uOO = addonTable.uOO
local const = addonTable.const

local obj = uOO:NewClass("PlayerData",
                         {
                             player_cache={},
                             db={}
                         })

function obj:Construct()
    if not self.class.state then
        -- stop the infinite loop
        self.class.state = true
        self.class.state = uOO:Construct("State")
    end

    if not self.class.roster then
        self.class.roster = uOO:Construct("Roster")
    end
end

-- Set the backing store for the class. If this is not called very early, some
-- of the data we store will get lost. If it is not called at all, the data will
-- not persist.
function obj:SetDataStore(db)
    self.db = data
end

function obj:Get(name)
    if not self.data[name] then
        self.data[name] = {}
    end

    -- These player objects are generating a lot of garbage. Since they don't
    -- have per-insance state, it is much better to have a single instance per
    -- player.
    if not self.player_cache[name] then
        self.player_cache[name] = self:NewPlayer(self, name, self.data[name])
    end
    return self.player_cache[name]
end

function obj:NewPlayer(playerdata, name, record)
    return uOO:Construct("Player", playerdata, name, record)
end


-- Get an iterator for known players in assigned list.
-- filterfunc is called with name
-- sortfunc is called with the names of the players tro be compared
function obj:GetIterator(filterfunc, sortfunc)
    local tmp = {}
    local res = {}
    -- Pick up players from online people, registered users, and players assigned
    -- to roles.

    for name in Guild:GetIterator("NAME", false) do
        tmp[name] = true
    end

    for name in self.state:RegistrationIterator() do
        tmp[name] = true
    end

    for name in self.state:AssignmentsIterator() do
        tmp[name] = true
    end

    for name in pairs(tmp) do
        tmp[name] = nil
        local player = self:Get(name)
        if not filterfunc or filterfunc(player) then
            table.insert(res, player)
        end
    end

    if sortfunc then
        table.sort(res, sortfunc)
    end

    local i = 0
    local n = #res
    local iterfunc = function ()
        if i < n then
            i = i + 1
            return i, res[i]
        end
    end

    return iterfunc, res, nil
end

-- Class that represents a player. It has a PlayerData backend for persistent
-- state management.
Player = uOO:NewClass("Player", {})

function Player:Construct(playerdata, name, record)
    self.playerData = playerdata
    self.name = name
    self.record = record
end

function Player:GetName()
    return self.name
end

-- These two helper functions make sure changes are replicated for both entries

local function set_role(record_name, role)
    local role = string.lower(role or "unknown")
    -- Update the player role with the new one unless the role is
    -- unknown. If the player role is not recorded yet, just stick
    -- anything we have (including unknown) to it.
    self.record[record_name] = role
end

local function get_role(record_name)
    return string.lower(self.record[record_name] or "unknown")
end

function Player:SetPrimaryRole(role)
    set_role("primary_role", role)
end

function Player:GetPrimaryRole()
    return get_role("primary_role")
end

function Player:SetSecondaryRole(role)
    set_role("secondary_role", role)
end

function Player:GetSecondaryRole()
    return get_role("secondary_role")
end

-- Select the active role:
--   1 - mainspec
--   2 - offspec
function Player:SetSelectedRole(selected)
    self.record.selected_role = selected
end

function Player:GetSelectedRole()
    return self.record.selected_role or 1
end

function Player:GetActiveRole()
    local selected = self:GetSelectedRole()
    if selected == 1 then
        return self:GetPrimaryRole()
    else
        return self:GetSecondaryRole()
    end
end

-- This is a little bit fancy, but just code to reduce repetition and copy/paste
-- errors. Will revert back to copy/paste if the code diverges for different
-- date table types.
do
    local function get_date_count(player, table_name)
        return #player[table_name]
    end

    local function get_dates(player, table_name)
        if not player.record[table_name] then player.record[table_name] = {} end
        return player.record[table_name]
    end

    local function get_last_date(player, table_name)
        local dates = get_dates(player, table_name)
        return dates or "01/01/2010"
    end

    local function add_date(player, table_name)
        local cur_date = uOO:GetClass("Calendar"):GetDateString()
        local last_date = get_last_date(player, table_name)
        if cur_date ~= last_date then
            table.insert(get_dates(player, table_name), curDate)
        end
    end

    local function remove_date(player, table_name)
        local cur_date = uOO:GetClass("Calendar"):GetDateString()
        local last_date = get_last_date(player, table_name)
        if  cur_date == last_date then
            table.remove(get_dates(player, table_name))
        end
    end

    -- Types of date sets we'll keep
    local datesets = {
        "Sitout", "Penalty", "Signed"
    }

    -- Functions for each date type
    local func_map = {
        ["Get%sCount"] = get_date_count,
        ["Get%sDates"] = get_dates,
        ["GetLast%sDate"] = get_last_date,
        ["Add%s"] = add_date,
        ["Remove%s"] = remove_date
    }

    for i, name in ipairs(datesets) do
        for func_name, func in pairs(func_map) do
            local real_name = string.format(func_name, name)
            local table_name = string.lower(name).."Dates"
            Player[real_name] = function(self)
                return func(self, table_name)
            end
        end
    end
end

function Player:GetGuildRank()
    return self:IsInGuild() and Guild:GetRank(self.name) or "N/A"
end

function Player:GetGuildNote()
    return self:IsInGuild() and Guild:GetNote(self.name) or "N/A"
end

function Player:IsOnline()
    -- It is not easy to determine non-guildies online status.
    -- For now, report online for everyone not in guild.
    return not self:IsInGuild() or Guild:IsMemberOnline(self.name)
end

function Player:GetClass()
    return self:IsInGuild() and Guild:GetClass(self.name) or "unknown"
end

function Player:GetTooltipText()
    local text = "Rank: " .. (self:GetGuildRank() or "not in guild") .. "\n"
    if self:GetGuildNote() then
        text = text ..
            self:GetGuildNote() .. "\n\n"
    else
        text = text .. "\n"
    end

    if not self:IsOnline() then
        text = text ..
            "|cffff0000" .. L["PLAYER_OFFLINE"] .. "|r\n\n"
    end

    local status = self:GetSignupStatus(self.name)
    if status == const.UNSIGNED then
        text = text ..
            "|cffff0000" .. L["PLAYER_UNSIGNED"] .. "|r\n\n"
    end

    text = text ..
        "|c9f3fff00" .. L["SIGNSTATS"] .. "|r: " ..
        self:GetSignedCount() .. "/" ..
        self:GetSitoutCount() .. "/" ..
        self:GetPenaltyCount() .. "\n"

    local sitoutDates = self:GetSitoutDates()
    for _,v in ipairs(sitoutDates) do
        text = text ..
            "|c7f1fcf00" .. v .. "|r\n"
    end

    local penaltyDates = self:GetPenaltyDates()
    for _,v in ipairs(penaltyDates) do
        text = text ..
            "|cff1f1f00" .. v .. "|r\n"
    end
    return text
end

function Player:GetSignupStatus()
    return self.playerData.state:GetSignupStatus(self.name)
end

function Player:GetSignupNote()
    return self.playerData.state:GetSignupNote(self.name)
end

function Player:GetAssignment()
    return self.playerData.state:GetAssignment(self.name)
end

function Player:SetAssignment(assignment)
    return self.playerData.state:SetAssignment(self.name, assignment)
end

function Player:RemoveAssignment()
    return self.playerData.state:RemoveAssignment(self.name)
end

function Player:GetClassColor()
    return Guild:GetClassColor(self.name)
end

function Player:IsInGuild()
    return Guild:HasMember(self.name)
end

function Player:IsInRaid()
    -- TODO: Move roster functionality to playerdata
    return self.playerData.roster:IsPlayerInRaid(self.name)
end
