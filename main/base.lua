local CBaseValidator = {}
CBaseValidator.__index = CBaseValidator

local helpers = require "main.helpers"

function CBaseValidator:parse(value, path)
  if path == nil then path = {} elseif type(path) ~= "table" then path = { path } end

  if value == nil then
    if self.__hasDefault then value = self.__default end
    if value == nil and (self.__optional or self.__nullable) then return true, nil end
    if value == nil then
      return false, ("[%s] expected %s, got nil"):format(helpers.pathToString(path), self.__label)
    end
  end

  if value == nil and self.__nullable then return true, nil end

  local ok, result = self.__check(value, path)
  if not ok then return false, result end
  value = result  -- ← use the processed result (the `out` table for objects)

  for _, ref in ipairs(self.__refinements) do
    local refOk, refResult = ref(value, path)
    if not refOk then return false, refResult end
    value = refResult  -- ← pick up transforms like .upper(), .trim()
  end

  return true, value
end

-- Safe parsing, returns { success: boolean, value|error }
function CBaseValidator:safeParse(value, path)
  local ok, result = self:parse(value, path)

  if ok then
    return { success = true, data = result }
  else
    return { success = false, error = result }
  end
end

function CBaseValidator:assert(value, path)
  local ok, result = self:parse(value, path)

  if not ok then
    error(result, 2)
  end
  return result
end

function CBaseValidator:_clone()
  local clone = {}

  for key, value in pairs(self) do
    if key == "__refinements" then
      local refinements = {}
      for i = 1, #value do refinements[i] = value[i] end
      clone[key] = refinements
    else
      clone[key] = value
    end
  end

  return setmetatable(clone, getmetatable(self))
end

function CBaseValidator:_addRefinement(refinement)
  local clone = self:_clone()
  table.insert(clone.__refinements, refinement)
  return clone
end

function CBaseValidator:optional()
  local clone = self:_clone()
  clone.__optional = true
  return clone
end

function CBaseValidator:nullable()
  local clone = self:_clone()
  clone.__nullable = true
  return clone
end

function CBaseValidator:default(value)
  local clone = self:_clone()
  clone.__hasDefault = true
  clone.__default = value
  return clone
end

function CBaseValidator:label(label)
  local clone = self:_clone()
  clone.__label = label
  return clone
end

function CBaseValidator:refine(fn, message)
  return self:_addRefinement(function(value, path)
    local ok, customErr = fn(value)

    if not ok then
      return false, ("[%s] %s"):format(helpers.pathToString(path), customErr or message or "custom validation failed")
    end
    return true, value
  end)
end

return {
  CBaseValidator, 
  function(baseType, checkFn)
    return setmetatable({
    __type = baseType,
    __check = checkFn,

    __refinements = {},

    __optional = false,
    __nullable = false,

    __default = nil,
    __hasDefault = false,
    __label = baseType
  }, CBaseValidator)
  end
}
