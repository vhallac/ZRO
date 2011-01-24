local addonName, addonTable = ...

local ZRO   = addonTable.ZRO
local uOO   = addonTable.uOO
local const = addonTable.const

local Calendar = uOO.object:clone()
local events = {}
local callbacks = LibStub("CallbackHandler-1.0"):New(Calendar)

-- The code below is going to be tricky. As usual, events are involved in
-- collecting the information we are after. To simplify the code, I will use
-- coroutines to create the illusion of continuity.
do
    local coCalendarQuery
    -- functions I will define later
    local queryCalendar, onOpenEvent

    -- Warning: only call after PLAYER_LOGIN event is fired
    function Calendar:LoadEvents()
        coCalendarQuery = coroutine.create(queryCalendar)
        if coCalendarQuery then
            local status, err = coroutine.resume(coCalendarQuery, self)
            if not status then
                ZRO:Print("Cannot query calendar - " .. (err or "no info"))
            end
        else
            ZRO_Print("Cannot query calendar")
        end
    end

    queryCalendar = function(self)
        -- TODO: Start with open calendar... It didn't work for me once. May need
        -- experimentation.
        ZRO:RegisterEvent("CALENDAR_OPEN_EVENT", onOpenEvent, self)

        local dow, mon, day, year = self:GetDate()
        -- Get number of events for today
        local numEvents = CalendarGetNumDayEvents(0, day)
        for i=1,numEvents do

            local title, hour, minute, calendarType, sequenceType, eventType, texture, modStatus, inviteStatus, invitedBy, difficulty, inviteType = CalendarGetDayEvent(0, day, i)
            if ( calendarType == "PLAYER" or
                 calendarType == "GUILD_EVENT" )
            then
                -- These are the types of events people can sign up to. Get invite
                -- information, and create an entry for it.
                CalendarOpenEvent(0, day, i)
                -- The resume will come either from a timeout, or from a response
                -- from CALENDAR_OPEN_EVENT

                members = coroutine.yield()
                if members then
                    -- If we got something meaningful, create invite status
                    -- field for the events.
                    events[title] = members
                end
            end

        end

        ZRO:UnregisterEvent("CALENDAR_OPEN_EVENT")

        -- Let the interested parties know that we are done.
        callbacks:Fire("CalendarLoaded")
    end

    local inviteStatusMap = {
        [2] = const.SIGNED,
        [4] = const.SIGNED,
        [7] = const.SIGNED,
        [3] = const.UNSIGNED,
        [6] = const.UNSURE,
        [9] = const.UNSURE,
    }
    onOpenEvent = function(self)
        local numInvites = CalendarGetNumInvites()
        local inviteTbl = {}
        for i=1, numInvites do
            local name, level, className, classFileName, inviteStatus, modStatus, inviteIsMine, inviteType = CalendarEventGetInvite(index)
            if inviteStatusMap[inviteStatus] then
                -- This is an entry we are interested in
                inviteTbl[name] = inviteStatusMap[inviteStatus]
            end
        end
        coroutine.resume(coCalendarQuery, inviteTbl)
    end
end

function Calendar:GetDate()
    local dow, mon, day, year = CalendarGetDate()
    local hour, min = GetGameTime()

    -- TODO: Should this be configurable?
    if hour < 12 then
        -- Everything up to noon is considered yesterday. Some raids go for too
        -- long. :)
        -- I will cheat and let the time() and date() fnctions do the heavy lifting.
        local dt = date("*t", time({year=year, month=mon, day=day-1}))
        dow, mon, day, year = dt.wday, dt.month, dt.day, dt.year
    end
    return dow, mon, day, year
end

function Calendar:GetDateString()
    local _, mon, day, year = self:GetDate()
    return string.format("%02d/%02d/%04d", mon, day, year)
end

uOO.Calendar = Calendar
