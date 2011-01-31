local addonName, addonTable = ...

local ZRO   = addonTable.ZRO
local uOO   = addonTable.uOO
local const = addonTable.const

local DualList = uOO.object:clone()

function DualList:Initialize(getKeyFunc, sortFunc)
    self.list = {}
    self.getKeyFunc = getKeyFunc or function(item) return item end
    self.sortFunc = sortFunc
end

-- Copied from http://lua-users.org/wiki/BinaryInsert
local function bininsert(t, value, fcomp)
    --  Initialise numbers
    local iStart,iEnd,iMid,iState = 1,#t,1,0
    -- Get insert position
    while iStart <= iEnd do
        -- calculate middle
        iMid = math.floor( (iStart+iEnd)/2 )
        -- compare
        if fcomp( value,t[iMid] ) then
            iEnd,iState = iMid - 1,0
        else
            iStart,iState = iMid + 1,1
        end
    end
    table.insert( t,(iMid+iState),value )
    return (iMid+iState)
end

local function reindex(t, getKeyFunc, idx)
    idx = idx or 1
    for i=idx, #t do
        t[getKeyFunc(t[i])] = i
    end
end

function DualList:AddItem(item, dontSort)
    local added = false
    local idx
    if not self.list[self.getKeyFunc(item)] then
        if self.sortFunc and not dontSort then
            idx = bininsert(self.list, item, self.sortFunc)
        else
            table.insert(self.list, item)
        end
        reindex(self.list, self.getKeyFunc, idx)
        added = true
    end
    return added
end

function DualList:Sort()
    if self.sortFunc then
        table.sort(self.list, self.sortFunc)
    end
    reindex(self.list, self.getKeyFunc)
end

function DualList:RemoveItem(idxOrItem)
    local index
    local key
    local removed
    if type(idxOrItem) == "number" then
        index = idxOrItem
        key = self.getKeyFunc(self.list[index])
    else
        key = self.getKeyFunc(idxOrItem)
        index = self.list[key]
    end

    if self.list[key] then
        removed = true
        table.remove(self.list, index)
        self.list[key] = nil
        reindex(self.list, self.getKeyFunc, index)
    end

    return removed
end

function DualList:RemoveAllItems()
    for i, v in pairs(self.list) do
        self.list[i] = nil
    end
end

function DualList:HaveItem(idxOrItem)
    return self:GetItem(idxOrItem) and true
end

function DualList:GetIndex(item)
    local key = self.getKeyFunc(item)
    return self.list[key]
end

function DualList:GetItem(idxOrItem)
    local index
    if type(idxOrItem) == "number" then
        index = idxOrItem
    else
        local key = self.getKeyFunc(idxOrItem)
        index = self.list[key]
    end

    return self.list[index]
end

function DualList:GetItemCount()
    return self.list and #self.list or 0
end

local MarkableDualList = DualList:clone()

function MarkableDualList:Initialize(getKeyFunc, sortFunc)
    DualList.Initialize(self)
    self.marks = {}
end

function MarkableDualList:MarkItem(item)
    self.marks[self.getKeyFunc(item)] = true
end

function MarkableDualList:UnmarkItem(item)
    self.marks[self.getKeyFunc(item)] = nil
end

function MarkableDualList:IsItemMarked(item)
    return self.marks[self.getKeyFunc(item)]
end

function MarkableDualList:ClearAllMarks()
    for key in pairs(self.marks) do
        self.marks[key] = nil
    end
end

function MarkableDualList:RemoveItem(idxOrItem)
    local removed
    local item = self:GetItem(idxOrItem)
    if item then
        self:UnmarkItem(item)
    end
    return DualList.RemoveItem(self, idxOrItem)
end

function MarkableDualList:RemoveAllItems()
    DualList.RemoveAllItems(self)
    self:ClearAllMarks()
end

uOO.DualList = DualList
uOO.MarkableDualList = MarkableDualList
