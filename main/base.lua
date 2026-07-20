local CBaseValidator = {}
CBaseValidator.__index = CBaseValidator

local helpers = require "main.helpers"

function CBaseValidator:_parse(value, path, collect)
  if path == nil then path = {} elseif type(path) ~= "table" then path = { path } end

  for _, preprocess in ipairs(self.__preprocessors) do value = preprocess(value) end

  if value == nil then
    if self.__hasDefault then value = self.__default end
    if value == nil and (self.__optional or self.__nullable) then return true, nil end
    if value == nil then
      return false, { helpers.issue(path, "invalid_type", ("expected %s, got nil"):format(self.__label), self.__label, "nil") }
    end
  end

  if value == nil and self.__nullable then return true, nil end

  local ok, result = self.__check(value, path, collect)
  if not ok then return false, helpers.issues(result) end
  value = result  -- ← use the processed result (the `out` table for objects)

  for _, ref in ipairs(self.__refinements) do
    local refOk, refResult = ref(value, path)
    if not refOk then return false, helpers.issues(refResult) end
    value = refResult  -- ← pick up transforms like .upper(), .trim()
  end

  return true, value
end

function CBaseValidator:parse(value, path)
  local ok, result = self:_parse(value, path, false)
  if not ok then return false, helpers.formatIssue(result[1]) end
  return true, result
end

-- Safe parsing, returns { success: boolean, value|error }
function CBaseValidator:safeParse(value, path)
  local ok, result = self:_parse(value, path, true)

  if ok then
    return { success = true, data = result }
  else
    return {
      success = false,
      error = helpers.formatIssue(result[1]),
      issues = result,
    }
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
    if key == "__refinements" or key == "__preprocessors" then
      local values = {}
      for i = 1, #value do values[i] = value[i] end
      clone[key] = values
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

function CBaseValidator:preprocess(fn)
  if type(fn) ~= "function" then error("preprocessor must be a function", 2) end
  local clone = self:_clone()
  table.insert(clone.__preprocessors, fn)
  return clone
end

function CBaseValidator:transform(fn)
  if type(fn) ~= "function" then error("transform must be a function", 2) end
  return self:_addRefinement(function(value)
    return true, fn(value)
  end)
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
      return false, helpers.issue(path, "custom", customErr or message or "custom validation failed")
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
    __preprocessors = {},

    __optional = false,
    __nullable = false,

    __default = nil,
    __hasDefault = false,
    __label = baseType
  }, CBaseValidator)
  end
}
