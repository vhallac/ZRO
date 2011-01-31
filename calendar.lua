local addonName, addonTable = ...

local ZRO   = addonTable.ZRO
local uOO   = addonTable.uOO
local const = addonTable.const

local Calendar = uOO.object:clone()
local events = {}
local callbacks = LibStub("CallbackHandler-1.0"):New(Calendar)
local lconst = {
    NEW_EVENT = 1,
    OLD_EVENT = 2
}

function Calendar:Initialize()
    self.events = {}
    ZRO.RegisterEvent(self, "CALENDAR_UPDATE_ERROR", "OnUpdateError")
    ZRO.RegisterEvent(self, "CALENDAR_UPDATE_EVENT_LIST", "OnUpdateEventList")
    ZRO.RegisterEvent(self, "CALENDAR_UPDATE_GUILD_EVENTS", "OnUpdateGuildEvents")
    ZRO.RegisterEvent(self, "CALENDAR_OPEN_EVENT", "OnOpenEvent")
    -- TODO: Detect a deleted event...

    CalendarCloseEvent()
    local dow, mon, day, year = self:GetDate()
    CalendarSetAbsMonth(mon, year)
	OpenCalendar()

    self:OnUpdateEventList()
end

function Calendar:Finalize()
    ZRO.UnregisterEvent(self, "CALENDAR_OPEN_EVENT")
    ZRO.UnregisterEvent(self, "CALENDAR_UPDATE_EVENT_LIST")
end

function Calendar:OnUpdateError()
    ZRO:Print("Calendar:OnUpdateError")
end

function Calendar:OnUpdateGuildEvents()
    ZRO:Print("Calendar:OnUpdateGuildEvents")
end

function Calendar:OnUpdateEventList()
    local dow, mon, day, year = self:GetDate()

    -- Go through the event list, and check if the event is already recorded.
    -- If new events are found, or if old ones are deleted, fire a
    -- "EventListUpdate" event.
    local numEvents = CalendarGetNumDayEvents(0, day)
    for i=1,numEvents do
        local title, hour, minute, calendarType, sequenceType, eventType, texture, modStatus, inviteStatus, invitedBy, difficulty, inviteType = CalendarGetDayEvent(0, day, i)
        if ( calendarType == "PLAYER" or
             calendarType == "GUILD_EVENT" )
        then
            -- These are the types of events people can sign up to. Get invite
            -- information, and create an entry for it.
            if not self.events[title] then
                callbacks:Fire("EventAdded", title)
            end
            self.events[title] = lconst.NEW_EVENT
        end
    end

    for title, val in pairs(self.events) do
        if self.events[title] == lconst.OLD_EVENT then
            callbacks:Fire("EventRemoved", title)
            self.events[title] = nil
        end
        self.events[title] = lconst.OLD_EVENT
    end
end

function Calendar:GetEventIterator()
    local iter = pairs(self.events)
    local dummy_index = 1
    local last = nil
    return function()
        dummy_index = dummy_index + 1
        last = iter(self.events, last)
        return last and dummy_index-1, last
    end
end

function Calendar:SelectEvent(eventName)
    local dow, mon, day, year = self:GetDate()

    local numEvents = CalendarGetNumDayEvents(0, day)
    for i=1,numEvents do
        local title, _, _, calendarType = CalendarGetDayEvent(0, day, i)
        if ( ( calendarType == "PLAYER" or
               calendarType == "GUILD_EVENT" ) and
             title == eventName )
        then
            self.selectedEvent = eventName
            -- Open the event, and wait for messages to drive the rest of the setup.
            CalendarOpenEvent(0, day, i)
            break
        end
    end
end

function Calendar:OnOpenEvent(_, calendarType)
    local title = CalendarGetEventInfo()
    if title ~= self.selectedEvent then
        return
    end

    local numInvites = CalendarEventGetNumInvites()
    local inviteTbl = {}
    for i=1, numInvites do
        local name, level, className, classFileName, inviteStatus, modStatus, inviteIsMine, inviteType = CalendarEventGetInvite(i)
        callbacks:Fire("InviteInfo", name, inviteStatus)
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

Calendar:lock()

uOO.Calendar = Calendar
