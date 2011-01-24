local addonName, addonTable = ...

-- Clone an object. All non-derived objects are clones of uOO.object
function clone( base_object, clone_object )
  if type( base_object ) ~= "table" then
    return clone_object or base_object
  end
  clone_object = clone_object or {}
  clone_object.__index = base_object
  return setmetatable(clone_object, clone_object)
end

-- lock an object against cloning. Useful for modules that need to hook events,
--etc. and cloning them would break their functionality.
function lock( object )
    object.clone = function(base_object, clone_object) return nil end
end

-- Check if an object is a clone of another, or is derived from a clone of
-- another.
function isa( clone_object, base_object )
  local clone_object_type = type(clone_object)
  local base_object_type = type(base_object)
  if clone_object_type ~= "table" and base_object_type ~= table then
    return clone_object_type == base_object_type
  end
  local index = clone_object.__index
  local _isa = index == base_object
  while not _isa and index ~= nil do
    index = index.__index
    _isa = index == base_object
  end
  return _isa
end

local uOO = {}
uOO.object = clone( table, { clone = clone, isa = isa, lock = lock } )

addonTable.uOO = uOO
