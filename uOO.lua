local addonName, addonTable = ...

local uOO = {
    classes = {}
}

function uOO:NewClass(name, class)
    self.classes[name] = class

    local meta = {
        __index = class,
        __newindex = function(tbl, key, val)
            if class[key] then class[key] = val
            else rawset(tbl, key, val) end
        end}
    class.New = function (self, ...)
        local instance = setmetatable({}, meta)
        if instance then
            -- Make it an instance variable to prevent self-referencing class objects.
            instance.class = class
            instance:Construct(...)
        end
        return instance
    end

    return class
end

function uOO:GetClass(name)
    return self.classes[name]
end

function uOO:Construct(name, ...)
    local class = self:GetClass(name)
    local instance
    if class then
        instance = class:New(...)
    end
    return instance
end

addonTable.uOO = uOO
