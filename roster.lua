local addonName, addonTable = ...
local ZRO = addonTable.ZRO
local uOO = addonTable.uOO

local Roster = uOO.object:clone()

-- Move these out of the class and into the local scope.
local initialized = false
local unitIds = {}
local callbacks = LibStub("CallbackHandler-1.0"):New(Roster)

function Roster:Initialize()
    if not initialized then
        ZRO:RegisterEvent("RAID_ROSTER_UPDATE", self.MembersChanged, self)
        ZRO:RegisterEvent("PARTY_MEMBERS_CHANGED", self.MembersChanged, self)

        -- Assume there was a change, and record the current status
        self:MembersChanged()
    end
end

-- This is a class method
function Roster:Finalize()
    ZRO:UnregisterEvent("PARTY_MEMBERS_CHANGED")
    ZRO:UnregisterEvent("RAID_ROSTER_UPDATE")
end

function Roster:IsPlayerInRaid(player)
    return unitIds[player] and true or false
end

function Roster:GetIterator()
    return pairs(unitIds)
end

-- This is a class method (see how it is registered)
function Roster:MembersChanged()
    local updated = false

    -- Get rid of people who left the raid, or changed unit ids
    for name, unit in pairs(unitIds) do
        if GetUnitName(unit) ~= name
        then
            unitIds[name] = nil
            updated = true
        end
    end

    -- Scan either the party, or the raid
    local formatString, getCountFunc
    if UnitInRaid("player") then
        formatString = "raid%d"
        getCountFunc = GetNumRaidMembers
    elseif UnitInParty("player") and GetNumPartyMembers() > 0 then
        formatString = "party%d"
        getCountFunc = GetNumPartyMembers
    end

    if getCountFunc then
        local n = getCountFunc()
        for i=1,n do
            local unit=string.format(formatString, i)
            local name=GetUnitName(unit)
            if unit and name then
                if unitIds[name] ~= unit then
                    unitIds[name] = unit
                    updated = true
                end
            end
        end
    end

    if updated then
        callbacks:Fire("RosterUpdated")
    end
end

-- Don't allow cloning this.
Roster:lock()

uOO.Roster = Roster
