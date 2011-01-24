local addonName, addonTable = ...
local ZRO = addonTable.ZRO
local uOO = addonTable.uOO
local const = addonTable.const

local Guild = uOO.object:clone()
local initialized = false
local memberList = {}
local callbacks = callbacks = LibStub("CallbackHandler-1.0"):New(Guild)

function Guild:Initialize()
    if not initialized then
        ZRO:RegisterEvent("GUILD_ROSTER_UPDATE", self.GuildUpdate, self)
        ZRO:RegisterEvent("PLAYER_GUILD_UPDATE", self.PlayerUpdate, self)

        -- Schedule the first guild roster callback
        GuildRoster()

        initialized = true
    end
end

-- This is a class method
function Guild:Finalize()
    if initialized then
        initialized = false
        ZRO:UnregisterEvent("PLAYER_GUILD_UPDATE")
        ZRO:UnregisterEvent("GUILD_ROSTER_UPDATE")
        callbacks:UnregisterAllCallbacks()
    end
end

function Guild:GuildUpdate(event, arg1)
    if not arg1 then
        -- Update for GuildRoster(). Go through local cache, and fix things up.
        self:SyncMembers()
    else
        -- Local cache update. Do a GuildRoster() to pick up changes.
        GuildRoster()
    end
end

function Guild:PlayerUpdate(unit)
    if not unit or unit ~= "player" then return end

    if IsInGuild() then
        -- Joined a guild. Good for me!
        GuildRoster()
        callbacks:Fire("JoinedGuild")
    else
        -- Not in guild, clear the member list (except myself)
        self:ClearAll(false)
        callbacks:Fire("LeftGuild")
    end
end

function Guild:SyncMembers()
    if not IsInGuild() then
        -- Not in guild, clear the member list (except myself)
        self:ClearAll(false)
        return
    end

    local numPlayers = GetNumGuildMembers()
    local numOnline = 0
    for i = 1, numPlayers do
        local name, rank, rankIndex, level, class, zone, note, officernote, online, status, englishClass = GetGuildRosterInfo(i)

        if status == "" then status = nil end
		if note == "" then note = nil end
		if officernote == "" then officernote = nil end

        local player
        if name then
            if not memberList[name] then
                player = {}
                memberList[name] = player
                player.new = true -- Processed and cleared later
            else
                player = memberList[name]
            end

            player.name = name -- I know it is redundant, but speeds things up
                               -- in iterator filtering and sorting
            player.rank = rank
            player.rankIndex = rankIndex
            player.level = level
            player.class = class
            player.englishClass = englishClass
            player.note = note
            player.officernote = officernote
            player.oldOnline = player.online -- Will clear later
            player.online = online and true or false
            player.status = status -- <AFK>, <DND>, etc...
            player.updated = true
        end

        if online then
            numOnline = numOnline + 1
        end
    end

    -- Now, all my data is up to date. I can start sending events
    local deleteList = nil

    for name, player in pairs(self.memberList) do
        if player.oldOnline ~= player.online then
            callbacks:Fire(player.online and
                           "MemberConnected" or
                           "MemberDisconnected", name)
        end
        player.oldOnline = nil

        if not player.updated then
            callbacks:Fire("MemberRemoved", name)
             -- reduce garbage by creating table only when needed
            if not deleteList then deleteList = {} end
            table.insert(deleteList, name)
        end
        player.updated = nil

        if player.new then
            callbacks:Fire("MemberAdded", name)
            player.new = nil
        end
    end
end

function Guild:ClearAll(shouldClearSelf)
    for name, _ in pairs(self.memberList) do
        memberList[name] = nil
        callbacks:Fire("PlayerRemoved", name)
    end
end

-- Get an iterator for members.
-- both filterfunc and sortfunc are called with the member information
-- The member information is supposed to be passed back to accessor functions.
-- Caller can access the information directly, but the savings from function call
-- overhead is not worth the headache when information is changed.
--
-- Example:
-- for _, v in G:GetIterator(function(inf) return G:GetLevel(i) == 85 end) do
--    print(G:GetName(i))
-- end
function Guild:GetIterator(filterfunc, sortfunc)
    local tmp = {}
    local res = {}
    -- Pick up players from online people, registered users, and players assigned
    -- to roles.

    for name, player in pairs(self.memberList) do
        tmp[name] = nil
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

-- Create a list of accessor functions
do
    -- Return the member information structure.
    local function get_info(name)
        return memberList and memberList[name]
    end

    local function get_data(nameOrInfo, member, default)
        if type(nameOrInfo) == "string" then
            nameOrInfo = get_info(nameOrInfo)
        end
        return nameOrInfo and nameOrInfo[member] or default
    end

    local accessors = {
        {"GetName", "name", const.UNKNOWN},
        {"GetRank", "rank", const.UNKNOWN},
        {"GetRankIndex", "rankIndex", -1},
        {"GetLevel", "level", 1},
        {"GetClass", "class", const.UNKNOWN},
        {"GetEnglishClass", "englishClass", const.UNKNOWN},
        {"GetNote", "note", ""},
        {"GetOfficerNote", "officernote", ""},
        {"IsMemberOnline", "online", false},
        {"GetStatus", "status", ""}
    }

    for _, data in ipairs(accessors) do
        Guild[data[1]] = function(self, nameOrInfo)
            get_data(nameOrInfo, data[2], data[3])
        end
    end

    function Guild:HasMember(name)
        return get_info(name) and true or false
    end
end

function Guild:GetClassColor(name)
	local class = self:GetEnglishClass(name)
	if not class then return 0.8, 0.8, 0.8 end
	local c = RAID_CLASS_COLORS[class]
	return c.r, c.g, c.b
end

function Guild:GetClassHexColor(name)
	local r, g, b = GetClassColor(name)
	return ("%02X%02X%02X"):format(r*255, g*255, b*255)
end

-- TODO: Add monitors for chat message, and keep track of online/offline
-- information that way.
-- TODO2: If it is not accurate enough, do what others did: send a GuildRoster()
-- call every n seconds (15 or 60 are the ones I've seen). Don't forget to
-- disable this when guild page is opened (check if it still causes problems
-- first), or when player enters combat.

-- Don't allow cloning this
Guild:lock()

uOO.Guild = Guild
