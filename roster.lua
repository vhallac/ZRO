local addonName, addonTable = ...
local ZRO = addonTable.ZRO
local uOO = addonTable.uOO

local Roster = uOO:NewClass("Roster",
                            {
                            })

-- This is a class method
function Roster:Initialize()
    if not self.callbacks then
        self.callbacks = LibStub("CallbackHandler-1.0"):New(self)
    end
    if not self.unitIds then self.unitIds = {} end

    ZRO:RegisterEvent("RAID_ROSTER_UPDATE", self.MembersChanged, self)
    ZRO:RegisterEvent("PARTY_MEMBERS_CHANGED", self.MembersChanged, self)

    -- Assume there was a change, and record the current status
    self:MembersChanged()
end

-- This is a class method
function Roster:Finalize()
    ZRO:UnregisterEvent("PARTY_MEMBERS_CHANGED")
    ZRO:UnregisterEvent("RAID_ROSTER_UPDATE")
end

function Roster:Construct()
end

function Roster:IsPlayerInRaid(player)
   if self.unitIds[player] then return true
   else return false
   end
end

function Roster:GetIterator()
    return pairs(self.unitIds)
end

-- This is a class method (see how it is registered)
function Roster:MembersChanged()
    ZRO:Debug("Roster:MembersChanged()")

    local updated = false

    -- Get rid of people who left the raid, or changed unit ids
    for name, unit in pairs(self.unitIds) do
        if GetUnitName(unit) ~= name
        then
            self.unitIds[name] = nil
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
                if self.unitIds[name] ~= unit then
                    self.unitIds[name] = unit
                    updated = true
                end
            end
        end
    end

    if updated then
        -- TODO: So many things wrong with this design. Create a per-instance
        -- callback handler, and some sort of event handler that isolates the
        -- ZebRaid logic from the details.
        self.callbacks:Fire("ZebRaid_RosterUpdated")
    end

    ZRO:Debug("Roster:MembersChanged():END")
end
